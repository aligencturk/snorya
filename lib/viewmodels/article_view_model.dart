import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/wiki_service.dart';
import '../services/flutter_wikipedia_service.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

enum ArticleLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class ArticleViewModel extends ChangeNotifier {
  final WikiService _wikiService;
  final FlutterWikipediaService _flutterWikipediaService;
  final StorageService _storageService;

  ArticleViewModel({
    required WikiService wikiService,
    required FlutterWikipediaService flutterWikipediaService,
    required StorageService storageService,
  }) : _wikiService = wikiService,
       _flutterWikipediaService = flutterWikipediaService,
       _storageService = storageService;

  List<Article> _articles = [];
  List<Article> get articles => _articles;

  String _selectedCategory = AppConstants.categoryMixed;
  String get selectedCategory => _selectedCategory;

  String _selectedCustomTopic = '';
  String get selectedCustomTopic => _selectedCustomTopic;

  List<String> _customTopics = [];
  List<String> get customTopics => _customTopics;

  ArticleLoadingState _state = ArticleLoadingState.initial;
  ArticleLoadingState get state => _state;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String _errorMessage = AppConstants.errorLoadingArticle;
  String get errorMessage => _errorMessage;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  bool _showWikimediaContent = false; // WikiSpecies ve Commons içeriğini göster
  bool get showWikimediaContent => _showWikimediaContent;

  // Initialize the view model
  Future<void> initialize() async {
    _state = ArticleLoadingState.initial;
    notifyListeners();

    try {
      // Flutter Wikipedia servisinin sağlık durumunu kontrol et
      print('🏥 Flutter Wikipedia servisi sağlık kontrolü...');
      final isHealthy = await _flutterWikipediaService.isHealthy();
      if (!isHealthy) {
        print('❌ Wikipedia servisi çalışmıyor!');
        _state = ArticleLoadingState.error;
        _errorMessage = 'Wikipedia servisi erişim sorunu yaşıyor. İnternet bağlantınızı kontrol edin.';
        notifyListeners();
        return;
      }
      print('✅ Flutter Wikipedia servisi çalışıyor!');

      // Favori makaleleri yükle
      await _loadFavorites();

      // Her zaman karışık kategoriden başla
      _selectedCategory = AppConstants.categoryMixed;
      
      // Kategoriyi kaydet (karışık olarak)
      await _storageService.saveLastCategory(AppConstants.categoryMixed);

      // Özel konuları yükle
      _customTopics = await _storageService.getCustomTopics();

      // İlk makaleyi yükle
      await loadNextArticle();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = 'Başlatılırken hata oluştu: $e';
      notifyListeners();
    }
  }

  // Yeni makale yükle
  Future<void> loadNextArticle() async {
    try {
      _state = ArticleLoadingState.loading;
      notifyListeners();

      // Eğer özel kategori seçiliyse ve özel konu seçilmemişse
      if (_selectedCategory == AppConstants.categoryCustom && _selectedCustomTopic.isEmpty) {
        _state = ArticleLoadingState.error;
        _errorMessage = 'Lütfen özel bir konu seçin veya ekleyin.';
        notifyListeners();
        return;
      }

      // Wikipediadam rastgele makale başlığı al
      final title = await _wikiService.getRandomArticleTitle(
        _selectedCategory,
        customTopic: _selectedCustomTopic,
      );

      // Makale içeriğini al
      final content = await _wikiService.getArticleContent(title);

      // Makale görselini al
      final imageUrl = await _wikiService.getArticleImage(title);

      // Özet oluştur - FLUTTER WIKIPEDIA SERVİSİ KULLAN
      String summary;
      try {
        print('📱 Flutter Wikipedia ile özet oluşturuluyor...');
        summary = await _flutterWikipediaService.summarizeContent(content);
        print('✅ Özet başarıyla oluşturuldu - SUNUCU GEREKMİYOR!');
      } catch (e) {
        print('❌ Flutter Wikipedia özet hatası: $e');
        summary = AppConstants.fallbackSummary;
      }

      // Makale nesnesini oluştur
      var article = Article(
        title: title,
        content: content,
        summary: summary,
        imageUrl: imageUrl,
        category: _selectedCategory,
      );

      // Favorilerde var mı kontrol et
      final favorites = await _storageService.loadFavorites();
      if (favorites.any((fav) => fav.title == article.title)) {
        article = article.copyWith(isFavorite: true);
      }

      // Listeye ekle
      _articles.add(article);
      _currentIndex = _articles.length - 1;

      _state = ArticleLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = 'Makale yüklenirken bir hata oluştu: $e';
      notifyListeners();
    }
  }

  // Kategori değiştir
  Future<void> changeCategory(String category) async {
    if (_selectedCategory != category) {
      // Eski kategori önbelleğini temizle
      _wikiService.clearCategoryCache(_selectedCategory);
      
      _selectedCategory = category;
      
      // Kategoriyi kaydet
      await _storageService.saveLastCategory(category);
      
      // Makaleleri temizle
      _articles = [];
      
      // WikiSpecies veya Commons içeriği gösterme
      _showWikimediaContent = false;
      
      // Yeni kategori için makaleleri yükle
      await loadNextArticle();

      // Kaydırma deneyimini iyileştirmek için, arka planda 2 makale daha yükle
      for (int i = 0; i < 2; i++) {
        await loadNextArticle();
      }
    }
  }

  // Özel konu değiştir
  Future<void> changeCustomTopic(String topic) async {
    if (_selectedCustomTopic != topic) {
      _selectedCustomTopic = topic;
      
      // Özel konuyu kaydet
      await _storageService.saveLastCustomTopic(topic);
      
      if (_selectedCategory == AppConstants.categoryCustom) {
        // Makaleleri temizle ve yeni konu için içerik yükle
        _articles = [];
        await loadNextArticle();
      }
    }
  }

  // Özel konu ekle
  Future<void> addCustomTopic(String topic) async {
    if (!_customTopics.contains(topic)) {
      _customTopics.add(topic);
      
      // Özel konuları kaydet
      await _storageService.saveCustomTopics(_customTopics);
      
      // Seçili konu olarak ata
      await changeCustomTopic(topic);
    } else {
      // Zaten var olan konuyu seç
      await changeCustomTopic(topic);
    }
  }

  // Özel konu sil
  Future<void> removeCustomTopic(String topic) async {
    if (_customTopics.contains(topic)) {
      _customTopics.remove(topic);
      
      // Özel konuları kaydet
      await _storageService.saveCustomTopics(_customTopics);
      
      // Eğer seçili konu silindiyse, ya boşalt ya da başka bir konu seç
      if (_selectedCustomTopic == topic) {
        if (_customTopics.isNotEmpty) {
          await changeCustomTopic(_customTopics.first);
        } else {
          await changeCustomTopic('');
        }
      }
    }
  }

  // Daha fazla makale yüklemeli mi kontrol et
  void checkAndLoadMoreArticles(int index) {
    _currentIndex = index;
    // Kullanıcı makalelerin sonuna yaklaştığında yeni makaleler yükle
    final needsMoreArticles = index >= _articles.length - 3 && !_isLoadingMore;
    
    if (needsMoreArticles) {
      _loadMoreArticles();
    }
  }

  // Daha fazla makale yükle
  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // Paralel olarak 3 makale yükle (daha hızlı kaydırma deneyimi için)
      await Future.wait([
        loadNextArticle(),
        loadNextArticle(),
        loadNextArticle(),
      ]);
    } catch (e) {
      // Hata zaten loadNextArticle içinde işlendi
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Favori durumunu değiştir
  Future<void> toggleFavorite() async {
    if (_articles.isEmpty || _currentIndex >= _articles.length) return;
    
    final article = _articles[_currentIndex];
    final updatedArticle = article.copyWith(isFavorite: !article.isFavorite);
    
    _articles[_currentIndex] = updatedArticle;
    notifyListeners();
    
    // Favori değiştiyse, kaydet/kaldır
    final favorites = await _storageService.loadFavorites();
    
    if (updatedArticle.isFavorite) {
      // Ekle
      favorites.add(updatedArticle);
    } else {
      // Kaldır (başlıkla eşleşen tüm makaleleri)
      favorites.removeWhere((a) => a.title == article.title);
    }
    
    await _storageService.saveFavorites(favorites);
  }

  // Favorileri yükle
  Future<void> _loadFavorites() async {
    try {
      // Favorileri kontrol et
      await _storageService.loadFavorites();
    } catch (e) {
      // Hata olursa yok sayabilir
    }
  }
  
  // Makaleyi yenile
  Future<void> refreshArticle() async {
    await loadNextArticle();
  }
  
  // Wiki artıklarını temizle
  void clearWikiCache() {
    _wikiService.clearAllUsedTitles();
    _wikiService.clearAllTopicCache();
  }

  // Mevcut makaleyi güncelle
  void refreshCurrentArticle() async {
    await loadNextArticle();
  }

  // WikiSpecies'dan tür bilgilerini getir
  Future<void> loadWikiSpeciesInfo(String species) async {
    try {
      _state = ArticleLoadingState.loading;
      notifyListeners();

      final speciesData = await _wikiService.getWikiSpeciesInfo(species);
      
      if (speciesData.containsKey('error')) {
        _state = ArticleLoadingState.error;
        _errorMessage = speciesData['error'] as String;
        notifyListeners();
        return;
      }
      
      final article = Article.fromWikiSpecies(speciesData);
      
      // Favorilerde var mı kontrol et
      final favorites = await _storageService.loadFavorites();
      final updatedArticle = favorites.any((fav) => fav.title == article.title)
          ? article.copyWith(isFavorite: true)
          : article;
      
      _articles.add(updatedArticle);
      _currentIndex = _articles.length - 1;
      _showWikimediaContent = true;
      
      _state = ArticleLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = 'WikiSpecies verisi yüklenirken bir hata oluştu: $e';
      notifyListeners();
    }
  }

  // Commons'dan görsel bilgilerini getir
  Future<void> loadCommonsImages(String topic) async {
    try {
      _state = ArticleLoadingState.loading;
      notifyListeners();

      final images = await _wikiService.getCommonsImages(topic);
      
      if (images.isEmpty) {
        _state = ArticleLoadingState.error;
        _errorMessage = 'Commons\'ta bu konu hakkında görsel bulunamadı';
        notifyListeners();
        return;
      }
      
      final article = Article.fromCommons(topic, images);
      
      _articles.add(article);
      _currentIndex = _articles.length - 1;
      _showWikimediaContent = true;
      
      _state = ArticleLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = 'Commons görselleri yüklenirken bir hata oluştu: $e';
      notifyListeners();
    }
  }

  // Gisburn Forest bilgilerini getir
  Future<void> loadGisburnForestInfo() async {
    try {
      _state = ArticleLoadingState.loading;
      notifyListeners();

      final forestData = await _wikiService.getGisburnForestInfo();
      
      if (forestData.containsKey('error')) {
        _state = ArticleLoadingState.error;
        _errorMessage = forestData['error'] as String;
        notifyListeners();
        return;
      }
      
      forestData['source'] = 'Gisburn Forest';
      forestData['url'] = 'https://en.wikipedia.org/wiki/Gisburn_Forest';
      
      final article = Article.fromSpecialContent(forestData);
      
      _articles.add(article);
      _currentIndex = _articles.length - 1;
      _showWikimediaContent = true;
      
      _state = ArticleLoadingState.loaded;
      notifyListeners();
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = 'Orman bilgileri yüklenirken bir hata oluştu: $e';
      notifyListeners();
    }
  }

  // Mevcut makaleye benzer içerik getir
  Future<void> loadSimilarArticle() async {
    try {
      if (_articles.isEmpty || _currentIndex >= _articles.length) return;
      
      final currentArticle = _articles[_currentIndex];
      
      _state = ArticleLoadingState.loading;
      notifyListeners();

      // Wikipediadam benzer makale başlığı al
      final title = await _wikiService.getSimilarArticleTitle(currentArticle.title);

      // Makale içeriğini al
      final content = await _wikiService.getArticleContent(title);

      // Makale görselini al
      final imageUrl = await _wikiService.getArticleImage(title);

      // Özet oluştur - Flutter Wikipedia servisi kullan
      String summary;
      try {
        summary = await _flutterWikipediaService.summarizeContent(content);
      } catch (e) {
        summary = content.length > 200 ? '${content.substring(0, 200)}...' : content;
      }

      // Makale nesnesini oluştur
      var article = Article(
        title: title,
        content: content,
        summary: summary,
        imageUrl: imageUrl,
        category: _selectedCategory,
      );

      // Favorilerde var mı kontrol et
      final favorites = await _storageService.loadFavorites();
      if (favorites.any((fav) => fav.title == article.title)) {
        article = article.copyWith(isFavorite: true);
      }

      // Listeye ekle
      _articles.add(article);
      _currentIndex = _articles.length - 1;

      _state = ArticleLoadingState.loaded;
      notifyListeners();
      
      return; // Future tamamlandı
    } catch (e) {
      _state = ArticleLoadingState.error;
      _errorMessage = 'Benzer makale yüklenirken bir hata oluştu: $e';
      notifyListeners();
      throw e; // Hatayı ileten tarafa gönder ki uygun şekilde işlesin
    }
  }
} 
