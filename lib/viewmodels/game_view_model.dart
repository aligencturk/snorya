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
  String _activeGenreFilter = 'Tümü'; // Aktif tür filtresi
  bool _isCustomSearch = false; // Özel arama mı yapıldı?
  
  // Getters
  List<Game> get games => _games;
  GameLoadingState get state => _state;
  String get errorMessage => _errorMessage;
  bool get isSearching => _isSearching;
  String get lastQuery => _lastQuery;
  String get activeGenreFilter => _activeGenreFilter; // Aktif tür filtresi getter'ı
  
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
  Future<void> generateGameRecommendation(String query, {String genreFilter = 'Tümü'}) async {
    _state = GameLoadingState.loading;
    _isSearching = true;
    _lastQuery = query;
    _activeGenreFilter = genreFilter; // Aktif filtre türünü ayarla
    
    // Özel arama mı yoksa filtre mi belirleme
    if (genreFilter != 'Tümü') {
      _isCustomSearch = false; // Bu bir filtre araması
    } else if (!query.contains('popüler') && !query.contains('oyun önerisi')) {
      _isCustomSearch = true; // Bu özel bir arama
    } else {
      _isCustomSearch = false; // Bu genel bir öneri
    }
    
    notifyListeners();
    
    try {
      // Eğer filtre aktifse ve özel arama değilse, sorguyu filtre türüne göre düzenle
      String finalQuery = query;
      if (genreFilter != 'Tümü' && !_isCustomSearch) {
        finalQuery = '$genreFilter oyunu önerisi';
      }
      
      // Gemini'den oyun önerisi al
      final gameRecommendations = await _geminiService.generateGameRecommendation(finalQuery);
      
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
      
      // Eğer aktif bir tür filtresi varsa, gelen oyunları filtrele
      List<Game> filteredGames = gameRecommendations;
      if (genreFilter != 'Tümü') {
        filteredGames = gameRecommendations
            .where((game) => 
                game.genre.toLowerCase().contains(genreFilter.toLowerCase()) || 
                genreFilter.toLowerCase().contains(game.genre.toLowerCase()))
            .toList();
        
        // Filtrelenmiş liste boşsa, tüm oyunları kullan ama türlerini güncelle
        if (filteredGames.isEmpty) {
          filteredGames = gameRecommendations.map((game) {
            // Genre'yi aktif filtreye uygun olacak şekilde güncelle
            return game.copyWith(
              genre: genreFilter
            );
          }).toList();
        }
      }
      
      // Her bir oyun için Wikipedia'dan görsel ve ek içerik al
      final enrichedGames = <Game>[];
      
      for (final game in filteredGames) {
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
            
            // Oyun değerlendirmeleri ve puanlarını getir
            Map<String, dynamic>? reviewsAndRatings;
            try {
              reviewsAndRatings = await _geminiService.fetchGameReviewsAndRatings(game.title);
            } catch (e) {
              print("Oyun değerlendirmeleri alınırken hata: $e");
              reviewsAndRatings = null;
            }
            
            // Derecelendirme ve yorumları güvenli şekilde ayarla
            Map<String, dynamic>? ratings = null;
            List<Map<String, dynamic>>? reviews = null;
            
            if (reviewsAndRatings != null) {
              // Ratings verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('ratings') && reviewsAndRatings['ratings'] is Map) {
                ratings = Map<String, dynamic>.from(reviewsAndRatings['ratings']);
              }
              
              // Reviews verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('reviews') && reviewsAndRatings['reviews'] is List) {
                try {
                  reviews = (reviewsAndRatings['reviews'] as List)
                      .map((item) => item is Map 
                          ? Map<String, dynamic>.from(item) 
                          : <String, dynamic>{})
                      .toList();
                } catch (e) {
                  print("Reviews dönüştürme hatası: $e");
                  reviews = null;
                }
              }
            }
            
            // Zenginleştirilmiş oyun bilgisi oluştur
            final enrichedGame = game.copyWith(
              imageUrl: wikiData['imageUrl'] ?? '',
              additionalImages: additionalImages,
              metadata: {
                ...?game.metadata,
                'wikiUrl': wikiData['url'] ?? '',
              },
              ratings: ratings,
              reviews: reviews,
            );
            
            enrichedGames.add(enrichedGame);
          } else {
            // Sadece değerlendirmeleri getir
            Map<String, dynamic>? reviewsAndRatings;
            try {
              reviewsAndRatings = await _geminiService.fetchGameReviewsAndRatings(game.title);
            } catch (e) {
              print("Oyun değerlendirmeleri alınırken hata: $e");
              reviewsAndRatings = null;
            }
            
            // Derecelendirme ve yorumları güvenli şekilde ayarla
            Map<String, dynamic>? ratings = null;
            List<Map<String, dynamic>>? reviews = null;
            
            if (reviewsAndRatings != null) {
              // Ratings verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('ratings') && reviewsAndRatings['ratings'] is Map) {
                ratings = Map<String, dynamic>.from(reviewsAndRatings['ratings']);
              }
              
              // Reviews verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('reviews') && reviewsAndRatings['reviews'] is List) {
                try {
                  reviews = (reviewsAndRatings['reviews'] as List)
                      .map((item) => item is Map 
                          ? Map<String, dynamic>.from(item) 
                          : <String, dynamic>{})
                      .toList();
                } catch (e) {
                  print("Reviews dönüştürme hatası: $e");
                  reviews = null;
                }
              }
            }
            
            // Wikipedia'da bulunamadıysa olduğu gibi ekle, varsa değerlendirmeleri ekle
            final enrichedGame = game.copyWith(
              ratings: ratings,
              reviews: reviews,
            );
            
            enrichedGames.add(enrichedGame);
          }
        } catch (e) {
          // Sadece değerlendirmeleri getir
          Map<String, dynamic>? reviewsAndRatings;
          try {
            reviewsAndRatings = await _geminiService.fetchGameReviewsAndRatings(game.title);
          } catch (e) {
            print("Oyun değerlendirmeleri alınırken hata: $e");
            reviewsAndRatings = null;
          }
          
          // Derecelendirme ve yorumları güvenli şekilde ayarla
          Map<String, dynamic>? ratings = null;
          List<Map<String, dynamic>>? reviews = null;
          
          if (reviewsAndRatings != null) {
            // Ratings verisini güvenli şekilde al
            if (reviewsAndRatings.containsKey('ratings') && reviewsAndRatings['ratings'] is Map) {
              ratings = Map<String, dynamic>.from(reviewsAndRatings['ratings']);
            }
            
            // Reviews verisini güvenli şekilde al
            if (reviewsAndRatings.containsKey('reviews') && reviewsAndRatings['reviews'] is List) {
              try {
                reviews = (reviewsAndRatings['reviews'] as List)
                    .map((item) => item is Map 
                        ? Map<String, dynamic>.from(item) 
                        : <String, dynamic>{})
                    .toList();
              } catch (e) {
                print("Reviews dönüştürme hatası: $e");
                reviews = null;
              }
            }
          }
          
          // Hata durumunda orijinal oyunu ekle, varsa değerlendirmeleri ekle
          final enrichedGame = game.copyWith(
            ratings: ratings,
            reviews: reviews,
          );
          
          enrichedGames.add(enrichedGame);
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
    // Aktif filtreye veya özel aramaya göre yenileme yap
    if (_isCustomSearch) {
      // Özel arama varsa aynı sorguyla devam et
      await generateGameRecommendation(_lastQuery);
    } else if (_activeGenreFilter != 'Tümü') {
      // Belirli bir tür filtresi varsa
      await generateGameRecommendation('popüler oyun önerisi', genreFilter: _activeGenreFilter);
    } else {
      // Hiçbir özel durumda değilsek rastgele getir
      await generateGameRecommendation('popüler oyun önerisi');
    }
  }
  
  /// Benzer bir oyun önerisi getir
  Future<void> loadSimilarGameRecommendation() async {
    if (_games.isNotEmpty) {
      final currentGame = _games.first;
      String query = 'şuna benzer oyun önerisi: ${currentGame.title}';
      
      // Aktif tür filtresi varsa benzer oyun da o türden olsun
      if (_activeGenreFilter != 'Tümü') {
        query += ' $_activeGenreFilter türünde';
      }
      
      await generateGameRecommendation(query, genreFilter: _activeGenreFilter);
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
  
  /// Kaydırma sırasında gerekirse daha fazla oyun yükle
  Future<void> checkAndLoadMoreGames(int currentIndex) async {
    // Eğer kullanıcı listenin sonuna yaklaştıysa yeni oyunlar yükle
    if (currentIndex >= _games.length - 2) {
      await loadMoreGames();
    }
  }
  
  /// Yeni oyunlar yükle ve listeye ekle (sonsuz kaydırma için)
  Future<void> loadMoreGames() async {
    if (_state == GameLoadingState.loading) {
      return; // Zaten yükleme yapılıyorsa çıkış yap
    }
    
    // Aktif filtreye veya özel aramaya bağlı olarak yükleme yapalım
    if (_isCustomSearch) {
      // Özel bir arama varsa aynı sorguyla devam et
      await _loadMoreGamesByQuery(_lastQuery, _activeGenreFilter);
    } else if (_activeGenreFilter != 'Tümü') {
      // Belirli bir tür filtresi varsa
      await _loadMoreGamesByQuery('$_activeGenreFilter oyunu önerisi', _activeGenreFilter);
    } else {
      // Hiçbir özel durumda değilsek rastgele kategori seçelim
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
      
      await _loadMoreGamesByQuery(query, _activeGenreFilter);
    }
  }
  
  /// Belirli bir sorguya göre oyun yükle ve mevcut listeye ekle
  Future<void> _loadMoreGamesByQuery(String query, String genreFilter) async {
    // Yükleniyor durumunu güncelle
    _state = GameLoadingState.loading;
    notifyListeners();
    
    try {
      // Gemini'den oyun önerisi al
      // Tür filtresi varsa sorguyu zenginleştir
      String finalQuery = query;
      if (genreFilter != 'Tümü' && !finalQuery.toLowerCase().contains(genreFilter.toLowerCase())) {
        finalQuery = '$genreFilter türünde $query';
      }
      
      final gameRecommendations = await _geminiService.generateGameRecommendation(finalQuery);
      
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
      
      // Eğer aktif bir tür filtresi varsa, gelen oyunları filtrele
      List<Game> filteredGames = gameRecommendations;
      if (genreFilter != 'Tümü') {
        filteredGames = gameRecommendations
            .where((game) => 
                game.genre.toLowerCase().contains(genreFilter.toLowerCase()) || 
                genreFilter.toLowerCase().contains(game.genre.toLowerCase()))
            .toList();
        
        // Filtrelenmiş liste boşsa, tüm oyunları kullan ama türlerini güncelle
        if (filteredGames.isEmpty) {
          filteredGames = gameRecommendations.map((game) {
            // Genre'yi aktif filtreye uygun olacak şekilde güncelle
            return game.copyWith(
              genre: genreFilter
            );
          }).toList();
        }
      }
      
      // Her bir oyun için Wikipedia'dan görsel ve ek içerik al
      final enrichedGames = <Game>[];
      
      for (final game in filteredGames) {
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
            
            // Oyun değerlendirmeleri ve puanlarını getir
            Map<String, dynamic>? reviewsAndRatings;
            try {
              reviewsAndRatings = await _geminiService.fetchGameReviewsAndRatings(game.title);
            } catch (e) {
              print("Oyun değerlendirmeleri alınırken hata: $e");
              reviewsAndRatings = null;
            }
            
            // Derecelendirme ve yorumları güvenli şekilde ayarla
            Map<String, dynamic>? ratings = null;
            List<Map<String, dynamic>>? reviews = null;
            
            if (reviewsAndRatings != null) {
              // Ratings verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('ratings') && reviewsAndRatings['ratings'] is Map) {
                ratings = Map<String, dynamic>.from(reviewsAndRatings['ratings']);
              }
              
              // Reviews verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('reviews') && reviewsAndRatings['reviews'] is List) {
                try {
                  reviews = (reviewsAndRatings['reviews'] as List)
                      .map((item) => item is Map 
                          ? Map<String, dynamic>.from(item) 
                          : <String, dynamic>{})
                      .toList();
                } catch (e) {
                  print("Reviews dönüştürme hatası: $e");
                  reviews = null;
                }
              }
            }
            
            // Zenginleştirilmiş oyun bilgisi oluştur
            final enrichedGame = game.copyWith(
              imageUrl: wikiData['imageUrl'] ?? '',
              additionalImages: additionalImages,
              metadata: {
                ...?game.metadata,
                'wikiUrl': wikiData['url'] ?? '',
              },
              ratings: ratings,
              reviews: reviews,
            );
            
            enrichedGames.add(enrichedGame);
          } else {
            // Sadece değerlendirmeleri getir
            Map<String, dynamic>? reviewsAndRatings;
            try {
              reviewsAndRatings = await _geminiService.fetchGameReviewsAndRatings(game.title);
            } catch (e) {
              print("Oyun değerlendirmeleri alınırken hata: $e");
              reviewsAndRatings = null;
            }
            
            // Derecelendirme ve yorumları güvenli şekilde ayarla
            Map<String, dynamic>? ratings = null;
            List<Map<String, dynamic>>? reviews = null;
            
            if (reviewsAndRatings != null) {
              // Ratings verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('ratings') && reviewsAndRatings['ratings'] is Map) {
                ratings = Map<String, dynamic>.from(reviewsAndRatings['ratings']);
              }
              
              // Reviews verisini güvenli şekilde al
              if (reviewsAndRatings.containsKey('reviews') && reviewsAndRatings['reviews'] is List) {
                try {
                  reviews = (reviewsAndRatings['reviews'] as List)
                      .map((item) => item is Map 
                          ? Map<String, dynamic>.from(item) 
                          : <String, dynamic>{})
                      .toList();
                } catch (e) {
                  print("Reviews dönüştürme hatası: $e");
                  reviews = null;
                }
              }
            }
            
            // Wikipedia'da bulunamadıysa olduğu gibi ekle, varsa değerlendirmeleri ekle
            final enrichedGame = game.copyWith(
              ratings: ratings,
              reviews: reviews,
            );
            
            enrichedGames.add(enrichedGame);
          }
        } catch (e) {
          // Sadece değerlendirmeleri getir
          Map<String, dynamic>? reviewsAndRatings;
          try {
            reviewsAndRatings = await _geminiService.fetchGameReviewsAndRatings(game.title);
          } catch (e) {
            print("Oyun değerlendirmeleri alınırken hata: $e");
            reviewsAndRatings = null;
          }
          
          // Derecelendirme ve yorumları güvenli şekilde ayarla
          Map<String, dynamic>? ratings = null;
          List<Map<String, dynamic>>? reviews = null;
          
          if (reviewsAndRatings != null) {
            // Ratings verisini güvenli şekilde al
            if (reviewsAndRatings.containsKey('ratings') && reviewsAndRatings['ratings'] is Map) {
              ratings = Map<String, dynamic>.from(reviewsAndRatings['ratings']);
            }
            
            // Reviews verisini güvenli şekilde al
            if (reviewsAndRatings.containsKey('reviews') && reviewsAndRatings['reviews'] is List) {
              try {
                reviews = (reviewsAndRatings['reviews'] as List)
                    .map((item) => item is Map 
                        ? Map<String, dynamic>.from(item) 
                        : <String, dynamic>{})
                    .toList();
              } catch (e) {
                print("Reviews dönüştürme hatası: $e");
                reviews = null;
              }
            }
          }
          
          // Hata durumunda orijinal oyunu ekle, varsa değerlendirmeleri ekle
          final enrichedGame = game.copyWith(
            ratings: ratings,
            reviews: reviews,
          );
          
          enrichedGames.add(enrichedGame);
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
} 