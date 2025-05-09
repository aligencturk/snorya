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
    );
  }

  factory Game.fromJson(Map<String, dynamic> json) {
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
    };
  }
} 