class Article {
  final String title;
  final String content;
  final String summary;
  final String imageUrl;
  final String category;
  final bool isFavorite;

  Article({
    required this.title,
    required this.content,
    required this.summary,
    required this.imageUrl,
    required this.category,
    this.isFavorite = false,
  });

  Article copyWith({
    String? title,
    String? content,
    String? summary,
    String? imageUrl,
    String? category,
    bool? isFavorite,
  }) {
    return Article(
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      summary: json['summary'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'Karışık',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'imageUrl': imageUrl,
      'category': category,
      'isFavorite': isFavorite,
    };
  }
} 