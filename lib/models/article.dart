class Article {
  final String title;
  final String content;
  final String summary;
  final String imageUrl;
  final String category;
  final bool isFavorite;
  final String source; // Veri kaynağı: 'wikipedia', 'wikispecies', 'commons', vb.
  final List<Map<String, dynamic>>? additionalImages; // Commons'tan ek görseller
  final Map<String, dynamic>? metadata; // Ek meta veriler

  Article({
    required this.title,
    required this.content,
    required this.summary,
    required this.imageUrl,
    required this.category,
    this.isFavorite = false,
    this.source = 'wikipedia',
    this.additionalImages,
    this.metadata,
  });

  Article copyWith({
    String? title,
    String? content,
    String? summary,
    String? imageUrl,
    String? category,
    bool? isFavorite,
    String? source,
    List<Map<String, dynamic>>? additionalImages,
    Map<String, dynamic>? metadata,
  }) {
    return Article(
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source ?? this.source,
      additionalImages: additionalImages ?? this.additionalImages,
      metadata: metadata ?? this.metadata,
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
      source: json['source'] ?? 'wikipedia',
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
      'category': category,
      'isFavorite': isFavorite,
      'source': source,
      'additionalImages': additionalImages,
      'metadata': metadata,
    };
  }
  
  // WikiSpecies'dan gelen veri için özel oluşturucu
  factory Article.fromWikiSpecies(Map<String, dynamic> data) {
    return Article(
      title: data['title'] ?? 'Tür Bilgisi',
      content: data['content'] ?? '',
      summary: data['content'] != null && data['content'].length > 200 
          ? data['content'].substring(0, 200) + '...' 
          : data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: 'Bilim',
      source: 'wikispecies',
      metadata: {
        'originalSource': 'WikiSpecies',
        'url': 'https://species.wikimedia.org/wiki/${Uri.encodeComponent(data['title'] ?? '')}',
      },
    );
  }
  
  // Commons'tan gelen veri için özel oluşturucu
  factory Article.fromCommons(String topic, List<Map<String, dynamic>> images) {
    String content = '$topic hakkında Wikimedia Commons görüntüleri';
    
    if (images.isNotEmpty) {
      content += '\n\nGörüntü detayları:\n';
      for (var image in images.take(5)) {
        content += '\n- ${image['title']}\n';
        if (image['description'].isNotEmpty) {
          content += '   Açıklama: ${image['description']}\n';
        }
        if (image['author'].isNotEmpty) {
          content += '   Yazar: ${image['author']}\n';
        }
      }
    }
    
    return Article(
      title: '$topic - Commons Görüntüleri',
      content: content,
      summary: '$topic ile ilgili Wikimedia Commons\'tan görüntüler.',
      imageUrl: images.isNotEmpty ? images.first['url'] : '',
      category: 'Karışık',
      source: 'commons',
      additionalImages: images,
      metadata: {
        'originalSource': 'Wikimedia Commons',
        'url': 'https://commons.wikimedia.org/wiki/Category:${Uri.encodeComponent(topic)}',
      },
    );
  }
  
  // Gisburn Forest veya özel içerik için oluşturucu
  factory Article.fromSpecialContent(Map<String, dynamic> data) {
    return Article(
      title: data['title'] ?? 'Özel İçerik',
      content: data['content'] ?? '',
      summary: data['content'] != null && data['content'].length > 200 
          ? data['content'].substring(0, 200) + '...' 
          : data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: 'Özel',
      source: 'special',
      additionalImages: data['commonsImages'],
      metadata: {
        'originalSource': data['source'] ?? 'Özel',
        'url': data['url'] ?? '',
      },
    );
  }
} 