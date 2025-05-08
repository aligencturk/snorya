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

  // Favori makaleleri kaydet
  Future<void> saveFavorites(List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = articles.map((article) => jsonEncode(article.toJson())).toList();
      await prefs.setStringList(AppConstants.cacheKeyFavorites, jsonList);
    } catch (e) {
      print('Favoriler kaydedilirken hata oluştu: $e');
    }
  }
  
  // Favori makaleleri yükle
  Future<List<Article>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(AppConstants.cacheKeyFavorites);
      
      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }
      
      return jsonList
          .map((jsonStr) => Article.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      print('Favoriler yüklenirken hata oluştu: $e');
      return [];
    }
  }
}
  // Son seçilen kategoriyi kaydet
  Future<void> saveLastCategory(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.cacheKeyLastCategory, category);
    } catch (e) {
      print('Kategori kaydedilirken hata oluştu: $e');
    }
  }
  
  // Son seçilen kategoriyi yükle
  Future<String> loadLastCategory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.cacheKeyLastCategory) ?? AppConstants.categoryMixed;
    } catch (e) {
      print('Kategori yüklenirken hata oluştu: $e');
      return AppConstants.categoryMixed;
    }
  }
  
  // Özel konuları kaydet
  Future<void> saveCustomTopics(List<String> topics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(AppConstants.cacheKeyCustomTopics, topics);
    } catch (e) {
      print('Özel konular kaydedilirken hata oluştu: $e');
    }
  }
  
  // Özel konuları yükle
  Future<List<String>> loadCustomTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(AppConstants.cacheKeyCustomTopics) ?? [];
    } catch (e) {
      print('Özel konular yüklenirken hata oluştu: $e');
      return [];
    }
  }
  
  // Son seçilen özel konuyu kaydet
  Future<void> saveLastCustomTopic(String topic) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.cacheKeyLastCustomTopic, topic);
    } catch (e) {
      print('Özel konu kaydedilirken hata oluştu: $e');
    }
  }
  
  // Son seçilen özel konuyu yükle
  Future<String> loadLastCustomTopic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.cacheKeyLastCustomTopic) ?? '';
    } catch (e) {
      print('Özel konu yüklenirken hata oluştu: $e');
      return '';
    }
  }
  
  // Genel bir string değeri kaydet
  Future<void> setString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      print('String değeri kaydedilirken hata oluştu: $e');
    }
  }
  
  // Genel bir string değeri yükle
  Future<String> getString(String key, {String defaultValue = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key) ?? defaultValue;
    } catch (e) {
      print('String değeri yüklenirken hata oluştu: $e');
      return defaultValue;
    }
  }
  
  // Genel bir string listesi kaydet
  Future<void> setStringList(String key, List<String> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, values);
    } catch (e) {
      print('String listesi kaydedilirken hata oluştu: $e');
    }
  }
  
  // Genel bir string listesi yükle
  Future<List<String>> getStringList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(key) ?? [];
    } catch (e) {
      print('String listesi yüklenirken hata oluştu: $e');
      return [];
    }
  }
  
  // Makaleleri kaydet (genel amaçlı)
  Future<void> saveArticles(String key, List<Article> articles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = articles.map((article) => jsonEncode(article.toJson())).toList();
      await prefs.setStringList(key, jsonList);
    } catch (e) {
      print('Makaleler kaydedilirken hata oluştu: $e');
    }
  }
  
  // Makaleleri yükle (genel amaçlı)
  Future<List<Article>> getArticles(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(key);
      
      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }
      
      return jsonList
          .map((jsonStr) => Article.fromJson(jsonDecode(jsonStr)))
          .toList();
    } catch (e) {
      print('Makaleler yüklenirken hata oluştu: $e');
      return [];
    }
  }
