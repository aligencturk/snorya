import 'package:flutter/material.dart';
import '../../models/article.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onRefresh;
  
  const ArticleCard({
    super.key,
    required this.article,
    required this.onFavoriteToggle,
    required this.onRefresh,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.article.title;
    final String summary = widget.article.summary;
    final String content = widget.article.content;
    final String imageUrl = widget.article.imageUrl;
    final bool isFavorite = widget.article.isFavorite;
    
    return Container(
          decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: imageUrl.isNotEmpty
              ? NetworkImage(imageUrl) as ImageProvider
              : const AssetImage('assets/images/placeholder.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
              children: [
          // İlk sayfa - Özet
          _buildSummaryPage(title, summary, isFavorite),
          
          // İkinci sayfa - Tam içerik
          _buildFullContentPage(title, content),
        ],
      ),
    );
  }
  
  // Özet sayfası
  Widget _buildSummaryPage(String title, String summary, bool isFavorite) {
    return Stack(
      children: [
        // İçerik alanı
        Column(
          children: [
            const Spacer(flex: 1),
            // Başlık ve özet
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                    // Makale başlığı
                        Text(
                      title,
                          style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                            color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 16),
                    // Makale özeti
                Text(
                      summary,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                            color: Colors.black26,
                        blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tam içeriği göster butonu
                    ElevatedButton.icon(
                      onPressed: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.article),
                      label: const Text('Tam İçeriği Göster'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        // Sağa kaydırma indikatörü
        Positioned(
          right: 16,
          top: 0,
          bottom: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_arrow_right,
                    color: Colors.white,
                    size: 24,
                  ),
                  Text(
                    'Kaydır',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
                      ),
                    ),
                  ),
                ),
                
        // Üst butonlar
        Positioned(
          top: 36,
          right: 20,
                  child: Row(
                    children: [
              // Yenile butonu
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: widget.onRefresh,
                        tooltip: 'Yeni Makale',
                ),
              ),
              const SizedBox(width: 12),
              // Favori butonu
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorite ? Colors.yellow : Colors.white,
                  ),
                  onPressed: widget.onFavoriteToggle,
                  tooltip: isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                  ),
                ),
              ],
          ),
        ),
      ],
    );
  }
  
  // Tam içerik sayfası
  Widget _buildFullContentPage(String title, String content) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Üst bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.article.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: widget.article.isFavorite ? Colors.yellow : Colors.white,
                    ),
                    onPressed: widget.onFavoriteToggle,
                  ),
              ],
            ),
          ),
            
            // Metin scrollable alanı
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  content,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                  textAlign: TextAlign.justify,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 