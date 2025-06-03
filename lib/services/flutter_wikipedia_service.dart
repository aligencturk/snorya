import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:wikipedia/wikipedia.dart';
import '../utils/constants.dart';

/// Python sunucu gerektirmeden Wikipedia API'yi direkt kullanan servis
class FlutterWikipediaService {
  final Wikipedia _wikipedia = Wikipedia();
  final Random _random = Random();

  /// Wikipedia'da arama yapar ve bulunan makaleyi özetler
  Future<Map<String, dynamic>> searchAndSummarize(String query) async {
    try {
      print('🔍 Flutter Wikipedia ile arama: $query');
      
      // Wikipedia'da arama yap
      final searchResult = await _wikipedia.searchQuery(
        searchQuery: query, 
        limit: 1
      );
      
      if (searchResult?.query?.search?.isEmpty ?? true) {
        return {
          'title': query,
          'summary': '$query konusu hakkında bilgi bulunamadı.',
          'url': '',
          'content': '',
        };
      }
      
      final firstResult = searchResult!.query!.search![0];
      final pageId = firstResult.pageid;
      
      if (pageId == null) {
        return {
          'title': query,
          'summary': 'Makale bulunamadı.',
          'url': '',
          'content': '',
        };
      }
      
      // Makale detaylarını al
      final summaryResult = await _wikipedia.searchSummaryWithPageId(
        pageId: pageId
      );
      
      if (summaryResult == null) {
        return {
          'title': firstResult.title ?? query,
          'summary': 'Makale özeti alınamadı.',
          'url': '',
          'content': '',
        };
      }
      
      // Wikipedia URL'ini oluştur
      final encodedTitle = Uri.encodeComponent(
        (summaryResult.title ?? query).replaceAll(' ', '_')
      );
      final url = 'https://tr.wikipedia.org/wiki/$encodedTitle';
      
      // Özetleme yap (ilk 4 cümle)
      final fullContent = summaryResult.extract ?? '';
      final summary = _summarizeText(fullContent, 4);
      
      print('✅ Wikipedia makale bulundu: ${summaryResult.title}');
      
      return {
        'title': summaryResult.title ?? query,
        'summary': summary,
        'url': url,
        'content': fullContent,
      };
    } catch (e) {
      print('❌ Flutter Wikipedia hatası: $e');
      return {
        'title': query,
        'summary': 'Wikipedia araması sırasında hata oluştu.',
        'url': '',
        'content': '',
      };
    }
  }
  
  /// Rastgele bir Wikipedia makalesini alır ve özetler
  Future<Map<String, dynamic>?> getRandomSummary() async {
    try {
      print('🎲 Rastgele Wikipedia makalesi alınıyor...');
      
      // Rastgele arama terimi oluştur
      final randomTerms = [
        'Türkiye', 'İstanbul', 'Teknoloji', 'Tarih', 'Bilim',
        'Doğa', 'Hayvan', 'Bitki', 'Sanat', 'Müzik', 'Edebiyat',
        'Coğrafya', 'Matematik', 'Fizik', 'Kimya', 'Biyoloji'
      ];
      
      final randomTerm = randomTerms[_random.nextInt(randomTerms.length)];
      
      // Rastgele arama yap
      final searchResult = await _wikipedia.searchQuery(
        searchQuery: randomTerm, 
        limit: 10
      );
      
      if (searchResult?.query?.search?.isEmpty ?? true) {
        return null;
      }
      
      // Sonuçlardan rastgele birini seç
      final results = searchResult!.query!.search!;
      final randomResult = results[_random.nextInt(results.length)];
      final pageId = randomResult.pageid;
      
      if (pageId == null) {
        return null;
      }
      
      // Makale detaylarını al
      final summaryResult = await _wikipedia.searchSummaryWithPageId(
        pageId: pageId
      );
      
      if (summaryResult == null) {
        return null;
      }
      
      // Wikipedia URL'ini oluştur
      final encodedTitle = Uri.encodeComponent(
        (summaryResult.title ?? '').replaceAll(' ', '_')
      );
      final url = 'https://tr.wikipedia.org/wiki/$encodedTitle';
      
      // Özetleme yap
      final fullContent = summaryResult.extract ?? '';
      final summary = _summarizeText(fullContent, 4);
      
      print('✅ Rastgele makale: ${summaryResult.title}');
      
      return {
        'title': summaryResult.title ?? 'Rastgele Makale',
        'summary': summary,
        'url': url,
        'content': fullContent,
      };
    } catch (e) {
      print('❌ Rastgele makale hatası: $e');
      return null;
    }
  }
  
  /// Metin özetleme fonksiyonu
  String _summarizeText(String text, int sentences) {
    if (text.isEmpty) {
      return 'İçerik bulunamadı.';
    }
    
    // Metni cümlelere ayır
    final sentencesList = text
        .replaceAll('\n', ' ')
        .split('.')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 10)
        .toList();
    
    if (sentencesList.isEmpty) {
      return 'Özet oluşturulamadı.';
    }
    
    // İstenilen sayıda cümle al
    final selectedSentences = sentencesList.take(sentences).toList();
    
    // Cümleleri birleştir
    return selectedSentences.join('. ') + '.';
  }
  
  /// Belirli bir makale başlığının içeriğini özetler
  Future<String> summarizeContent(String content, {int sentences = 4}) async {
    return _summarizeText(content, sentences);
  }
  
  /// Sağlık kontrolü
  Future<bool> isHealthy() async {
    try {
      // Basit bir arama yaparak servisin çalışıp çalışmadığını kontrol et
      final result = await _wikipedia.searchQuery(
        searchQuery: 'test',
        limit: 1
      );
      return result != null;
    } catch (e) {
      return false;
    }
  }
} 