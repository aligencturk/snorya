import 'dart:collection';
import '../models/article.dart';
import 'wiki_service.dart';
import 'flutter_wikipedia_service.dart';
import '../utils/constants.dart';

class PreloadService {
  final WikiService _wikiService;
  final FlutterWikipediaService _flutterWikipediaService;
  final Map<String, Queue<Article>> _categoryQueues = {};
  bool _isPreloading = false;
  
  PreloadService({
    required WikiService wikiService,
    required FlutterWikipediaService flutterWikipediaService,
  }) : _wikiService = wikiService,
       _flutterWikipediaService = flutterWikipediaService {
    // Her kategori için bir kuyruk oluştur
    for (final category in AppConstants.categories) {
      _categoryQueues[category] = Queue<Article>();
    }
  }
  
  // Belirli kategori için önbellekten bir makale al
  Future<Article?> getNextArticle(String category, {String customTopic = ''}) async {
    final targetQueue = _categoryQueues[category] ?? Queue<Article>();
    
    // Eğer önbellekte bu kategoride makale yoksa yükle
    if (targetQueue.isEmpty) {
      await preloadArticles(category, customTopic: customTopic);
      if (targetQueue.isEmpty) return null;
    }
    
    // Önbellekten bir makale al
    if (targetQueue.isNotEmpty) {
      final article = targetQueue.removeFirst();
      
      // Arka planda daha fazla makale yükle
      _ensurePreloadingForCategory(category, customTopic: customTopic);
      
      return article;
    }
    
    return null;
  }
  
  // Arka planda belirli bir kategori için makaleleri yükle
  Future<void> preloadArticles(String category, {String customTopic = ''}) async {
    // Her kategorinin kendi kuyruğunu kontrol et
    Queue<Article> targetQueue = _categoryQueues[category] ?? Queue<Article>();
    
    // Önbellekte yeterli makale varsa yükleme yapma
    if (targetQueue.length >= 5) return;
    
    if (_isPreloading) return;
    
    _isPreloading = true;
    try {
      // Belirli kategori için yeni makaleler yükle
      int successCount = 0;
      while (targetQueue.length < 10 && successCount < 5) {
        final article = await _loadSingleArticle(category, customTopic: customTopic);
        if (article != null) {
          targetQueue.add(article);
          successCount++;
        }
      }
    } finally {
      _isPreloading = false;
    }
  }
  
  // Tek bir makale yükle
  Future<Article?> _loadSingleArticle(String category, {String customTopic = ''}) async {
    try {
      final String title = await _wikiService.getRandomArticleTitle(
        category, 
        customTopic: customTopic
      );
      final String content = await _wikiService.getArticleContent(title);
      
      // Görsel ve özet işlemlerini paralel yap
      final Future<String> imageFuture = _wikiService.getArticleImage(title);
      // FLUTTER WIKIPEDIA SERVİSİ KULLAN - SUNUCU GEREKMİYOR
      final Future<String> summaryFuture = _flutterWikipediaService.summarizeContent(content);
      
      final results = await Future.wait([imageFuture, summaryFuture]);
      final String imageUrl = results[0];
      final String summary = results[1];
      
      return Article(
        title: title,
        content: content,
        summary: summary,
        imageUrl: imageUrl,
        category: category,
        isFavorite: false,
      );
    } catch (e) {
      print('Makale yükleme hatası: $e');
      return null;
    }
  }
  
  // Kategori için arka planda yeterli makale olduğunu kontrol et
  void _ensurePreloadingForCategory(String category, {String customTopic = ''}) {
    final targetQueue = _categoryQueues[category];
    if (targetQueue != null && targetQueue.length < 5) {
      // Arka planda asenkron olarak daha fazla makale yükle
      Future.microtask(() => preloadArticles(category, customTopic: customTopic));
    }
  }
  
  // Başlangıçta tüm kategoriler için makaleleri önyükle
  Future<void> initializePreloading() async {
    // Önce kullanılmış başlıkları temizle
    _wikiService.clearAllUsedTitles();
    
    // Her kategori için birkaç makale önyükle
    for (final category in AppConstants.categories) {
      // Özel kategori için önyükleme yapmıyoruz
      if (category != AppConstants.categoryCustom) {
        await preloadArticles(category);
      }
    }
  }
  
  // Belirli bir kategori için önbelleği temizle
  void clearCategoryCache(String category) {
    if (_categoryQueues.containsKey(category)) {
      _categoryQueues[category]!.clear();
      _wikiService.clearUsedTitles(category);
    }
  }
  
  // Tüm önbelleği temizle
  void clearAllCache() {
    for (final category in _categoryQueues.keys) {
      _categoryQueues[category]!.clear();
    }
    _wikiService.clearAllUsedTitles();
    _wikiService.clearAllTopicCache();
  }
} 