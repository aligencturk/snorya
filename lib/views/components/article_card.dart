import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/article.dart';
import '../../utils/constants.dart';

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
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Makale Başlığı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              article.title,
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Makale Görseli (varsa)
          if (article.imageUrl.isNotEmpty && !article.imageUrl.startsWith('assets/'))
            SizedBox(
              height: 200,
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Image.asset(
                  AppConstants.fallbackImageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Image.asset(
                AppConstants.fallbackImageUrl,
                fit: BoxFit.cover,
              ),
            ),
          
          // Makale Özeti
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Text(
                  article.summary,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            ),
          ),
          
          // Alt Butonlar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Favorilere Ekle/Çıkar Butonu
                IconButton(
                  icon: Icon(
                    article.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: article.isFavorite ? Colors.red : null,
                  ),
                  onPressed: onFavoriteToggle,
                  tooltip: article.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                ),
                
                // Yenile Butonu
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh,
                  tooltip: 'Yeni Makale Getir',
                ),
                
                // Paylaş Butonu
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => _shareArticle(context),
                  tooltip: 'Paylaş',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Makaleyi paylaş
  void _shareArticle(BuildContext context) {
    final String shareText = '${article.title}\n\n${article.summary}\n\nSnorya uygulamasından paylaşıldı.';
    Share.share(shareText);
  }
} 