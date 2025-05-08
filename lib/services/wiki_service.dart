import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class WikiService {
  /// Belirli bir kategori için rastgele bir Wikipedia makalesi başlığı getirir
  Future<String> getRandomArticleTitle(String category) async {
    try {
      // Kategori bazlı sorgu parametresi oluşturma
      String gcmtitle = '';
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
      
      // Eğer belirli bir kategori seçilmişse, o kategoriden bir makale getir
      if (gcmtitle.isNotEmpty) {
        url = Uri.parse('${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=categorymembers&cmtitle=$gcmtitle&cmlimit=20&cmtype=page');
        
        final response = await http.get(url);
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final members = data['query']['categorymembers'] as List;
          
          if (members.isNotEmpty) {
            // Rastgele bir makale seç
            final randomIndex = DateTime.now().millisecondsSinceEpoch % members.length;
            return members[randomIndex]['title'];
          }
        }
      }
      
      // Kategori belirtilmemiş veya kategori sorgusu başarısız olmuşsa rastgele makale getir
      url = Uri.parse('${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&list=random&rnlimit=1&rnnamespace=0');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['query']['random'][0]['title'];
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Rastgele makale getirilirken hata oluştu: $e');
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
      final Uri url = Uri.parse(
        '${AppConstants.wikipediaApiBaseUrl}?action=query&format=json&prop=pageimages&titles=${Uri.encodeComponent(title)}&piprop=original'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'] as Map<String, dynamic>;
        final pageId = pages.keys.first;
        
        if (pageId != '-1' && pages[pageId].containsKey('original')) {
          return pages[pageId]['original']['source'];
        } else {
          return AppConstants.fallbackImageUrl;
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      return AppConstants.fallbackImageUrl;
    }
  }
} 