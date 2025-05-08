import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/storage_service.dart';

class FavoritesViewModel extends ChangeNotifier {
  final StorageService _storageService;
  
  List<Article> _favorites = [];
  bool _isLoading = false;
  
  FavoritesViewModel({
    required StorageService storageService,
  }) : _storageService = storageService;
  
  // Getters
  List<Article> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool get hasFavorites => _favorites.isNotEmpty;
  
  /// Favorileri yükle
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _favorites = await _storageService.getFavorites();
    } catch (e) {
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Favorilerden kaldır
  Future<void> removeFromFavorites(String title) async {
    try {
      await _storageService.removeFromFavorites(title);
      _favorites.removeWhere((article) => article.title == title);
      notifyListeners();
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }
} 