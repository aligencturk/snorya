import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/gemini_service.dart';
import '../services/wiki_service.dart';
import '../services/storage_service.dart';
import 'dart:math';

enum GameLoadingState { initial, loading, loaded, error, empty }

class GameViewModel extends ChangeNotifier {
  final GeminiService _geminiService;
  final WikiService _wikiService;
  final StorageService _storageService;
  
  List<Game> _games = [];
  GameLoadingState _state = GameLoadingState.initial;
  String _errorMessage = '';
  String _lastQuery = '';
  bool _isSearching = false;
  
  // Getters
  List<Game> get games => _games;
  GameLoadingState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isSearching => _isSearching;
  String get lastQuery => _lastQuery;
  
  GameViewModel({
    required GeminiService geminiService,
    required WikiService wikiService,
    required StorageService storageService,
  }) : 
    _geminiService = geminiService,
    _wikiService = wikiService,
    _storageService = storageService;
  
  /// İlk yükleme için rastgele bir oyun önerisi al
  Future<void> initialize() async {
    if (_state == GameLoadingState.initial) {
      await generateGameRecommendation('popüler oyun önerisi');
    }
  }
  
  /// Kullanıcı sorgusuna göre oyun önerisi getir
  Future<void> generateGameRecommendation(String query) async {
    _state = GameLoadingState.loading;
    _isSearching = true;
    _lastQuery = query;
    notifyListeners();
    
    try {
      // Gemini'den oyun önerisi al
      final gameRecommendations = await _geminiService.generateGameRecommendation(query);
      
      if (gameRecommendations.isEmpty) {
        _state = GameLoadingState.empty;
        _errorMessage = 'Oyun önerisi bulunamadı. Lütfen farklı bir arama terimi deneyin.';
        notifyListeners();
        return;
      }
      
      // Format hatası varsa kontrol et
      if (gameRecommendations.length == 1 && 
          gameRecommendations[0].title == 'Format Hatası') {
        _state = GameLoadingState.error;
        _errorMessage = 'Oyun önerisi alınırken bir format hatası oluştu. Lütfen farklı bir sorgu ile tekrar deneyin.';
        _games = gameRecommendations;
        notifyListeners();
        return;
      }
      
      // Her bir oyun için Wikipedia'dan görsel ve ek içerik al
      final enrichedGames = <Game>[];
      
      for (final game in gameRecommendations) {
        final String searchTitle = game.metadata?['searchTitle'] ?? game.title;
        
        try {
          // Wikipedia'dan içerik al
          final wikiData = await _wikiService.fetchArticleByTitle(searchTitle);
          
          // Eğer Wikipedia'da ilgili içerik bulunursa, oyun bilgilerini zenginleştir
          if (wikiData != null && wikiData.containsKey('imageUrl')) {
            // Ek görselleri alma
            List<Map<String, dynamic>>? additionalImages;
            
            try {
              additionalImages = await _wikiService.fetchCommonsImages(searchTitle, limit: 5);
            } catch (e) {
              additionalImages = null;
            }
            
            // Zenginleştirilmiş oyun bilgisi oluştur
            final enrichedGame = game.copyWith(
              imageUrl: wikiData['imageUrl'] ?? '',
              additionalImages: additionalImages,
              metadata: {
                ...?game.metadata,
                'wikiUrl': wikiData['url'] ?? '',
              },
            );
            
            enrichedGames.add(enrichedGame);
          } else {
            // Wikipedia'da bulunamadıysa olduğu gibi ekle
            enrichedGames.add(game);
          }
        } catch (e) {
          // Hata durumunda orijinal oyunu ekle
          enrichedGames.add(game);
        }
      }
      
      // Önerileri güncelle
      _games = enrichedGames;
      _state = GameLoadingState.loaded;
    } catch (e) {
      _state = GameLoadingState.error;
      _errorMessage = 'Oyun önerisi alınırken bir hata oluştu: ${e.toString()}';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  /// Yeni bir oyun önerisi getir (yenile)
  Future<void> refreshGameRecommendation() async {
    if (_lastQuery.isNotEmpty) {
      await generateGameRecommendation(_lastQuery);
    } else {
      await generateGameRecommendation('popüler oyun önerisi');
    }
  }
  
  /// Benzer bir oyun önerisi getir
  Future<void> loadSimilarGameRecommendation() async {
    if (_games.isNotEmpty) {
      final currentGame = _games.first;
      final query = 'şuna benzer oyun önerisi: ${currentGame.title}';
      await generateGameRecommendation(query);
    } else {
      await refreshGameRecommendation();
    }
  }
  
  /// Favori durumunu değiştir
  void toggleFavorite() {
    if (_games.isNotEmpty) {
      final currentGame = _games.first;
      final updatedGame = currentGame.copyWith(isFavorite: !currentGame.isFavorite);
      
      _games = [updatedGame, ..._games.sublist(1)];
      notifyListeners();
      
      // Favori durumunu kaydet
      _saveFavoriteGames();
    }
  }
  
  /// Favori oyunları kaydet
  Future<void> _saveFavoriteGames() async {
    try {
      final favoriteGames = _games.where((game) => game.isFavorite).toList();
      await _storageService.saveData('favorite_games', favoriteGames.map((game) => game.toJson()).toList());
    } catch (e) {
      debugPrint('Favori oyunlar kaydedilirken hata: $e');
    }
  }
  
  /// Yeni oyunlar yükle ve listeye ekle (sonsuz kaydırma için)
  Future<void> loadMoreGames() async {
    if (_state == GameLoadingState.loading) {
      return; // Zaten yükleme yapılıyorsa çıkış yap
    }
    
    // Rastgele çeşitli sorgu terimleri kullanalım
    final List<String> queryTerms = [
      'popüler oyun önerisi',
      'macera oyunu',
      'strateji oyunu',
      'yarış oyunu',
      'rol yapma oyunu',
      'aksiyon oyunu',
      'simülasyon oyunu',
      'platform oyunu',
      'bulmaca oyunu',
      'spor oyunu'
    ];
    
    // Rastgele bir sorgu terimi seç
    final random = Random();
    final query = queryTerms[random.nextInt(queryTerms.length)];
    
    await _loadMoreGamesByQuery(query);
  }
  
  /// Belirli bir sorguya göre oyun yükle ve mevcut listeye ekle
  Future<void> _loadMoreGamesByQuery(String query) async {
    // Yükleniyor durumunu güncelle
    _state = GameLoadingState.loading;
    notifyListeners();
    
    try {
      // Gemini'den oyun önerisi al
      final gameRecommendations = await _geminiService.generateGameRecommendation(query);
      
      if (gameRecommendations.isEmpty) {
        _state = GameLoadingState.loaded; // Boş liste gelirse sadece durumu güncelle
        notifyListeners();
        return;
      }
      
      // Format hatası varsa kontrol et
      if (gameRecommendations.length == 1 && 
          gameRecommendations[0].title == 'Format Hatası') {
        _state = GameLoadingState.loaded; // Hata varsa sadece durumu güncelle
        notifyListeners();
        return;
      }
      
      // Her bir oyun için Wikipedia'dan görsel ve ek içerik al
      final enrichedGames = <Game>[];
      
      for (final game in gameRecommendations) {
        final String searchTitle = game.metadata?['searchTitle'] ?? game.title;
        
        try {
          // Wikipedia'dan içerik al
          final wikiData = await _wikiService.fetchArticleByTitle(searchTitle);
          
          // Eğer Wikipedia'da ilgili içerik bulunursa, oyun bilgilerini zenginleştir
          if (wikiData != null && wikiData.containsKey('imageUrl')) {
            // Ek görselleri alma
            List<Map<String, dynamic>>? additionalImages;
            
            try {
              additionalImages = await _wikiService.fetchCommonsImages(searchTitle, limit: 5);
            } catch (e) {
              additionalImages = null;
            }
            
            // Zenginleştirilmiş oyun bilgisi oluştur
            final enrichedGame = game.copyWith(
              imageUrl: wikiData['imageUrl'] ?? '',
              additionalImages: additionalImages,
              metadata: {
                ...?game.metadata,
                'wikiUrl': wikiData['url'] ?? '',
              },
            );
            
            enrichedGames.add(enrichedGame);
          } else {
            // Wikipedia'da bulunamadıysa olduğu gibi ekle
            enrichedGames.add(game);
          }
        } catch (e) {
          // Hata durumunda orijinal oyunu ekle
          enrichedGames.add(game);
        }
      }
      
      // Yeni oyunları mevcut listeye ekle
      _games = [..._games, ...enrichedGames];
      _state = GameLoadingState.loaded;
    } catch (e) {
      // Yükleme hatası durumunda durumu güncelle, ama mevcut oyunları tut
      _state = GameLoadingState.loaded;
      _errorMessage = 'Yeni oyun önerileri alınırken bir hata oluştu: ${e.toString()}';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  /// Kaydırma sırasında gerekirse daha fazla oyun yükle
  Future<void> checkAndLoadMoreGames(int currentIndex) async {
    // Eğer kullanıcı listenin sonuna yaklaştıysa yeni oyunlar yükle
    if (currentIndex >= _games.length - 2) {
      await loadMoreGames();
    }
  }
} 