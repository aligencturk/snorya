import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/article.dart';
import '../../utils/constants.dart';
import 'dart:math';

class ArticleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka plan görseli
        _buildBackgroundImage(context),
        
        // Karartma katmanı (daha koyu arka plan için)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.1, 0.4, 0.8],
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        
        // İçerik
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Üst boşluk
                const SizedBox(height: 20),
                
                // Kategori etiketi
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(article.category),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(article.category),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          article.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Üst boşluk
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  article.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 5,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 20),
                
                // İçerik Alanı
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          article.summary,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.6,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Alt boşluk ve butonlar
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: article.isFavorite ? Icons.favorite : Icons.favorite_outline,
                        tooltip: article.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                        color: article.isFavorite ? Colors.redAccent : Colors.white,
                        onPressed: onFavoriteToggle,
                      ),
                      const SizedBox(width: 32),
                      _buildActionButton(
                        icon: Icons.refresh,
                        tooltip: 'Yeni Makale',
                        color: Colors.white,
                        onPressed: onRefresh,
                      ),
                      const SizedBox(width: 32),
                      _buildActionButton(
                        icon: Icons.share_outlined,
                        tooltip: 'Paylaş',
                        color: Colors.white,
                        onPressed: () => _shareArticle(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  /// Arka plan görseli oluşturur
  Widget _buildBackgroundImage(BuildContext context) {
    // Wikipedia'dan alınan görselin URL'si geçerliyse kullan
    if (article.imageUrl.isNotEmpty && !article.imageUrl.startsWith('assets/') && _isValidImageUrl(article.imageUrl)) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.2),
          BlendMode.darken,
        ),
        child: CachedNetworkImage(
          imageUrl: article.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.black12,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => _buildFallbackImage(),
        ),
      );
    } else {
      return _buildFallbackImage();
    }
  }
  
  /// Yedek görsel oluşturur
  Widget _buildFallbackImage() {
    // Sabit yerleşimci görseller (önceden yüklenmiş stock görseller)
    final List<String> categoryImages = [
      'https://i.ibb.co/PTDQJxW/science.jpg',      // Bilim için görsel
      'https://i.ibb.co/hC6ZSVy/history.jpg',      // Tarih için görsel
      'https://i.ibb.co/ZGkJQPG/technology.jpg',   // Teknoloji için görsel
      'https://i.ibb.co/F5KySfN/culture.jpg',      // Kültür için görsel
      'https://i.ibb.co/PrpyzP8/mixed.jpg',        // Karışık için görsel
    ];
    
    // Kategori bazlı görsel seçimi
    String imageUrl;
    switch (article.category) {
      case AppConstants.categoryScience:
        imageUrl = categoryImages[0];
        break;
      case AppConstants.categoryHistory:
        imageUrl = categoryImages[1];
        break;
      case AppConstants.categoryTechnology:
        imageUrl = categoryImages[2];
        break;
      case AppConstants.categoryCulture:
        imageUrl = categoryImages[3];
        break;
      default:
        // Rastgele bir görsel seç (makale başlığına göre sabit bir seçim)
        final int seed = article.title.length;
        final int index = seed % categoryImages.length;
        imageUrl = categoryImages[index];
    }
    
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.3),
        BlendMode.darken,
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCategoryColor(article.category).withOpacity(0.7),
                _getCategoryColor(article.category).withOpacity(0.3),
              ],
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getCategoryColor(article.category).withOpacity(0.7),
                _getCategoryColor(article.category).withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Görsel URL'sinin geçerli olup olmadığını kontrol eder
  bool _isValidImageUrl(String url) {
    return url.contains('.jpg') || 
           url.contains('.jpeg') || 
           url.contains('.png') || 
           url.contains('.webp') || 
           url.contains('.gif');
  }
  
  /// Eylem butonunu oluşturur
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Kategori için ikon seçer
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case AppConstants.categoryScience:
        return Icons.science;
      case AppConstants.categoryHistory:
        return Icons.history_edu;
      case AppConstants.categoryTechnology:
        return Icons.computer;
      case AppConstants.categoryCulture:
        return Icons.theaters;
      case AppConstants.categoryMixed:
        return Icons.dashboard;
      default:
        return Icons.category;
    }
  }
  
  /// Kategori için renk seçer
  Color _getCategoryColor(String category) {
    switch (category) {
      case AppConstants.categoryScience:
        return Colors.blue;
      case AppConstants.categoryHistory:
        return Colors.amber.shade800;
      case AppConstants.categoryTechnology:
        return Colors.teal;
      case AppConstants.categoryCulture:
        return Colors.purple;
      case AppConstants.categoryMixed:
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
  
  /// Makaleyi paylaş
  void _shareArticle(BuildContext context) {
    final String shareText = '${article.title}\n\n${article.summary}\n\nSnorya uygulamasından paylaşıldı.';
    Share.share(shareText);
  }
} 