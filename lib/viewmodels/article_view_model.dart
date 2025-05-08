import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/wiki_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/preload_service.dart';
import '../utils/constants.dart';

enum ArticleLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class ArticleViewModel extends ChangeNotifier {
  final WikiService _wikiService;
  final GeminiService _geminiService;
  final StorageService _storageService;
  final PreloadService _preloadService;
  
  ArticleLoadingState _state = ArticleLoadingState.initial;
  String _selectedCategory = AppConstants.categoryMixed;
  String _selectedCustomTopic = '';
  List<Article> _articles = [];
  int _currentIndex = 0;
  String _errorMessage = '';
  bool _isLoadingMore = false;
  int _pageLoadCount = 0;
  List<String> _customTopics = [];
  
  ArticleViewModel({
    required WikiService wikiService,
    required GeminiService geminiService,
    required StorageService storageService,
    required PreloadService preloadService,
  }) : _wikiService = wikiService,
       _geminiService = geminiService,
       _storageService = storageService,
       _preloadService = preloadService;
  
  // Getters
  ArticleLoadingState get state => _state;
  String get selectedCategory => _selectedCategory;
  String get selectedCustomTopic => _selectedCustomTopic;
  List<Article> get articles => _articles;
  int get currentIndex => _currentIndex;
  String get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  List<String> get customTopics => _customTopics;
  Article? get currentArticle => _articles.isNotEmpty && _currentIndex < _articles.length 
      ? _articles[_currentIndex] 
      : null;
  
  /// ViewModel başlatma
  Future<void> initialize() async {
    _state = ArticleLoadingState.loading;
    notifyListeners();
    
    try {
      // Son seçilen kategoriyi getir
      _selectedCategory = await _storageService.getLastCategory();
      
      // Özel konuları yükle
      _customTopics = await _storageService.getCustomTopics();
      
      // Son seçilen özel konuyu getir
      _selectedCustomTopic = await _storageService.getLastCustomTopic();
      
      // Tüm önbelleği temizle (uygulama her açıldığında farklı içerik)
      _preloadService.clearAllCache();
      _wikiService.clearAllTopicCache();
      
      // Arka planda makaleleri önyüklemeye başla
      _preloadService.initializePreloading();
      
      // İlk birkaç makaleyi hızlıca yükle
      await _loadInitialArticles();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// İlk birkaç makaleyi yükle
  Future<void> _loadInitialArticles() async {
    try {
      // Makale sayacını sıfırla
      _pageLoadCount = 0;
      
      // İlk 3 makaleyi yükle (sonsuz kaydırma için başlangıç)
      for (int i = 0; i < 3; i++) {
        await _loadNextArticle();
      }
      
      _state = ArticleLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// Bir sonraki makaleyi yükle
  Future<void> loadNextArticle() async {
    // Zaten yükleme yapılıyorsa tekrar yükleme yapma
    if (_isLoadingMore || _state == ArticleLoadingState.loading) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      await _loadNextArticle();
      _currentIndex = _articles.length - 1;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _state = ArticleLoadingState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// Makale yükleme iç fonksiyonu
  Future<void> _loadNextArticle() async {
    try {
      // Sayfa yükleme sayacını artır
      _pageLoadCount++;
      
      // Özel kategori için konu parametresi ekle
      String customTopic = '';
      if (_selectedCategory == AppConstants.categoryCustom) {
        customTopic = _selectedCustomTopic;
      }
      
      // Önce önbellekten makale almayı dene
      final article = await _preloadService.getNextArticle(_selectedCategory, customTopic: customTopic);
      
      if (article != null) {
        // Favori durumunu kontrol et
        final bool isFavorite = await _storageService.isFavorite(article.title);
        
        // Makalenin zaten listede olup olmadığını kontrol et
        final isDuplicate = _articles.any((a) => a.title == article.title);
        
        if (!isDuplicate) {
          // Makaleyi listeye ekle
          _articles.add(article.copyWith(isFavorite: isFavorite));
          
          _state = ArticleLoadingState.loaded;
          notifyListeners();
        } else {
          // Eğer bu makale zaten listede varsa tekrar dene
          await _loadNextArticle();
          return;
        }
        
        // Her 10 makale yüklendikten sonra önbelleği temizle
        if (_pageLoadCount % 10 == 0) {
          _wikiService.clearUsedTitles(_selectedCategory);
          if (customTopic.isNotEmpty) {
            _wikiService.clearTopicCache(customTopic);
          }
        }
      } else {
        // Önbellekte makale yoksa normal yükleme işlemine devam et
        final String title = await _wikiService.getRandomArticleTitle(_selectedCategory, customTopic: customTopic);
        final String content = await _wikiService.getArticleContent(title);
        
        // Görsel ve özet işlemlerini paralel yürüt
        final Future<String> imageFuture = _wikiService.getArticleImage(title);
        final Future<String> summaryFuture = _geminiService.generateSummary(content);
        
        final results = await Future.wait([imageFuture, summaryFuture]);
        final String imageUrl = results[0];
        final String summary = results[1];
        
        // Favori durumunu kontrol et
        final bool isFavorite = await _storageService.isFavorite(title);
        
        // Makalenin zaten listede olup olmadığını kontrol et
        final isDuplicate = _articles.any((a) => a.title == title);
        
        if (!isDuplicate) {
          // Yeni makaleyi oluştur
          final newArticle = Article(
            title: title,
            content: content,
            summary: summary,
            imageUrl: imageUrl,
            category: _selectedCategory,
            isFavorite: isFavorite,
          );
          
          // Makaleyi listeye ekle
          _articles.add(newArticle);
          
          _state = ArticleLoadingState.loaded;
          notifyListeners();
        } else {
          // Eğer bu makale zaten listede varsa tekrar dene
          await _loadNextArticle();
          return;
        }
      }
    } catch (e) {
      throw Exception(AppConstants.errorLoadingArticle);
    }
  }
  
  /// Kaydırma sırasında yeni makale yüklemeyi kontrol et
  void checkAndLoadMoreArticles(int currentPageIndex) {
    // Eğer kullanıcı son 3 makaleye geldiyse, yeni makaleler yükle
    if (currentPageIndex >= _articles.length - 3 && !_isLoadingMore) {
      // Birden fazla makale yüklemeyi başlat
      for (int i = 0; i < 2; i++) {
        loadNextArticle();
      }
    }
    
    // Görünen makaleyi güncelle
    if (currentPageIndex < _articles.length) {
      _currentIndex = currentPageIndex;
      notifyListeners();
    }
  }
  
  /// Kategori değiştir
  Future<void> changeCategory(String category) async {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      await _storageService.saveLastCategory(category);
      
      // Makale listesini temizle ve yeniden başla
      _articles = [];
      _currentIndex = 0;
      _pageLoadCount = 0;
      _state = ArticleLoadingState.loading;
      notifyListeners();
      
      // Önceki kategori için önbelleği temizle
      _preloadService.clearCategoryCache(category);
      
      // Arka planda kategori için makaleleri önyüklemeye başla
      _preloadService.preloadArticles(category);
      
      // Yeni kategoride ilk birkaç makaleyi yükle
      await _loadInitialArticles();
    }
  }
  
  /// Özel konuyu değiştir
  Future<void> changeCustomTopic(String topic) async {
    if (_selectedCustomTopic != topic) {
      _selectedCustomTopic = topic;
      await _storageService.saveLastCustomTopic(topic);
      
      // Özel konu değişti, kategoriyi özel olarak ayarla
      if (_selectedCategory != AppConstants.categoryCustom) {
        await changeCategory(AppConstants.categoryCustom);
      } else {
        // Zaten özel kategorideyse, sadece içeriği güncelle
        _articles = [];
        _currentIndex = 0;
        _pageLoadCount = 0;
        _state = ArticleLoadingState.loading;
        notifyListeners();
        
        // Önbelleği temizle
        _wikiService.clearTopicCache(topic);
        
        // Yeni konuda ilk birkaç makaleyi yükle
        await _loadInitialArticles();
      }
    }
  }
  
  /// Yeni özel konu ekle
  Future<void> addCustomTopic(String topic) async {
    if (topic.isNotEmpty && !_customTopics.contains(topic)) {
      await _storageService.addCustomTopic(topic);
      _customTopics = await _storageService.getCustomTopics();
      notifyListeners();
    }
  }
  
  /// Özel konuyu kaldır
  Future<void> removeCustomTopic(String topic) async {
    if (_customTopics.contains(topic)) {
      await _storageService.removeCustomTopic(topic);
      _customTopics = await _storageService.getCustomTopics();
      
      // Eğer seçili konu kaldırıldıysa, başka bir konu seç
      if (_selectedCustomTopic == topic && _customTopics.isNotEmpty) {
        await changeCustomTopic(_customTopics.first);
      }
      
      notifyListeners();
    }
  }
  
  /// Favorilere ekle/çıkar
  Future<void> toggleFavorite() async {
    if (currentArticle == null) return;
    
    final Article article = currentArticle!;
    final bool isFavorite = !article.isFavorite;
    
    if (isFavorite) {
      await _storageService.addToFavorites(article);
    } else {
      await _storageService.removeFromFavorites(article.title);
    }
    
    // Mevcut makaleyi güncellenmiş favori durumuyla değiştir
    _articles[_currentIndex] = article.copyWith(isFavorite: isFavorite);
    notifyListeners();
  }
  
  /// Önceki makaleye geç
  void goToPreviousArticle() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }
  
  /// Sonraki makaleye geç
  void goToNextArticle() {
    if (_currentIndex < _articles.length - 1) {
      _currentIndex++;
      notifyListeners();
    } else {
      loadNextArticle();
    }
  }
  
  /// Index'e göre makaleye geç
  void goToArticle(int index) {
    if (index >= 0 && index < _articles.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  /// Yeni makale talep et
  Future<void> refreshArticle() async {
    await loadNextArticle();
  }
} 