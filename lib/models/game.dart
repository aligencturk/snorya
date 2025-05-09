class Game {
  final String title;
  final String content;
  final String summary;
  final String imageUrl;
  final String genre;
  final String platform;
  final bool isFavorite;
  final List<Map<String, dynamic>>? additionalImages; 
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? ratings; // Metacritic, IGN, Steam gibi puanlar
  final List<Map<String, dynamic>>? reviews; // Oyun değerlendirmeleri

  Game({
    required this.title,
    required this.content,
    required this.summary,
    required this.imageUrl,
    required this.genre,
    this.platform = '',
    this.isFavorite = false,
    this.additionalImages,
    this.metadata,
    this.ratings,
    this.reviews,
  });

  Game copyWith({
    String? title,
    String? content,
    String? summary,
    String? imageUrl,
    String? genre,
    String? platform,
    bool? isFavorite,
    List<Map<String, dynamic>>? additionalImages,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? ratings,
    List<Map<String, dynamic>>? reviews,
  }) {
    return Game(
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      genre: genre ?? this.genre,
      platform: platform ?? this.platform,
      isFavorite: isFavorite ?? this.isFavorite,
      additionalImages: additionalImages ?? this.additionalImages,
      metadata: metadata ?? this.metadata,
      ratings: ratings ?? this.ratings,
      reviews: reviews ?? this.reviews,
    );
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    // Reviews alanı için güvenli dönüşüm
    List<Map<String, dynamic>>? reviewsList;
    if (json['reviews'] != null) {
      try {
        reviewsList = (json['reviews'] as List)
            .map((item) => item is Map 
                ? Map<String, dynamic>.from(item) 
                : <String, dynamic>{})
            .toList();
      } catch (e) {
        print('Reviews dönüştürme hatası: $e');
        reviewsList = null;
      }
    }
    
    return Game(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      summary: json['summary'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      genre: json['genre'] ?? 'Genel',
      platform: json['platform'] ?? '',
      isFavorite: json['isFavorite'] ?? false,
      additionalImages: json['additionalImages'] != null 
          ? List<Map<String, dynamic>>.from(json['additionalImages'])
          : null,
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      ratings: json['ratings'] != null 
          ? Map<String, dynamic>.from(json['ratings'])
          : null,
      reviews: reviewsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'imageUrl': imageUrl,
      'genre': genre,
      'platform': platform,
      'isFavorite': isFavorite,
      'additionalImages': additionalImages,
      'metadata': metadata,
      'ratings': ratings,
      'reviews': reviews,
    };
  }
} 