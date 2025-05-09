import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/wiki_service.dart';
import '../utils/constants.dart';

enum MovieLoadingState {
  initial,
  loading,
  loaded,
  searching,
  error,
}

class MovieViewModel extends ChangeNotifier {
  final GeminiService _geminiService;
  final WikiService _wikiService;
  final StorageService _storageService;

  List<Movie> _movies = [];
  List<Movie> _filteredMovies = [];
  List<Movie> _favoriteMovies = [];
  MovieLoadingState _state = MovieLoadingState.initial;
  String _selectedCategory = '';
  String _searchQuery = '';
  String _errorMessage = '';
  Movie? _currentMovie;
  bool _hasMoreMovies = true;
  int _page = 1;

  MovieViewModel({
    required GeminiService geminiService,
    required WikiService wikiService,
    required StorageService storageService,
  })  : _geminiService = geminiService,
        _wikiService = wikiService,
        _storageService = storageService;

  // Getters
  List<Movie> get movies => _searchQuery.isEmpty ? _movies : _filteredMovies;
  List<Movie> get favoriteMovies => _favoriteMovies;
  MovieLoadingState get state => _state;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get errorMessage => _errorMessage;
  Movie? get currentMovie => _currentMovie;
  bool get hasMoreMovies => _hasMoreMovies;

  // ViewModel'i başlat
  Future<void> initialize() async {
    if (_state == MovieLoadingState.initial) {
      await loadFavorites();
      await changeCategory(AppConstants.categoryMixed);
    }
  }

  // Dizi/film kategorisini değiştir
  Future<void> changeCategory(String category) async {
    if (_selectedCategory == category && _movies.isNotEmpty) {
      return;
    }

    _selectedCategory = category;
    _page = 1;
    _hasMoreMovies = true;
    _movies.clear();
    _state = MovieLoadingState.loading;
    notifyListeners();

    try {
      final List<Movie> newMovies = await _loadMoviesForCategory(category, _page);
      _movies.addAll(newMovies);
      _state = MovieLoadingState.loaded;
    } catch (e) {
      _state = MovieLoadingState.error;
      _errorMessage = 'Dizi/filmler yüklenirken bir hata oluştu: ${e.toString()}';
    }

    notifyListeners();
  }

  // Kategori için dizi/filmleri yükle
  Future<List<Movie>> _loadMoviesForCategory(String category, int page, {String? type, String? genre}) async {
    // Yapay zeka ile kategori için uygun dizi/film önerileri al
    String prompt = 'Lütfen $category kategorisinde 10 adet popüler ';
    
    // İçerik tipine göre özelleştir
    if (type == 'movie') {
      prompt += 'film ';
    } else if (type == 'tv') {
      prompt += 'dizi ';
    } else {
      prompt += 'dizi ve film ';
    }
    
    // Türe göre özelleştir
    if (genre != null) {
      prompt += 'türü $genre olan ';
    }
    
    prompt += 'öner. Her öneri için şu bilgileri ver: id (benzersiz sayı), başlık, kısa özet, '
        'türler (virgülle ayır), yönetmen, yayın tarihi ve 10 üzerinden puanı. '
        'JSON formatında dön: [{"id": "1", "title": "Film Adı", "overview": "Özet", '
        '"type": "movie/tv", "genres": ["Tür1", "Tür2"], "director": "Yönetmen", '
        '"releaseDate": "Tarih", "rating": 8.5}]';

    final response = await _geminiService.generateContent(prompt);
    
    if (response.isEmpty) {
      throw Exception('Film/dizi önerileri alınamadı');
    }

    try {
      // JSON formatını ayıklama
      String jsonText = response;
      
      // JSON parantezleri bulmaya çalış
      final int startIndex = jsonText.indexOf('[');
      final int endIndex = jsonText.lastIndexOf(']') + 1;
      
      if (startIndex >= 0 && endIndex > startIndex) {
        jsonText = jsonText.substring(startIndex, endIndex);
      }
      
      final List<dynamic> moviesJson = json.decode(jsonText);
      
      final List<Movie> moviesList = [];
      
      for (var movieJson in moviesJson) {
        final movie = Movie.fromJson(movieJson);
        
        // Favori durumunu kontrol et
        final isFavorite = _favoriteMovies.any((fav) => fav.id == movie.id);
        final movieWithFavorite = movie.copyWith(isFavorite: isFavorite);
        
        // Poster URL'ini Wikipedia'dan al
        final posterUrl = await _getPosterUrl(movie.title);
        final movieWithPoster = movieWithFavorite.copyWith(posterUrl: posterUrl);
        
        moviesList.add(movieWithPoster);
      }
      
      return moviesList;
    } catch (e) {
      throw Exception('Film/dizi verisi parse edilemedi: ${e.toString()}');
    }
  }

  // Dizi/film için poster URL'ini al
  Future<String> _getPosterUrl(String title) async {
    try {
      // İlk önce Türkçe, sonra İngilizce Wikipedia'dan arama yap
      final imageUrl = await _wikiService.searchImage(title, isEnglish: false);
      if (imageUrl.isNotEmpty) {
        return imageUrl;
      }
      
      final englishImageUrl = await _wikiService.searchImage(title, isEnglish: true);
      if (englishImageUrl.isNotEmpty) {
        return englishImageUrl;
      }
      
      return AppConstants.fallbackImageUrl;
    } catch (e) {
      return AppConstants.fallbackImageUrl;
    }
  }

  // Daha fazla dizi/film yükle
  Future<void> loadMoreMovies() async {
    if (!_hasMoreMovies || _state == MovieLoadingState.loading) {
      return;
    }
    
    _state = MovieLoadingState.loading;
    notifyListeners();
    
    try {
      _page++;
      final List<Movie> newMovies = await _loadMoviesForCategory(_selectedCategory, _page);
      
      if (newMovies.isEmpty) {
        _hasMoreMovies = false;
      } else {
        _movies.addAll(newMovies);
      }
      
      _state = MovieLoadingState.loaded;
    } catch (e) {
      _state = MovieLoadingState.error;
      _errorMessage = 'Daha fazla dizi/film yüklenirken bir hata oluştu: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Dizi/film ara veya filtrele
  Future<void> searchMovies(String query, {String? type, String? genre}) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      _filteredMovies.clear();
      notifyListeners();
      return;
    }
    
    _state = MovieLoadingState.searching;
    notifyListeners();
    
    try {
      // Benzer dizi/film önerileri için yapay zeka kullan
      String prompt = 'Lütfen "$query" benzer veya bu tarza uygun 10 adet ';
      
      // İçerik tipine göre özelleştir
      if (type == 'movie') {
        prompt += 'film ';
      } else if (type == 'tv') {
        prompt += 'dizi ';
      } else {
        prompt += 'dizi ve film ';
      }
      
      // Türe göre özelleştir
      if (genre != null) {
        prompt += 'türü $genre olan ';
      }
      
      prompt += 'öner. Her öneri için şu bilgileri ver: id (benzersiz sayı), başlık, kısa özet, '
           'türler (virgülle ayır), yönetmen, yayın tarihi ve 10 üzerinden puanı. '
           'JSON formatında dön: [{"id": "1", "title": "Film Adı", "overview": "Özet", '
           '"type": "movie/tv", "genres": ["Tür1", "Tür2"], "director": "Yönetmen", '
           '"releaseDate": "Tarih", "rating": 8.5}]';
      
      final response = await _geminiService.generateContent(prompt);
      
      if (response.isEmpty) {
        throw Exception('Film/dizi önerileri alınamadı');
      }
      
      try {
        // JSON formatını ayıklama
        String jsonText = response;
        
        // JSON parantezleri bulmaya çalış
        final int startIndex = jsonText.indexOf('[');
        final int endIndex = jsonText.lastIndexOf(']') + 1;
        
        if (startIndex >= 0 && endIndex > startIndex) {
          jsonText = jsonText.substring(startIndex, endIndex);
        }
        
        final List<dynamic> moviesJson = json.decode(jsonText);
        
        _filteredMovies.clear();
        
        for (var movieJson in moviesJson) {
          final movie = Movie.fromJson(movieJson);
          
          // Favori durumunu kontrol et
          final isFavorite = _favoriteMovies.any((fav) => fav.id == movie.id);
          final movieWithFavorite = movie.copyWith(isFavorite: isFavorite);
          
          // Poster URL'ini Wikipedia'dan al
          final posterUrl = await _getPosterUrl(movie.title);
          final movieWithPoster = movieWithFavorite.copyWith(posterUrl: posterUrl);
          
          _filteredMovies.add(movieWithPoster);
        }
        
        _state = MovieLoadingState.loaded;
      } catch (e) {
        throw Exception('Film/dizi verisi parse edilemedi: ${e.toString()}');
      }
    } catch (e) {
      _state = MovieLoadingState.error;
      _errorMessage = 'Dizi/film aranırken bir hata oluştu: ${e.toString()}';
    }
    
    notifyListeners();
  }

  // Aramanın temizlenmesi
  void clearSearch() {
    _searchQuery = '';
    _filteredMovies.clear();
    notifyListeners();
  }

  // Favori dizi/filmleri yükle
  Future<void> loadFavorites() async {
    try {
      final List<String>? favoritesList = await _storageService.getStringList(AppConstants.cacheKeyMovieFavorites);
      
      if (favoritesList != null && favoritesList.isNotEmpty) {
        _favoriteMovies = favoritesList
            .map((json) => Movie.fromJson(jsonDecode(json)))
            .toList();
            
        // Mevcut filmlerin favori durumunu güncelle
        _updateMoviesFavoriteStatus();
      }
    } catch (e) {
      debugPrint('Favori dizi/filmler yüklenirken hata: ${e.toString()}');
    }
  }

  // Dizi/filmin favori durumunu değiştir
  Future<void> toggleFavorite(Movie movie) async {
    final updatedMovie = movie.copyWith(isFavorite: !movie.isFavorite);
    
    // Favorilere ekle veya çıkar
    if (updatedMovie.isFavorite) {
      if (!_favoriteMovies.contains(updatedMovie)) {
        _favoriteMovies.add(updatedMovie);
      }
    } else {
      _favoriteMovies.removeWhere((m) => m.id == updatedMovie.id);
    }
    
    // Mevcut film listesini güncelle
    final index = _movies.indexWhere((m) => m.id == updatedMovie.id);
    if (index != -1) {
      _movies[index] = updatedMovie;
    }
    
    // Filtrelenmiş listeyi güncelle
    final filteredIndex = _filteredMovies.indexWhere((m) => m.id == updatedMovie.id);
    if (filteredIndex != -1) {
      _filteredMovies[filteredIndex] = updatedMovie;
    }
    
    // Güncel favori filmi ayarla
    if (_currentMovie?.id == updatedMovie.id) {
      _currentMovie = updatedMovie;
    }
    
    // Değişiklikleri kaydet
    await _saveFavorites();
    
    notifyListeners();
  }

  // Favori dizi/filmleri kaydet
  Future<void> _saveFavorites() async {
    try {
      final List<String> favoritesList = _favoriteMovies
          .map((movie) => jsonEncode(movie.toJson()))
          .toList();
          
      await _storageService.setStringList(AppConstants.cacheKeyMovieFavorites, favoritesList);
    } catch (e) {
      debugPrint('Favori dizi/filmler kaydedilirken hata: ${e.toString()}');
    }
  }

  // Mevcut dizi/filmlerin favori durumunu güncelle
  void _updateMoviesFavoriteStatus() {
    for (int i = 0; i < _movies.length; i++) {
      final Movie movie = _movies[i];
      final bool isFavorite = _favoriteMovies.any((fav) => fav.id == movie.id);
      
      if (movie.isFavorite != isFavorite) {
        _movies[i] = movie.copyWith(isFavorite: isFavorite);
      }
    }
    
    for (int i = 0; i < _filteredMovies.length; i++) {
      final Movie movie = _filteredMovies[i];
      final bool isFavorite = _favoriteMovies.any((fav) => fav.id == movie.id);
      
      if (movie.isFavorite != isFavorite) {
        _filteredMovies[i] = movie.copyWith(isFavorite: isFavorite);
      }
    }
    
    if (_currentMovie != null) {
      final bool isFavorite = _favoriteMovies.any((fav) => fav.id == _currentMovie!.id);
      
      if (_currentMovie!.isFavorite != isFavorite) {
        _currentMovie = _currentMovie!.copyWith(isFavorite: isFavorite);
      }
    }
  }

  // Mevcut dizi/filmi ayarla
  void setCurrentMovie(Movie movie) {
    _currentMovie = movie;
    notifyListeners();
  }

  // Sayfaları ve durumu sıfırla
  void reset() {
    _movies.clear();
    _filteredMovies.clear();
    _page = 1;
    _hasMoreMovies = true;
    _state = MovieLoadingState.initial;
    _searchQuery = '';
    notifyListeners();
  }
  
  // Belirli tip ve türe göre dizi/film yükle
  Future<void> loadByFilter({String? type, String? genre}) async {
    _state = MovieLoadingState.loading;
    _page = 1;
    _hasMoreMovies = true;
    _movies.clear();
    notifyListeners();
    
    try {
      // Eğer filtre varsa, yapay zekadan bu filtrelere uygun filmleri iste
      String filterQuery = '';
      
      if (type != null) {
        filterQuery += type == 'movie' ? 'film ' : 'dizi ';
      }
      
      if (genre != null) {
        filterQuery += genre;
      }
      
      if (filterQuery.isNotEmpty) {
        await searchMovies(filterQuery, type: type, genre: genre);
      } else {
        await changeCategory(AppConstants.categoryMixed);
      }
    } catch (e) {
      _state = MovieLoadingState.error;
      _errorMessage = 'Filtreli dizi/filmler yüklenirken bir hata oluştu: ${e.toString()}';
      notifyListeners();
    }
  }
} 