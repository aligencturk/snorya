import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class PythonSummaryService {
  // Python servisinin URL'i - constants'tan alınır
  static String get baseUrl => AppConstants.pythonSummaryServiceUrl;
  
  /// Wikipedia makale içeriğini Python servisi ile özetler
  Future<String> generateSummary(String articleContent) async {
    try {
      // Çok uzun bir içerikse kısalt
      final String trimmedContent = articleContent.length > 15000 
          ? articleContent.substring(0, 15000) 
          : articleContent;
      
      // Python servisine istek gönder
      final uri = Uri.parse('$baseUrl/summarize');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': trimmedContent,
          'sentences': 4,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['summary'] != null) {
          return data['summary'] as String;
        } else {
          // Hata durumunda fallback özet
          return data['summary'] ?? AppConstants.fallbackSummary;
        }
      } else {
        // HTTP hata durumu
        print('Python servisi HTTP hatası: ${response.statusCode}');
        return AppConstants.fallbackSummary;
      }
    } catch (e) {
      print('Python özet servisi hatası: $e');
      return AppConstants.fallbackSummary;
    }
  }
  
  /// Wikipedia'da arama yapar ve bulunan makaleyi özetler
  Future<Map<String, dynamic>> searchAndSummarize(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/search-and-summarize');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'sentences': 4,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'title': data['title'] ?? query,
            'summary': data['summary'] ?? 'Özet oluşturulamadı.',
            'url': data['url'] ?? '',
            'content': '', // Content buradan gelmiyor, Wikipedia API'den ayrı alınmalı
          };
        }
      }
      
      // Hata durumunda boş sonuç döndür
      return {
        'title': query,
        'summary': 'Arama sonucu bulunamadı.',
        'url': '',
        'content': '',
      };
    } catch (e) {
      print('Python arama ve özetleme hatası: $e');
      return {
        'title': query,
        'summary': 'Arama sırasında hata oluştu.',
        'url': '',
        'content': '',
      };
    }
  }
  
  /// Rastgele bir Wikipedia makalesini alır ve özetler
  Future<Map<String, dynamic>?> getRandomSummary() async {
    try {
      final uri = Uri.parse('$baseUrl/random-summary');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'title': data['title'] ?? 'Rastgele Makale',
            'summary': data['summary'] ?? 'Özet oluşturulamadı.',
            'content': data['content'] ?? '',
            'url': data['url'] ?? '',
          };
        }
      }
      
      return null;
    } catch (e) {
      print('Python rastgele makale hatası: $e');
      return null;
    }
  }
  
  /// Python servisinin sağlık durumunu kontrol eder
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy';
      }
      
      return false;
    } catch (e) {
      print('Python servisi sağlık kontrolü hatası: $e');
      return false;
    }
  }
  
  /// Servis URL'ini günceller (test ve production ortamları için)
  static void updateBaseUrl(String newUrl) {
    // Bu statik değişken olduğu için runtime'da değiştirilemez
    // Bunun yerine .env dosyasını kullanabiliriz
    print('Python servisi URL güncellenmek isteniyor: $newUrl');
    print('Lütfen .env dosyasında PYTHON_SUMMARY_SERVICE_URL değişkenini güncelleyin');
  }
} 