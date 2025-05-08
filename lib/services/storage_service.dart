import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';
import '../utils/constants.dart';

class StorageService {
  /// Favorilere bir makale ekler
  Future<void> addToFavorites(Article article) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(AppConstants.cacheKeyFavorites);
      
      List<Article> favorites = [];
      
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        favorites = decoded.map((item) => Article.fromJson(item)).toList();
      }
      
      // Makale favorilerde yoksa ekle
      if (!favorites.any((a) => a.title == article.title)) {
        favorites.add(article.copyWith(isFavorite: true));
        await prefs.setString(
          AppConstants.cacheKeyFavorites, 
          json.encode(favorites.map((a) => a.toJson()).toList())
        );
      }
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  /// Favorilerden bir makaleyi kaldırır
  Future<void> removeFromFavorites(String title) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(AppConstants.cacheKeyFavorites);
      
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        final List<Article> favorites = decoded.map((item) => Article.fromJson(item)).toList();
        
        favorites.removeWhere((article) => article.title == title);
        
        await prefs.setString(
          AppConstants.cacheKeyFavorites, 
          json.encode(favorites.map((a) => a.toJson()).toList())
        );
      }
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  /// Tüm favori makaleleri getirir
  Future<List<Article>> getFavorites() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(AppConstants.cacheKeyFavorites);
      
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        return decoded.map((item) => Article.fromJson(item)).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Bir makalenin favori olup olmadığını kontrol eder
  Future<bool> isFavorite(String title) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(AppConstants.cacheKeyFavorites);
      
      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        final List<Article> favorites = decoded.map((item) => Article.fromJson(item)).toList();
        
        return favorites.any((article) => article.title == title);
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Son seçilen kategoriyi kaydeder
  Future<void> saveLastCategory(String category) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.cacheKeyLastCategory, category);
    } catch (e) {
      // Hata durumunda sessizce geç
    }
  }

  /// Son seçilen kategoriyi getirir
  Future<String> getLastCategory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.cacheKeyLastCategory) ?? AppConstants.categoryMixed;
    } catch (e) {
      return AppConstants.categoryMixed;
    }
  }

  /// Son seçilen özel konuyu kaydet
  Future<void> saveLastCustomTopic(String topic) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cacheKeyLastCustomTopic, topic);
  }
  
  /// Son seçilen özel konuyu getir
  Future<String> getLastCustomTopic() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.cacheKeyLastCustomTopic) ?? '';
  }
  
  /// Özel konuları kaydet
  Future<void> saveCustomTopics(List<String> topics) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.cacheKeyCustomTopics, topics);
  }
  
  /// Özel konuları getir
  Future<List<String>> getCustomTopics() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(AppConstants.cacheKeyCustomTopics) ?? [];
  }
  
  /// Özel konu ekle
  Future<void> addCustomTopic(String topic) async {
    final existingTopics = await getCustomTopics();
    if (!existingTopics.contains(topic)) {
      existingTopics.add(topic);
      await saveCustomTopics(existingTopics);
    }
  }
  
  /// Özel konuyu kaldır
  Future<void> removeCustomTopic(String topic) async {
    final existingTopics = await getCustomTopics();
    existingTopics.remove(topic);
    await saveCustomTopics(existingTopics);
    
    // Eğer son seçilen konu bu ise, yeni bir tane seç
    final lastTopic = await getLastCustomTopic();
    if (lastTopic == topic && existingTopics.isNotEmpty) {
      await saveLastCustomTopic(existingTopics.first);
    }
  }
} 