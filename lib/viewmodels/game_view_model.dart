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
  bool _isCustomSearch = false; // Özel arama mı yapıldı?
  
  // Kategori bazlı duplikasyon takibi için map
  Map<String, Set<String>> _categoryTitleSets = {
    'Tümü': {},
  };
  
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
    
    // Özel arama mı yoksa genel öneri mi belirleme
    if (!query.contains('popüler') && !query.contains('oyun önerisi')) {
      _isCustomSearch = true; // Bu özel bir arama
    } else {
      _isCustomSearch = false; // Bu genel bir öneri
    }
    
    // Oyun listesini temizle
    _games = [];
    
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
      
      // Duplikasyon kontrolü için kategori
      final category = 'Tümü';
      
      // İlgili kategori için mevcut oyun başlıklarını al (duplikasyon kontrolü için)
      final Set<String> existingTitlesInCategory = _categoryTitleSets[category] ?? {};
      
      // Duplikasyon kontrolü yap
      List<Game> finalGameList = gameRecommendations;
      
      if (existingTitlesInCategory.isNotEmpty) {
        finalGameList = gameRecommendations.where((game) {
          // Başlığa göre duplikasyon kontrolü
          return !existingTitlesInCategory.contains(game.title.toLowerCase());
        }).toList();
        
        // Eğer filtreleme sonrası hiç oyun kalmadıysa, farklı bir sorgu dene
        if (finalGameList.isEmpty) {
          // Farklı sorgu oluşturalım
          List<String> alternativeQueries = [
            'yeni oyunları',
            'popüler oyunları',
            'en iyi oyunları',
            'klasik oyunları',
            'ödüllü oyunları'
          ];
          
          // Rastgele bir sorgu seç
          final random = Random();
          String newQuery = alternativeQueries[random.nextInt(alternativeQueries.length)].trim();
          
          // Yeni sorgu ile oyun önerileri al
          final alternativeRecommendations = await _geminiService.generateGameRecommendation(newQuery);
          
          // Duplikasyon kontrolü yap
          finalGameList = alternativeRecommendations.where((game) {
            return !existingTitlesInCategory.contains(game.title.toLowerCase());
          }).toList();
          
          // Hala bulunamadıysa orijinal listeyi kullan
          if (finalGameList.isEmpty) {
            finalGameList = gameRecommendations;
          }
        }
      }
      
      // Her bir oyun için Wikipedia'dan görsel ve ek içerik al
      final enrichedGames = <Game>[];
      
      for (final game in finalGameList) {
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
                'fullTitle': wikiData['title'] ?? game.title,
                'summary': wikiData['summary'] ?? game.summary,
                'url': wikiData['url'] ?? '',
                'categories': wikiData['categories'],
              },
              ratings: ratings,
              reviews: reviews,
            );
            
            // Kategori başlık setine ekle
            _categoryTitleSets[category]?.add(enrichedGame.title.toLowerCase());
            
            // Listeye ekle
            enrichedGames.add(enrichedGame);
          } else {
            // Wikipedia'dan bilgi alınamadıysa, en azından görsel URL'si ile güncelle
            String imageUrl = '';
            try {
              imageUrl = await _wikiService.searchImage(searchTitle, isEnglish: false);
              if (imageUrl.isEmpty) {
                imageUrl = await _wikiService.searchImage(searchTitle, isEnglish: true);
              }
            } catch (e) {
              imageUrl = '';
            }
            
            final updatedGame = game.copyWith(
              imageUrl: imageUrl,
            );
            
            // Listeye ekle
            enrichedGames.add(updatedGame);
            
            // Kategori başlık setine ekle
            _categoryTitleSets[category]?.add(updatedGame.title.toLowerCase());
          }
        } catch (e) {
          print("Oyun zenginleştirme hatası: $e");
          
          // Hataya rağmen oyunu ekle
          enrichedGames.add(game);
          
          // Kategori başlık setine ekle
          _categoryTitleSets[category]?.add(game.title.toLowerCase());
        }
      }
      
      // Oyunları state'e ekle ve UI'ı güncelle
      _games = enrichedGames;
      _state = GameLoadingState.loaded;
    } catch (e) {
      print("Oyun önerisi alma hatası: $e");
      _state = GameLoadingState.error;
      _errorMessage = 'Oyun önerisi alınırken bir hata oluştu: ${e.toString()}';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
  
  /// Yeni bir oyun önerisi getir (yenile)
  Future<void> refreshGameRecommendation() async {
    // Kategori bazlı duplikasyon listesini sıfırla
    if (_categoryTitleSets.containsKey('Tümü')) {
      _categoryTitleSets['Tümü'] = {};
    }
    
    // Oyun listesini temizle, böylece yeni içerik yüklensin
    _games = [];
    
    // Aktif filtreye veya özel aramaya göre yenileme yap
    if (_isCustomSearch) {
      // Özel arama varsa aynı sorguyla devam et
      await generateGameRecommendation(_lastQuery);
    } else {
      // Hiçbir özel durumda değilsek rastgele getir ama içerik çeşitliliğini artır
      List<String> generalQueries = [
        'popüler oyun önerisi',
        'en iyi oyunlar',
        'yeni çıkan oyunlar',
        'yüksek puanlı oyunlar',
        'en çok oynanan oyunlar'
      ];
      
      // Rastgele bir sorgu seç
      final random = Random();
      final String generalQuery = generalQueries[random.nextInt(generalQueries.length)];
      
      await generateGameRecommendation(generalQuery);
    }
  }
  
  /// Kategori bazlı duplikasyon listelerini tümüyle temizle
  void clearAllCategoryLists() {
    for (final key in _categoryTitleSets.keys) {
      _categoryTitleSets[key] = {};
    }
  }
  
  /// Belirli bir kategorinin duplikasyon listesini temizle
  void clearCategoryList(String category) {
    if (_categoryTitleSets.containsKey(category)) {
      _categoryTitleSets[category] = {};
    }
  }
  
  /// Benzer bir oyun önerisi getir
  Future<void> loadSimilarGameRecommendation() async {
    if (_games.isNotEmpty) {
      final currentGame = _games.first;
      String query = 'şuna benzer oyun önerisi: ${currentGame.title}';
      
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
      await _loadMoreGamesByQuery(_lastQuery);
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
      
      await _loadMoreGamesByQuery(query);
    }
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
      
      // Mevcut oyun başlıklarını al (duplikasyon kontrolü için)
      final Set<String> existingGameTitles = _games.map((game) => game.title.toLowerCase()).toSet();
      
      // Duplikasyonsuz oyun listesi oluştur
      final List<Game> nonDuplicateGames = gameRecommendations.where((game) {
        // Başlığa göre duplikasyon kontrolü
        return !existingGameTitles.contains(game.title.toLowerCase());
      }).toList();
      
      // Eğer tüm oyunlar duplikasyon ise, farklı bir sorgu deneyelim
      if (nonDuplicateGames.isEmpty) {
        final List<String> alternativeQueries = [
          'yeni çıkan oyunlar',
          'farklı türde oyun önerisi',
          'az bilinen oyun önerisi',
          'indie oyun önerisi',
          'klasik oyun önerisi'
        ];
        
        // Rastgele bir alternatif sorgu seç
        final random = Random();
        final newQuery = alternativeQueries[random.nextInt(alternativeQueries.length)];
        
        // Yeni sorgu ile tekrar dene (genreFilter'ı tümü yap ki daha geniş sonuçlar alsın)
        _state = GameLoadingState.loaded; // Yükleme durumunu güncelle ki sonsuz döngüye girmesin
        notifyListeners();
        
        // Kısa bir gecikme ekleyelim ki API çağrıları çok hızlı yapılmasın
        await Future.delayed(Duration(milliseconds: 300));
        
        // Yeni sorgu ile tekrar dene
        await _loadMoreGamesByQuery(newQuery);
        return;
      }
      
      // Her bir oyun için Wikipedia'dan görsel ve ek içerik al
      final enrichedGames = <Game>[];
      
      for (final game in nonDuplicateGames) {
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
                'fullTitle': wikiData['title'] ?? game.title,
                'summary': wikiData['summary'] ?? game.summary,
                'url': wikiData['url'] ?? '',
                'categories': wikiData['categories'],
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