import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'Snorya';
  
  // API Anahtar
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  
  // Kategori Sabitleri
  static const String categoryScience = 'Bilim';
  static const String categoryHistory = 'Tarih';
  static const String categoryTechnology = 'Teknoloji';
  static const String categoryCulture = 'Kültür';
  static const String categoryGames = 'Oyun';
  static const String categoryMoviesTv = 'Dizi/Film';
  static const String categoryMixed = 'Karışık';
  static const String categoryCustom = 'Özel';
  
  static const List<String> categories = [
    categoryMixed,
    categoryScience,
    categoryHistory,
    categoryTechnology,
    categoryCulture,
    categoryGames,
    categoryMoviesTv,
    categoryCustom,
  ];
  
  
  // Wikipedia API Sabitleri
  static String get wikipediaApiBaseUrl => dotenv.env['WIKIPEDIA_API_URL'] ?? 'https://tr.wikipedia.org/w/api.php';
  static String get wikipediaEnApiBaseUrl => dotenv.env['WIKIPEDIA_EN_API_URL'] ?? 'https://en.wikipedia.org/w/api.php';
  
  // Wikimedia API Sabitleri
  static String get wikiSpeciesApiBaseUrl => dotenv.env['WIKISPECIES_API_URL'] ?? 'https://species.wikimedia.org/w/api.php';
  static String get commonsApiBaseUrl => dotenv.env['COMMONS_API_URL'] ?? 'https://commons.wikimedia.org/w/api.php';
  static String get wikiDataApiBaseUrl => dotenv.env['WIKIDATA_API_URL'] ?? 'https://www.wikidata.org/w/api.php';
  static String get wikiSourceApiBaseUrl => dotenv.env['WIKISOURCE_API_URL'] ?? 'https://wikisource.org/w/api.php';
  
  // Gemini Prompt
  static const String geminiPrompt = 
      'Bu Wikipedia makalesinin içeriğini Türkçe olarak 3-4 cümleyle özetle. '
      'Cevabın sadece özet olsun, fazladan açıklama veya giriş cümlesi ekleme:';
  
  // Ön bellek Anahtarları
  static const String cacheKeyFavorites = 'favorites';
  static const String cacheKeyLastCategory = 'last_category';
  static const String cacheKeyCustomTopics = 'custom_topics';
  static const String cacheKeyLastCustomTopic = 'last_custom_topic';
  static const String cacheKeyMovieFavorites = 'movie_favorites';
  
  // Hata Mesajları
  static const String errorLoadingArticle = 'Makale yüklenirken bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorGeneratingSummary = 'Özet oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorLoadingImage = 'Görsel yüklenirken bir hata oluştu.';
  
  // Fallback Mesajları
  static const String fallbackSummary = 'Bu makalenin özeti şu anda mevcut değil. Lütfen daha sonra tekrar deneyin.';
  static const String fallbackImageUrl = 'assets/images/placeholder.png';
} 