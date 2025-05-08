class AppConstants {
  static const String appName = 'Snorya';
  
  // API Anahtar
  static const String geminiApiKey = 'AIzaSyB53XGwpaQ25hPyLlBja4wu_ZcjP33IrHQ'; // Gerçek bir API anahtarı ile değiştirilmeli
  
  // Kategori Sabitleri
  static const String categoryScience = 'Bilim';
  static const String categoryHistory = 'Tarih';
  static const String categoryTechnology = 'Teknoloji';
  static const String categoryCulture = 'Kültür';
  static const String categoryMixed = 'Karışık';
  static const String categoryCustom = 'Özel';
  
  static const List<String> categories = [
    categoryMixed,
    categoryScience,
    categoryHistory,
    categoryTechnology,
    categoryCulture,
    categoryCustom,
  ];
  
  // Özel Kategoriler için Öneriler
  static const List<String> suggestedCustomTopics = [
    'Fenerbahçe',
    'Galatasaray',
    'Beşiktaş',
    'Trabzonspor',
    'İstanbul',
    'Ankara',
    'Türk Mutfağı',
    'Türk Müziği',
    'Antalya',
    'Kapadokya',
  ];
  
  // Wikipedia API Sabitleri
  static const String wikipediaApiBaseUrl = 'https://tr.wikipedia.org/w/api.php';
  
  // Gemini Prompt
  static const String geminiPrompt = 
      'Bu Wikipedia makalesinin içeriğini Türkçe olarak 3-4 cümleyle özetle. '
      'Cevabın sadece özet olsun, fazladan açıklama veya giriş cümlesi ekleme:';
  
  // Ön bellek Anahtarları
  static const String cacheKeyFavorites = 'favorites';
  static const String cacheKeyLastCategory = 'last_category';
  static const String cacheKeyCustomTopics = 'custom_topics';
  static const String cacheKeyLastCustomTopic = 'last_custom_topic';
  
  // Hata Mesajları
  static const String errorLoadingArticle = 'Makale yüklenirken bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorGeneratingSummary = 'Özet oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorLoadingImage = 'Görsel yüklenirken bir hata oluştu.';
  
  // Fallback Mesajları
  static const String fallbackSummary = 'Bu makalenin özeti şu anda mevcut değil. Lütfen daha sonra tekrar deneyin.';
  static const String fallbackImageUrl = 'assets/images/placeholder.png';
} 