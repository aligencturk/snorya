import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class WikiService {
  final Random _random = Random();
  final Map<String, List<String>> _usedTitles = {};
  final Map<String, List<String>> _topicArticleCache = {};
  final Map<String, List<String>> _categoryArticleCache = {}; // Kategori önbelleği

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
      
      // Önbelleği kontrol et, gerekirse ön yükleme yap
      if (!_categoryArticleCache.containsKey(category) || _categoryArticleCache[category]!.isEmpty) {
        await _loadCategoryArticles(category);
      }

      // Önbellekten bir makale seç
      if (_categoryArticleCache.containsKey(category) && _categoryArticleCache[category]!.isNotEmpty) {
        // Önce kullanılmamış makaleleri filtrele
        final unusedArticles = _categoryArticleCache[category]!
            .where((title) => !_usedTitles[category]!.contains(title))
            .toList();

        String title;
        if (unusedArticles.isNotEmpty) {
          // Kullanılmamış bir makale seç
          title = unusedArticles[_random.nextInt(unusedArticles.length)];
        } else {
          // Tüm makaleler kullanılmış, rastgele bir tane seç
          title = _categoryArticleCache[category]![_random.nextInt(_categoryArticleCache[category]!.length)];
        }

        // Başlığı kullanılmış başlıklara ekle
        _usedTitles[category]!.add(title);
        
        // Liste çok büyürse, eski başlıkları temizle (son 100 başlığı tut)
        if (_usedTitles[category]!.length > 100) {
          _usedTitles[category] = _usedTitles[category]!.sublist(_usedTitles[category]!.length - 100);
        }

        return title;
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
          case AppConstants.categoryGames:
            gcmtitle = 'Kategori:Oyunlar';
            break;
          case AppConstants.categoryMoviesTv:
            gcmtitle = 'Kategori:Filmler';
            break;
        }
      }
      
      Uri url;
      String title = '';
      bool titleFound = false;
      int retryCount = 0;
      
      // Eğer belirli bir kategori seçilmişse, o kategoriden bir makale getir
      if (gcmtitle.isNotEmpty) {
        while (!titleFound && retryCount < 3) {
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
                
                // Alt kategorileri denemek için sorguları genişlet
                switch (category) {
                  case AppConstants.categoryScience:
                    // Bilim alt kategorileri
                    final scienceSubcategories = ['Kategori:Fizik', 'Kategori:Kimya', 'Kategori:Biyoloji', 'Kategori:Astronomi', 'Kategori:Matematik'];
                    if (retryCount < scienceSubcategories.length) {
                      gcmtitle = scienceSubcategories[retryCount];
                    }
                    break;
                  case AppConstants.categoryHistory:
                    // Tarih alt kategorileri
                    final historySubcategories = ['Kategori:Türk tarihi', 'Kategori:Dünya tarihi', 'Kategori:Antik tarih', 'Kategori:Savaşlar', 'Kategori:İmparatorluklar'];
                    if (retryCount < historySubcategories.length) {
                      gcmtitle = historySubcategories[retryCount];
                    }
                    break;
                  case AppConstants.categoryTechnology:
                    // Teknoloji alt kategorileri
                    final techSubcategories = ['Kategori:Bilgisayarlar', 'Kategori:İnternet', 'Kategori:Yazılım', 'Kategori:Mobil iletişim', 'Kategori:Yapay zeka'];
                    if (retryCount < techSubcategories.length) {
                      gcmtitle = techSubcategories[retryCount];
                    }
                    break;
                  case AppConstants.categoryCulture:
                    // Kültür alt kategorileri
                    final cultureSubcategories = ['Kategori:Sanat', 'Kategori:Edebiyat', 'Kategori:Müzik', 'Kategori:Sinema', 'Kategori:Tiyatro'];
                    if (retryCount < cultureSubcategories.length) {
                      gcmtitle = cultureSubcategories[retryCount];
                    }
                    break;
                  case AppConstants.categoryGames:
                    // Oyun alt kategorileri
                    final gamesSubcategories = ['Kategori:Video oyunları', 'Kategori:Bilgisayar oyunları', 'Kategori:Mobil oyunlar', 'Kategori:Oyun konsolları', 'Kategori:Rol yapma oyunları'];
                    if (retryCount < gamesSubcategories.length) {
                      gcmtitle = gamesSubcategories[retryCount];
                    }
                    break;
                  case AppConstants.categoryMoviesTv:
                    // Dizi/Film alt kategorileri
                    final moviesTvSubcategories = ['Kategori:Filmler', 'Kategori:Televizyon dizileri', 'Kategori:Sinema', 'Kategori:TV şovları', 'Kategori:Film yönetmenleri'];
                    if (retryCount < moviesTvSubcategories.length) {
                      gcmtitle = moviesTvSubcategories[retryCount];
                    }
                    break;
                }
              }
            } else {
              // Kategori boşsa, alt kategorileri dene
              retryCount++;
            }
          } else {
            // API hatası, tekrar dene
            retryCount++;
          }
        }
      }
      
      // Eğer hala başlık bulunamadıysa veya kategori "Karışık" ise rastgele makale getir
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
  
  /// WikiSpecies'den tür bilgilerini getirir
  Future<Map<String, dynamic>> getWikiSpeciesInfo(String species) async {
    try {
      final Uri url = Uri.parse(
        '${AppConstants.wikiSpeciesApiBaseUrl}?action=query&format=json&prop=extracts|pageimages&titles=${Uri.encodeComponent(species)}&pithumbsize=800&pilimit=1&exintro=1'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final pageId = pages.keys.first;
        
        if (pageId == '-1') {
          return {'error': 'Tür bulunamadı'};
        }
        
        final page = pages[pageId];
        final Map<String, dynamic> result = {
          'title': page['title'],
          'content': page.containsKey('extract') ? page['extract'] : 'İçerik bulunamadı',
          'imageUrl': '',
        };
        
        if (page.containsKey('thumbnail')) {
          result['imageUrl'] = page['thumbnail']['source'];
        }
        
        return result;
      } else {
        return {'error': 'API hatası: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Tür bilgileri getirilirken hata oluştu: $e'};
    }
  }
  
  /// Wikimedia Commons'tan belirli bir konuyla ilgili görselleri getirir
  Future<List<Map<String, dynamic>>> getCommonsImages(String topic) async {
    try {
      final Uri url = Uri.parse(
        '${AppConstants.commonsApiBaseUrl}?action=query&format=json&generator=search&gsrnamespace=6&gsrsearch=${Uri.encodeComponent(topic)}&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=800&gsrlimit=10'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (!data.containsKey('query') || !data['query'].containsKey('pages')) {
          return [];
        }
        
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final List<Map<String, dynamic>> images = [];
        
        for (final page in pages.values) {
          if (page.containsKey('imageinfo') && page['imageinfo'].isNotEmpty) {
            final imageInfo = page['imageinfo'][0];
            final metadata = imageInfo.containsKey('extmetadata') ? imageInfo['extmetadata'] : {};
            
            final Map<String, dynamic> image = {
              'title': page['title'],
              'url': imageInfo['url'],
              'description': metadata.containsKey('ImageDescription') ? metadata['ImageDescription']['value'] : '',
              'author': metadata.containsKey('Artist') ? metadata['Artist']['value'] : '',
              'license': metadata.containsKey('License') ? metadata['License']['value'] : '',
            };
            
            images.add(image);
          }
        }
        
        return images;
      } else {
        return [];
      }
    } catch (e) {
      print('Commons görselleri getirilirken hata: $e');
      return [];
    }
  }
  
  /// Gisburn Forest hakkında bilgileri getirir
  Future<Map<String, dynamic>> getGisburnForestInfo() async {
    try {
      const String forestTitle = 'Gisburn Forest';
      final Uri url = Uri.parse(
        '${AppConstants.wikipediaEnApiBaseUrl}?action=query&format=json&prop=extracts|pageimages&titles=${Uri.encodeComponent(forestTitle)}&pithumbsize=800&pilimit=1&exintro=0&explaintext=1'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final pageId = pages.keys.first;
        
        if (pageId == '-1') {
          // İngilizce bulunamadıysa Türkçe'yi dene
          return await _searchWikipedia('Gisburn Ormanı');
        }
        
        final page = pages[pageId];
        final Map<String, dynamic> result = {
          'title': page['title'],
          'content': page.containsKey('extract') ? page['extract'] : 'İçerik bulunamadı',
          'imageUrl': '',
        };
        
        if (page.containsKey('thumbnail')) {
          result['imageUrl'] = page['thumbnail']['source'];
        }
        
        // Commons'tan görsel bilgileri ekle
        final List<Map<String, dynamic>> commonsImages = await getCommonsImages('Gisburn Forest');
        if (commonsImages.isNotEmpty) {
          result['commonsImages'] = commonsImages;
        }
        
        return result;
      } else {
        return {'error': 'API hatası: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Orman bilgileri getirilirken hata oluştu: $e'};
    }
  }
  
  /// Wikipedia'da arama yapar ve ilk sonucu döndürür
  Future<Map<String, dynamic>> _searchWikipedia(String query) async {
    try {
      final Uri searchUrl = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=search&srsearch=${Uri.encodeComponent(query)}&srlimit=1'
      );
      
      final searchResponse = await http.get(searchUrl);
      
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final searchResults = searchData['query']['search'] as List;
        
        if (searchResults.isEmpty) {
          return {'error': 'Sonuç bulunamadı'};
        }
        
        final String title = searchResults[0]['title'];
        
        // Makale içeriğini al
        final Uri contentUrl = Uri.parse(
          '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&prop=extracts|pageimages&titles=${Uri.encodeComponent(title)}&pithumbsize=800&pilimit=1&exintro=0&explaintext=1'
        );
        
        final contentResponse = await http.get(contentUrl);
        
        if (contentResponse.statusCode == 200) {
          final contentData = json.decode(contentResponse.body);
          final pages = contentData['query']['pages'] as Map<String, dynamic>;
          final pageId = pages.keys.first;
          final page = pages[pageId];
          
          final Map<String, dynamic> result = {
            'title': page['title'],
            'content': page.containsKey('extract') ? page['extract'] : 'İçerik bulunamadı',
            'imageUrl': '',
          };
          
          if (page.containsKey('thumbnail')) {
            result['imageUrl'] = page['thumbnail']['source'];
          }
          
          return result;
        }
      }
      
      return {'error': 'Arama sonuçları getirilirken hata oluştu'};
    } catch (e) {
      return {'error': 'Arama yapılırken hata oluştu: $e'};
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

  /// Kategori için makaleleri önceden yükler
  Future<void> _loadCategoryArticles(String category) async {
    if (category == AppConstants.categoryMixed) {
      // Karışık kategorisi için rastgele makaleleri yükle
      return; // Karışık kategori için önbellek kullanmıyoruz
    }

    try {
      if (!_categoryArticleCache.containsKey(category)) {
        _categoryArticleCache[category] = [];
      }

      // Kategori için uygun başlıkları belirle
      List<String> categoryTitles = [];
      switch (category) {
        case AppConstants.categoryScience:
          categoryTitles = ['Kategori:Bilim', 'Kategori:Fizik', 'Kategori:Kimya', 'Kategori:Biyoloji', 'Kategori:Astronomi', 'Kategori:Matematik'];
          break;
        case AppConstants.categoryHistory:
          categoryTitles = ['Kategori:Tarih', 'Kategori:Türk tarihi', 'Kategori:Dünya tarihi', 'Kategori:Antik tarih', 'Kategori:Savaşlar', 'Kategori:İmparatorluklar'];
          break;
        case AppConstants.categoryTechnology:
          categoryTitles = ['Kategori:Teknoloji', 'Kategori:Bilgisayarlar', 'Kategori:İnternet', 'Kategori:Yazılım', 'Kategori:Mobil iletişim', 'Kategori:Yapay zeka'];
          break;
        case AppConstants.categoryCulture:
          categoryTitles = ['Kategori:Kültür', 'Kategori:Sanat', 'Kategori:Edebiyat', 'Kategori:Müzik', 'Kategori:Sinema', 'Kategori:Tiyatro'];
          break;
        case AppConstants.categoryGames:
          categoryTitles = ['Kategori:Oyunlar', 'Kategori:Video oyunları', 'Kategori:Bilgisayar oyunları', 'Kategori:Mobil oyunlar', 'Kategori:Oyun konsolları', 'Kategori:Rol yapma oyunları'];
          break;
        case AppConstants.categoryMoviesTv:
          categoryTitles = ['Kategori:Filmler', 'Kategori:Televizyon dizileri', 'Kategori:Sinema', 'Kategori:TV şovları', 'Kategori:Film yönetmenleri'];
          break;
        default:
          return; // Bilinmeyen kategori
      }

      // Her kategori başlığı için makaleleri getir
      for (final title in categoryTitles) {
        if (_categoryArticleCache[category]!.length >= 50) {
          break; // 50 makale yeterli
        }

        final Uri url = Uri.parse('${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=categorymembers&cmtitle=$title&cmlimit=50&cmtype=page');
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['query'].containsKey('categorymembers')) {
            final members = data['query']['categorymembers'] as List;
            
            for (final member in members) {
              final articleTitle = member['title'] as String;
              if (!_categoryArticleCache[category]!.contains(articleTitle)) {
                _categoryArticleCache[category]!.add(articleTitle);
              }
              
              if (_categoryArticleCache[category]!.length >= 50) {
                break; // 50 makale yeterli
              }
            }
          }
        }
      }
    } catch (e) {
      print('Kategori makaleleri yüklenirken hata: $e');
      // Hata durumunda sessizce devam et, ana akış etkilenmesin
    }
  }

  /// Kategori önbelleğini temizler
  void clearCategoryCache(String category) {
    if (_categoryArticleCache.containsKey(category)) {
      _categoryArticleCache[category] = [];
    }
  }

  /// Tüm kategori önbelleğini temizler
  void clearAllCategoryCache() {
    _categoryArticleCache.clear();
  }

  // Belirli bir başlığa sahip makaleye benzer içerik getirir
  Future<String> getSimilarArticleTitle(String currentTitle) async {
    try {
      // Önce başlığı kategorilere ayırıp anahtar kelimeler oluştur
      final keywords = await _extractKeywordsFromTitle(currentTitle);
      
      if (keywords.isEmpty) {
        // Anahtar kelime çıkarılamadıysa, rastgele bir makale getir
        return await getRandomArticleTitle(AppConstants.categoryMixed);
      }
      
      // Rastgele bir anahtar kelime seç
      final randomKeyword = keywords[_random.nextInt(keywords.length)];
      
      // Seçilen anahtar kelime ile arama yap
      final Uri searchUrl = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=search&srsearch=${Uri.encodeComponent(randomKeyword)}&srlimit=20'
      );
      
      final searchResponse = await http.get(searchUrl);
      
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final searchResults = searchData['query']['search'] as List;
        
        if (searchResults.isNotEmpty) {
          // Benzer makaleleri filtrele (mevcut makaleyi hariç tut)
          final similarArticles = searchResults
              .map<String>((result) => result['title'] as String)
              .where((title) => title != currentTitle)
              .toList();
          
          if (similarArticles.isNotEmpty) {
            // Rastgele bir benzer makale seç
            return similarArticles[_random.nextInt(similarArticles.length)];
          }
        }
      }
      
      // Hiçbir şey bulunamazsa, kategoriye göre rastgele bir makale getir
      return await getRandomArticleTitle(AppConstants.categoryMixed);
    } catch (e) {
      throw Exception('Benzer makale getirilirken hata oluştu: $e');
    }
  }
  
  // Makale başlığından anahtar kelimeler çıkar
  Future<List<String>> _extractKeywordsFromTitle(String title) async {
    try {
      // Başlığı kelimelere ayır ve kısa kelimeleri filtrele
      final words = title.split(' ')
          .where((word) => word.length > 3) // 3 karakterden uzun kelimeleri al
          .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), '')) // Özel karakterleri temizle
          .where((word) => word.isNotEmpty) 
          .toList();
      
      // Eğer yeterli kelime yoksa makale içeriğini de kullan
      if (words.length < 2) {
        final content = await getArticleContent(title);
        final contentWords = content.split(' ')
            .where((word) => word.length > 4) // İçerikten daha uzun kelimeleri al
            .take(50) // İlk 50 kelimeyi al
            .map((word) => word.replaceAll(RegExp(r'[^\w\s]'), ''))
            .where((word) => word.isNotEmpty)
            .toList();
        
        // Kelimelerden rastgele 5 tanesini seç
        final selectedWords = <String>[];
        for (int i = 0; i < 5 && contentWords.isNotEmpty; i++) {
          final randomIndex = _random.nextInt(contentWords.length);
          selectedWords.add(contentWords[randomIndex]);
          contentWords.removeAt(randomIndex);
        }
        
        return [...words, ...selectedWords];
      }
      
      return words;
    } catch (e) {
      print('Anahtar kelimeler çıkarılırken hata: $e');
      // Hata durumunda başlığı ayırıp döndür
      return title.split(' ');
    }
  }

  /// Belirli bir başlığa ait makale bilgilerini getirir
  /// Game sınıfı için ek olarak eklenen metot
  Future<Map<String, dynamic>?> fetchArticleByTitle(String title) async {
    try {
      // İçerik al
      final content = await getArticleContent(title);
      // Görsel al
      final imageUrl = await getArticleImage(title);
      
      // Wikipedia URL'ini oluştur
      final encodedTitle = Uri.encodeComponent(title.replaceAll(' ', '_'));
      final url = 'https://tr.wikipedia.org/wiki/$encodedTitle';
      
      return {
        'content': content,
        'imageUrl': imageUrl,
        'url': url,
      };
    } catch (e) {
      return null;
    }
  }
  
  /// Belirli bir konu için Commons görsellerini getir
  /// Game sınıfı için ek olarak eklenen metot
  Future<List<Map<String, dynamic>>> fetchCommonsImages(String topic, {int limit = 5}) async {
    try {
      final Uri url = Uri.parse(
        '${AppConstants.commonsApiBaseUrl}?action=query&format=json&list=search&srsearch=${Uri.encodeComponent(topic)}&srnamespace=6&srlimit=$limit'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final searchResults = data['query']['search'] as List;
        
        if (searchResults.isEmpty) {
          return [];
        }
        
        final List<Map<String, dynamic>> images = [];
        
        for (final result in searchResults) {
          final title = result['title'] as String;
          
          // Sadece görsel dosyalarını al
          if (title.startsWith('File:') || title.startsWith('Image:')) {
            final imageDetails = await _getCommonsImageDetails(title);
            
            if (imageDetails.containsKey('url') && imageDetails['url'].isNotEmpty) {
              images.add(imageDetails);
              
              // Yeterli görsel toplandıysa döngüden çık
              if (images.length >= limit) {
                break;
              }
            }
          }
        }
        
        return images;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Commons görsel detaylarını al
  Future<Map<String, dynamic>> _getCommonsImageDetails(String title) async {
    try {
      final Uri url = Uri.parse(
        '${AppConstants.commonsApiBaseUrl}?action=query&format=json&prop=imageinfo&titles=${Uri.encodeComponent(title)}&iiprop=url|extmetadata&iimetadataversion=latest'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final pageId = pages.keys.first;
        
        if (pageId != '-1' && pages[pageId].containsKey('imageinfo')) {
          final imageInfo = pages[pageId]['imageinfo'][0];
          final metadata = imageInfo['extmetadata'] ?? {};
          
          // Resim açıklaması
          String description = '';
          if (metadata.containsKey('ImageDescription') && metadata['ImageDescription'].containsKey('value')) {
            description = metadata['ImageDescription']['value'];
          }
          
          // Yazar bilgisi
          String author = '';
          if (metadata.containsKey('Artist') && metadata['Artist'].containsKey('value')) {
            author = metadata['Artist']['value'];
          }
          
          return {
            'title': title,
            'url': imageInfo['url'] ?? '',
            'description': description,
            'author': author,
          };
        }
      }
      
      return {'title': title, 'url': '', 'description': '', 'author': ''};
    } catch (e) {
      return {'title': title, 'url': '', 'description': '', 'author': ''};
    }
  }

  /// Başlığa göre resim URL'si arar
  Future<String> searchImage(String title, {bool isEnglish = false}) async {
    try {
      // Önce başlığın sonundaki parantezleri (varsa) temizle
      final cleanTitle = title.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
      
      // 1. Standart Wikipedia API'sini kullanarak resim ara
      String imageUrl = await _searchImageInWikipedia(cleanTitle, isEnglish: isEnglish);
      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
      
      // 2. Başlığı genişleterek alternatif arama
      final titleWords = cleanTitle.split(' ');
      if (titleWords.length > 1) {
        // İlk iki kelimeyi veya en fazla üç kelimeyi al
        final simplifiedTitle = titleWords.length > 3 
            ? titleWords.sublist(0, 3).join(' ') 
            : titleWords.join(' ');
        
        imageUrl = await _searchImageInWikipedia(simplifiedTitle, isEnglish: isEnglish);
        if (imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
      
      // 3. Film başlığına "film" veya "dizi" ekleyerek ara
      String mediaType = '';
      if (title.toLowerCase().contains('dizi') || 
          title.toLowerCase().contains('series') ||
          title.toLowerCase().contains('tv')) {
        mediaType = isEnglish ? 'TV series' : 'dizi';
      } else {
        mediaType = isEnglish ? 'film' : 'film';
      }
      
      imageUrl = await _searchImageInWikipedia('$cleanTitle $mediaType', isEnglish: isEnglish);
      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
      
      // 4. Commons'da ara (daha geniş medya veritabanı)
      imageUrl = await _searchImageInCommons(cleanTitle);
      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
      
      // 5. Commons'da "film posteri" veya "dizi posteri" ekleyerek ara
      final posterType = isEnglish ? 'poster' : 'afiş';
      imageUrl = await _searchImageInCommons('$cleanTitle $posterType');
      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
      
      // 6. Daha agresif arama stratejisi: ilk kelimeyle posterler arasında ara
      if (titleWords.isNotEmpty) {
        final firstWord = titleWords[0];
        imageUrl = await _searchImageInCommons('$firstWord $posterType film');
        if (imageUrl.isNotEmpty) {
          return imageUrl;
        }
      }
      
      // 7. İngilizce arama henüz denenmemişse, İngilizce olarak da dene
      if (!isEnglish) {
        return await searchImage(title, isEnglish: true);
      }
      
      return '';
    } catch (e) {
      print('Resim arama hatası: $e');
      return '';
    }
  }
  
  /// Wikipedia API'sini kullanarak resim ara
  Future<String> _searchImageInWikipedia(String title, {bool isEnglish = false}) async {
    try {
      final apiUrl = isEnglish 
          ? AppConstants.wikipediaEnApiBaseUrl 
          : AppConstants.wikipediaApiBaseUrl;
      
      final url = Uri.parse(
        '$apiUrl?action=query&titles=${Uri.encodeComponent(title)}'
        '&prop=pageimages&format=json&pithumbsize=500'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('query') && 
            data['query'].containsKey('pages')) {
          
          final pages = data['query']['pages'];
          
          // İlk sayfayı al (genellikle tek sayfa döner)
          final pageId = pages.keys.first;
          final page = pages[pageId];
          
          // Sayfada resim var mı kontrol et
          if (page.containsKey('thumbnail') && 
              page['thumbnail'].containsKey('source')) {
            return page['thumbnail']['source'];
          }
          
          // Resim yoksa, diğer resimleri kontrol et
          if (page.containsKey('original') && 
              page['original'].containsKey('source')) {
            return page['original']['source'];
          }
        }
      }
      
      return '';
    } catch (e) {
      print('Wikipedia resim arama hatası: $e');
      return '';
    }
  }
  
  /// Wikimedia Commons'dan resim ara
  Future<String> _searchImageInCommons(String title) async {
    try {
      // gsrsearch parametresi için film/dizi anahtar kelimeleri ekle
      final searchTerms = '${Uri.encodeComponent(title)} poster|film|movie|series|dizi|afiş';
      
      final url = Uri.parse(
        '${AppConstants.commonsApiBaseUrl}?action=query'
        '&generator=search&gsrsearch=$searchTerms'
        '&gsrnamespace=6' // Sadece File namespace'de ara (dosya/görsel)
        '&gsrlimit=10' // Daha fazla sonuç al
        '&prop=imageinfo&iiprop=url|mediatype|size&format=json'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('query') && 
            data['query'].containsKey('pages')) {
          
          final pages = data['query']['pages'];
          final List<Map<String, dynamic>> images = [];
          
          // Tüm görselleri topla ve sırala
          for (var pageId in pages.keys) {
            final page = pages[pageId];
            
            if (page.containsKey('imageinfo') && 
                page['imageinfo'] is List && 
                page['imageinfo'].isNotEmpty) {
              
              final imageInfo = page['imageinfo'][0];
              if (imageInfo.containsKey('url')) {
                // Görsel tipini kontrol et (jpg, png tercih edelim)
                final url = imageInfo['url'] as String;
                final isImage = url.toLowerCase().endsWith('.jpg') || 
                               url.toLowerCase().endsWith('.jpeg') || 
                               url.toLowerCase().endsWith('.png');
                               
                if (isImage) {
                  // Resmin boyutunu da al (eğer varsa)
                  int width = 0;
                  if (imageInfo.containsKey('width')) {
                    width = imageInfo['width'] as int;
                  }
                  
                  images.add({
                    'url': url,
                    'width': width,
                    'title': page['title'] ?? '',
                  });
                }
              }
            }
          }
          
          // Görselleri boyutlarına göre sırala, en büyük görseli tercih et
          if (images.isNotEmpty) {
            images.sort((a, b) => (b['width'] as int).compareTo(a['width'] as int));
            return images.first['url'] as String;
          }
        }
      }
      
      return '';
    } catch (e) {
      print('Commons\'da resim arama hatası: $e');
      return '';
    }
  }
} 