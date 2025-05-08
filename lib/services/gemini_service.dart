import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/constants.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService() : _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: AppConstants.geminiApiKey,
  );

  /// Wikipedia makale içeriğinden özet oluşturur
  Future<String> generateSummary(String articleContent) async {
    try {
      // Çok uzun bir içerikse kısalt
      final String trimmedContent = articleContent.length > 10000 
          ? articleContent.substring(0, 10000) 
          : articleContent;
      
      // Gemini prompt'unu oluştur
      final prompt = '${AppConstants.geminiPrompt}\n\n$trimmedContent';
      
      // Özet talep et
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      // Yanıtı kontrol et
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      } else {
        return AppConstants.fallbackSummary;
      }
    } catch (e) {
      return AppConstants.fallbackSummary;
    }
  }
} 