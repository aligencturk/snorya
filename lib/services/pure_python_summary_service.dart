import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class PurePythonSummaryService {
  static String get baseUrl => AppConstants.pythonSummaryServiceUrl;
  
  /// Wikipedia makale içeriğini SADECE Python servisi ile özetler
  /// Gemini fallback YOK - Python servisi çalışmak ZORUNDA
  Future<String> generateSummary(String articleContent) async {
    print('🐍 PURE PYTHON SERVİSİ: Özet oluşturma başladı');
    print('🌐 Python Servisi URL: $baseUrl');
    
    try {
      // Önce sağlık kontrolü
      final isHealthy = await checkHealth();
      if (!isHealthy) {
        print('❌ Python servisi çalışmıyor! Lütfen başlatın.');
        return AppConstants.fallbackSummary;
      }
      
      // İçeriği hazırla
      final String trimmedContent = articleContent.length > 15000 
          ? articleContent.substring(0, 15000) 
          : articleContent;
      
      print('📝 İçerik uzunluğu: ${trimmedContent.length}');
      
      // Python servisine istek gönder
      final uri = Uri.parse('$baseUrl/summarize');
      print('📡 İstek gönderiliyor: $uri');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'content': trimmedContent,
          'sentences': 4,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ Python servisi zaman aşımı!');
          throw Exception('Python servisi zaman aşımı');
        },
      );
      
      print('📥 Yanıt alındı - Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Yanıt verisi: $data');
        
        if (data['success'] == true && data['summary'] != null) {
          final summary = data['summary'] as String;
          print('✅ BAŞARILI! Python servisi özet oluşturdu');
          print('💰 Maliyet: ${data['cost'] ?? "0₺ - ÜCRETSIZ"}');
          print('📏 Özet uzunluğu: ${summary.length}');
          return summary;
        } else {
          print('⚠️ Python servisi başarısız yanıt döndü');
          return AppConstants.fallbackSummary;
        }
      } else {
        print('❌ HTTP Hatası: ${response.statusCode}');
        print('📄 Hata detayı: ${response.body}');
        return AppConstants.fallbackSummary;
      }
    } catch (e) {
      print('💥 KRITIK HATA: Python servisi çalışmıyor!');
      print('🔍 Hata detayı: $e');
      print('💡 Çözüm: Python servisini başlatmak için "cd python_summary_service && python main.py" çalıştırın');
      return AppConstants.fallbackSummary;
    }
  }
  
  /// Python servisinin sağlık durumunu kontrol eder
  Future<bool> checkHealth() async {
    try {
      print('🏥 Sağlık kontrolü başlatılıyor...');
      final uri = Uri.parse('$baseUrl/health');
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ Sağlık kontrolü zaman aşımı');
          throw Exception('Sağlık kontrolü zaman aşımı');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isHealthy = data['status'] == 'healthy';
        print('💚 Sağlık durumu: ${isHealthy ? "SAĞLIKLI" : "SORUNLU"}');
        return isHealthy;
      } else {
        print('🔴 Sağlık kontrolü başarısız: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('💥 Sağlık kontrolü hatası: $e');
      return false;
    }
  }
  
  /// Wikipedia'da arama yapar ve bulunan makaleyi özetler
  Future<Map<String, dynamic>> searchAndSummarize(String query) async {
    print('🔍 Arama ve özetleme: $query');
    
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
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          print('✅ Arama başarılı: ${data['title']}');
          return {
            'title': data['title'] ?? query,
            'summary': data['summary'] ?? 'Özet oluşturulamadı.',
            'url': data['url'] ?? '',
            'content': data['content'] ?? '',
          };
        }
      }
      
      print('❌ Arama başarısız');
      return {
        'title': query,
        'summary': 'Python servisi ile arama yapılamadı.',
        'url': '',
        'content': '',
      };
    } catch (e) {
      print('💥 Arama hatası: $e');
      return {
        'title': query,
        'summary': 'Python servisine bağlanılamadı.',
        'url': '',
        'content': '',
      };
    }
  }
  
  /// Rastgele bir Wikipedia makalesini alır ve özetler
  Future<Map<String, dynamic>?> getRandomSummary() async {
    print('🎲 Rastgele makale alınıyor...');
    
    try {
      final uri = Uri.parse('$baseUrl/random-summary');
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          print('✅ Rastgele makale alındı: ${data['title']}');
          return {
            'title': data['title'] ?? 'Rastgele Makale',
            'summary': data['summary'] ?? 'Özet oluşturulamadı.',
            'content': data['content'] ?? '',
            'url': data['url'] ?? '',
          };
        }
      }
      
      print('❌ Rastgele makale alınamadı');
      return null;
    } catch (e) {
      print('💥 Rastgele makale hatası: $e');
      return null;
    }
  }
  
  /// Servisi başlatma talimatları
  static String getStartupInstructions() {
    return '''
🐍 PYTHON SERVİSİNİ BAŞLATMAK İÇİN:

1. Terminal açın
2. Proje klasörüne gidin: cd /Users/gorkem/Projeler/snorya
3. Python servisi klasörüne gidin: cd python_summary_service
4. Servisi başlatın: python main.py

Servis başlatıldıktan sonra http://localhost:5001 adresinde çalışacaktır.

❓ Test etmek için: curl http://localhost:5001/health
    ''';
  }
} 