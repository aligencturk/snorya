import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/wiki_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
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
  
  ArticleLoadingState _state = ArticleLoadingState.initial;
  String _selectedCategory = AppConstants.categoryMixed;
  List<Article> _articles = [];
  int _currentIndex = 0;
  String _errorMessage = '';
  
  ArticleViewModel({
    required WikiService wikiService,
    required GeminiService geminiService,
    required StorageService storageService,
  }) : _wikiService = wikiService,
       _geminiService = geminiService,
       _storageService = storageService;
  
  // Getters
  ArticleLoadingState get state => _state;
  String get selectedCategory => _selectedCategory;
  List<Article> get articles => _articles;
  int get currentIndex => _currentIndex;
  String get errorMessage => _errorMessage;
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
      
      // İlk makaleyi yükle
      await _loadNextArticle();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// Bir sonraki makaleyi yükle
  Future<void> loadNextArticle() async {
    _state = ArticleLoadingState.loading;
    notifyListeners();
    
    try {
      await _loadNextArticle();
      _currentIndex = _articles.length - 1;
      notifyListeners();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  /// Makale yükleme iç fonksiyonu
  Future<void> _loadNextArticle() async {
    try {
      // Rastgele bir makale başlığı al
      final String title = await _wikiService.getRandomArticleTitle(_selectedCategory);
      
      // Makale içeriğini al
      final String content = await _wikiService.getArticleContent(title);
      
      // Gemini API ile özet oluştur
      final String summary = await _geminiService.generateSummary(content);
      
      // Makale görselini al
      final String imageUrl = await _wikiService.getArticleImage(title);
      
      // Favori durumunu kontrol et
      final bool isFavorite = await _storageService.isFavorite(title);
      
      // Yeni makaleyi oluştur
      final Article article = Article(
        title: title,
        content: content,
        summary: summary,
        imageUrl: imageUrl,
        category: _selectedCategory,
        isFavorite: isFavorite,
      );
      
      // Makaleyi listeye ekle
      _articles.add(article);
      
      _state = ArticleLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      throw Exception(AppConstants.errorLoadingArticle);
    }
  }
  
  /// Kategori değiştir
  Future<void> changeCategory(String category) async {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      await _storageService.saveLastCategory(category);
      
      // Yeni kategoride makale yükle
      await loadNextArticle();
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
} 