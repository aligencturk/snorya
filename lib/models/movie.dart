import 'package:flutter/foundation.dart';

class Movie {
  final String id;
  final String title;
  final String overview;
  final String posterUrl;
  final String type; // 'movie' veya 'tv'
  final List<String> genres;
  final String director;
  final String releaseDate;
  final double rating;
  bool isFavorite;

  Movie({
    required this.id,
    required this.title,
    required this.overview, 
    required this.posterUrl,
    required this.type,
    required this.genres,
    required this.director,
    required this.releaseDate,
    required this.rating,
    this.isFavorite = false,
  });

  // JSON verisinden Movie nesnesi oluşturma
  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      type: json['type'] ?? 'movie',
      genres: List<String>.from(json['genres'] ?? []),
      director: json['director'] ?? '',
      releaseDate: json['releaseDate'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Movie nesnesini JSON verisine dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'posterUrl': posterUrl,
      'type': type,
      'genres': genres,
      'director': director,
      'releaseDate': releaseDate,
      'rating': rating,
      'isFavorite': isFavorite,
    };
  }

  // Favori durumunu değiştiren kopyasını döndüren metot
  Movie copyWith({
    String? id,
    String? title,
    String? overview,
    String? posterUrl,
    String? type,
    List<String>? genres,
    String? director,
    String? releaseDate,
    double? rating,
    bool? isFavorite,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      type: type ?? this.type,
      genres: genres ?? this.genres,
      director: director ?? this.director,
      releaseDate: releaseDate ?? this.releaseDate,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Movie && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 