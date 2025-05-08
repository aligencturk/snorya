import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class WikiService {
  final Random _random = Random();
  final Map<String, List<String>> _usedTitles = {};
  final Map<String, List<String>> _topicArticleCache = {};

  /// Belirli bir kategori için rastgele bir Wikipedia makalesi başlığı getirir
  Future<String> getRandomArticleTitle(String category, {String customTopic = ''}) async {
    try {
      // Özel konu varsa, o konuya özel makale başlığı getir
      if (category == AppConstants.categoryCustom && customTopic.isNotEmpty) {
        return await _getCustomTopicArticleTitle(customTopic);
      }
      
      // Her kategori için kullanılmış başlıkları izle
      if (!_usedTitles.containsKey(category)) {
        _usedTitles[category] = [];
      }
      
      // Kategori bazlı sorgu parametresi oluşturma
      String gcmtitle = '';
      int cmlimit = 50; // Daha fazla sonuç almak için limit artırıldı
      
      if (category != AppConstants.categoryMixed) {
        switch (category) {
          case AppConstants.categoryScience:
            gcmtitle = 'Kategori:Bilim';
            break;
          case AppConstants.categoryHistory:
            gcmtitle = 'Kategori:Tarih';
            break;
          case AppConstants.categoryTechnology:
            gcmtitle = 'Kategori:Teknoloji';
            break;
          case AppConstants.categoryCulture:
            gcmtitle = 'Kategori:Kültür';
            break;
        }
      }
      
      Uri url;
      String title = '';
      bool titleFound = false;
      int retryCount = 0;
      
      // Eğer belirli bir kategori seçilmişse, o kategoriden bir makale getir
      while (!titleFound && retryCount < 3) {
        if (gcmtitle.isNotEmpty) {
          url = Uri.parse('${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=categorymembers&cmtitle=$gcmtitle&cmlimit=$cmlimit&cmtype=page');
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final members = data['query']['categorymembers'] as List;
            
            if (members.isNotEmpty) {
              // Kullanılmamış başlıkları filtrele
              final unusedMembers = members.where((member) => 
                !_usedTitles[category]!.contains(member['title'])).toList();
              
              if (unusedMembers.isNotEmpty) {
                // Rastgele bir makale seç
                final randomIndex = _random.nextInt(unusedMembers.length);
                title = unusedMembers[randomIndex]['title'];
                titleFound = true;
              } else if (members.length > _usedTitles[category]!.length) {
                // Tüm başlıklar kullanılmış, rastgele bir tane seç
                final randomIndex = _random.nextInt(members.length);
                title = members[randomIndex]['title'];
                titleFound = true;
              } else {
                // Alt kategorileri veya daha geniş kategorileri dene
                retryCount++;
                cmlimit += 50; // Daha fazla sonuç almak için limiti artır
              }
            }
          }
        }
        
        // Kategori belirtilmemiş veya kategori sorgusu başarısız olmuşsa rastgele makale getir
        if (!titleFound) {
          url = Uri.parse('${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=random&rnlimit=1&rnnamespace=0');
          
          final response = await http.get(url);
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            title = data['query']['random'][0]['title'];
            titleFound = true;
          } else {
            throw Exception('API error: ${response.statusCode}');
          }
        }
      }
      
      // Başlığı kullanılmış başlıklara ekle
      if (title.isNotEmpty) {
        _usedTitles[category]!.add(title);
        
        // Liste çok büyürse, eski başlıkları temizle (son 100 başlığı tut)
        if (_usedTitles[category]!.length > 100) {
          _usedTitles[category] = _usedTitles[category]!.sublist(_usedTitles[category]!.length - 100);
        }
      }
      
      return title;
    } catch (e) {
      throw Exception('Rastgele makale getirilirken hata oluştu: $e');
    }
  }
  
  /// Özel bir konu için makale başlığı getir
  Future<String> _getCustomTopicArticleTitle(String topic) async {
    try {
      final String cacheKey = topic.toLowerCase();
      
      // Önbellekte bu konuya ait makaleler var mı kontrol et
      if (!_topicArticleCache.containsKey(cacheKey)) {
        _topicArticleCache[cacheKey] = [];
      }
      
      // Eğer önbellekte yeterli makale yoksa, yeni makaleler ara
      if (_topicArticleCache[cacheKey]!.length < 5) {
        await _searchArticlesForTopic(topic);
      }
      
      // Önbellekten makale seç
      if (_topicArticleCache[cacheKey]!.isNotEmpty) {
        final unusedTitles = _topicArticleCache[cacheKey]!
            .where((title) => !_usedTitles.containsKey(cacheKey) || !_usedTitles[cacheKey]!.contains(title))
            .toList();
        
        if (unusedTitles.isNotEmpty) {
          final title = unusedTitles[_random.nextInt(unusedTitles.length)];
          
          // Kullanılmış başlıkları izle
          if (!_usedTitles.containsKey(cacheKey)) {
            _usedTitles[cacheKey] = [];
          }
          _usedTitles[cacheKey]!.add(title);
          
          return title;
        } else if (_topicArticleCache[cacheKey]!.isNotEmpty) {
          // Tüm başlıklar kullanılmış, rastgele bir tane seç
          return _topicArticleCache[cacheKey]![_random.nextInt(_topicArticleCache[cacheKey]!.length)];
        }
      }
      
      // Eğer hala makale bulunamadıysa, direkt konu adını dene
      return topic;
    } catch (e) {
      // Hata durumunda konunun kendisini döndür
      return topic;
    }
  }
  
  /// Belirli bir konu için Wikipedia'da arama yap ve ilgili makaleleri önbelleğe al
  Future<void> _searchArticlesForTopic(String topic) async {
    try {
      final String cacheKey = topic.toLowerCase();
      
      // Wikipedia'da arama yap
      final Uri searchUrl = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=search&srsearch=${Uri.encodeComponent(topic)}&srlimit=20'
      );
      
      final searchResponse = await http.get(searchUrl);
      
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final searchResults = searchData['query']['search'] as List;
        
        if (searchResults.isNotEmpty) {
          // Arama sonuçlarını önbelleğe al
          final titles = searchResults.map<String>((result) => result['title'] as String).toList();
          _topicArticleCache[cacheKey] = titles;
          
          // Kategori araması da yap
          await _searchCategoryForTopic(topic);
        }
      } else {
        // Kategori aramasını dene
        await _searchCategoryForTopic(topic);
      }
    } catch (e) {
      print('Konu araması sırasında hata: $e');
    }
  }
  
  /// Belirli bir konuyla ilgili Wikipedia kategorilerini ara
  Future<void> _searchCategoryForTopic(String topic) async {
    try {
      final String cacheKey = topic.toLowerCase();
      
      // Kategori araması
      final Uri categoryUrl = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=categorymembers&cmtitle=Kategori:${Uri.encodeComponent(topic)}&cmlimit=30&cmtype=page'
      );
      
      final categoryResponse = await http.get(categoryUrl);
      
      if (categoryResponse.statusCode == 200) {
        final categoryData = json.decode(categoryResponse.body);
        
        if (categoryData['query'].containsKey('categorymembers')) {
          final categoryMembers = categoryData['query']['categorymembers'] as List;
          
          if (categoryMembers.isNotEmpty) {
            // Kategori üyelerini önbelleğe ekle
            final titles = categoryMembers.map<String>((member) => member['title'] as String).toList();
            
            // Zaten var olan başlıkları ekle
            if (_topicArticleCache.containsKey(cacheKey)) {
              for (final title in titles) {
                if (!_topicArticleCache[cacheKey]!.contains(title)) {
                  _topicArticleCache[cacheKey]!.add(title);
                }
              }
            } else {
              _topicArticleCache[cacheKey] = titles;
            }
          }
        }
      }
      
      // Ana konu sayfasını da ekle
      final bool hasMainArticle = await _checkArticleExists(topic);
      if (hasMainArticle && !_topicArticleCache[cacheKey]!.contains(topic)) {
        _topicArticleCache[cacheKey]!.add(topic);
      }
    } catch (e) {
      print('Kategori araması sırasında hata: $e');
    }
  }
  
  /// Bir başlığın Wikipedia'da var olup olmadığını kontrol et
  Future<bool> _checkArticleExists(String title) async {
    try {
      final Uri url = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&titles=${Uri.encodeComponent(title)}'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        
        // "-1" kimliği olmayan bir sayfa varsa, makale var demektir
        return !pages.containsKey('-1');
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Belirli bir başlığa sahip makalenin içeriğini getirir
  Future<String> getArticleContent(String title) async {
    try {
      final Uri url = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&prop=extracts&titles=${Uri.encodeComponent(title)}&explaintext=1&exsectionformat=plain'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final pageId = pages.keys.first;
        
        if (pageId != '-1') {
          return pages[pageId]['extract'];
        } else {
          throw Exception('Makale bulunamadı');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Makale içeriği getirilirken hata oluştu: $e');
    }
  }

  /// Belirli bir başlığa sahip makalenin resmini getirir
  Future<String> getArticleImage(String title) async {
    try {
      // Önce sayfa kimliğini al
      final Uri pageIdUrl = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&titles=${Uri.encodeComponent(title)}'
      );
      
      final pageIdResponse = await http.get(pageIdUrl);
      
      if (pageIdResponse.statusCode != 200) {
        return '';
      }
      
      final pageIdData = json.decode(pageIdResponse.body);
      final pages = pageIdData['query']['pages'] as Map<String, dynamic>;
      final pageId = pages.keys.first;
      
      if (pageId == '-1') {
        return '';
      }
      
      // İkinci adım: Önce daha yüksek kaliteli görsel alın
      final Uri imageInfoUrl = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&prop=pageimages&titles=${Uri.encodeComponent(title)}&pithumbsize=800&pilimit=1'
      );
      
      final response = await http.get(imageInfoUrl);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        
        if (pages[pageId].containsKey('thumbnail')) {
          return pages[pageId]['thumbnail']['source'];
        }
      }
      
      // Yüksek çözünürlüklü görsel alınamadıysa alternatif görsel arama yöntemi
      final Uri alternativeUrl = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&generator=images&titles=${Uri.encodeComponent(title)}&prop=imageinfo&iiprop=url&gimlimit=5'
      );
      
      final alternativeResponse = await http.get(alternativeUrl);
      
      if (alternativeResponse.statusCode == 200) {
        final data = json.decode(alternativeResponse.body);
        
        // Görsel bulunamadıysa
        if (!data.containsKey('query') || !data['query'].containsKey('pages')) {
          return '';
        }
        
        final images = data['query']['pages'] as Map<String, dynamic>;
        // Görselleri filtrele - SVG, PNG, JPG formatında olanları al
        final validImages = images.values.where((image) {
          final url = image['imageinfo'][0]['url'].toString().toLowerCase();
          return url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png');
        }).toList();
        
        if (validImages.isNotEmpty) {
          // Rastgele bir görsel seç
          final randomIndex = _random.nextInt(validImages.length);
          return validImages[randomIndex]['imageinfo'][0]['url'];
        }
      }
      
      // Hiçbir görsel bulunamadıysa boş döndür
      return '';
    } catch (e) {
      return '';
    }
  }
  
  /// Kategorideki kullanılmış başlıkları temizle
  void clearUsedTitles(String category) {
    if (_usedTitles.containsKey(category)) {
      _usedTitles[category] = [];
    }
  }
  
  /// Tüm kullanılmış başlıkları temizle
  void clearAllUsedTitles() {
    _usedTitles.clear();
  }
  
  /// Konu önbelleğini temizle
  void clearTopicCache(String topic) {
    final String cacheKey = topic.toLowerCase();
    if (_topicArticleCache.containsKey(cacheKey)) {
      _topicArticleCache[cacheKey] = [];
    }
    if (_usedTitles.containsKey(cacheKey)) {
      _usedTitles[cacheKey] = [];
    }
  }
  
  /// Tüm konu önbelleğini temizle
  void clearAllTopicCache() {
    _topicArticleCache.clear();
  }
} 