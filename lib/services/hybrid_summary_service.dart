import '../utils/constants.dart';
import 'python_summary_service.dart';

class HybridSummaryService {
  final PythonSummaryService _pythonService = PythonSummaryService();
  
  /// Wikipedia makale içeriğinden özet oluşturur
  /// Sadece Python servisi kullanır
  Future<String> generateSummary(String articleContent) async {
    print('🔍 HybridSummaryService: Özet oluşturma başladı');
    print('📋 usePythonSummaryService: ${AppConstants.usePythonSummaryService}');
    
    try {
      print('🐍 Python servisini deniyor...');
      
      // Önce Python servisinin çalışıp çalışmadığını kontrol et
      final isHealthy = await _pythonService.checkHealth();
      print('💚 Python servisi sağlık durumu: $isHealthy');
      
      if (isHealthy) {
        // Python servisi çalışıyorsa onu kullan
        print('✅ Python servisi kullanılıyor - API MALİYETİ YOK!');
        final summary = await _pythonService.generateSummary(articleContent);
        
        // Python servisinden dönen özet boş veya hatalıysa fallback mesajı kullan
        if (summary == AppConstants.fallbackSummary) {
          print('⚠️ Python servisi başarısız, fallback mesajı kullanılıyor');
          return AppConstants.fallbackSummary;
        }
        
        print('🎉 Python servisi başarılı - Özet uzunluğu: ${summary.length}');
        return summary;
      } else {
        // Python servisi çalışmıyorsa fallback mesajı kullan
        print('❌ Python servisi çalışmıyor, fallback mesajı kullanılıyor');
        return AppConstants.fallbackSummary;
      }
    } catch (e) {
      // Python servisi hata verirse fallback mesajı kullan
      print('💥 Python servisi hatası, fallback mesajı kullanılıyor: $e');
      return AppConstants.fallbackSummary;
    }
  }
  
  /// Servislerin durumunu kontrol eder
  Future<Map<String, bool>> checkServicesHealth() async {
    final pythonHealth = await _pythonService.checkHealth();
    
    return {
      'python': pythonHealth,
    };
  }
  
  /// Hangi servisin kullanıldığını döndürür
  String getCurrentService() {
    return 'Python Wikipedia Service';
  }
  
  /// Servisi değiştirmek için (runtime'da)
  /// Not: Bu sadece test amaçlı
  Future<String> generateSummaryWithSpecificService(
    String articleContent, 
    {bool forcePython = false}
  ) async {
    if (forcePython) {
      return await _pythonService.generateSummary(articleContent);
    } else {
      return await generateSummary(articleContent);
    }
  }
  
  /// Python servisinden özet alır
  Future<Map<String, String>> generateSummaryComparison(String articleContent) async {
    final pythonResult = await _pythonService.generateSummary(articleContent).catchError((e) => 'Python servisi hatası: $e');
    
    return {
      'python': pythonResult,
    };
  }
} 