import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/favorites_view_model.dart';
import '../components/article_card.dart';
import '../../viewmodels/article_view_model.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // Favorileri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavoritesViewModel>(context, listen: false).loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoriler'),
      ),
      body: Consumer<FavoritesViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!viewModel.hasFavorites) {
            return const Center(
              child: Text(
                'Favori makaleniz yok.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: viewModel.favorites.length,
            itemBuilder: (context, index) {
              final article = viewModel.favorites[index];
              
              return Dismissible(
                key: Key(article.title),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                onDismissed: (direction) {
                  viewModel.removeFromFavorites(article.title);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${article.title} favorilerden kaldırıldı')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                      article.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    leading: article.imageUrl.isNotEmpty && !article.imageUrl.startsWith('assets/')
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(article.imageUrl),
                        )
                      : const CircleAvatar(
                          child: Icon(Icons.article),
                        ),
                    onTap: () {
                      _showArticleDetails(context, article, viewModel);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  /// Makale detaylarını göster
  void _showArticleDetails(BuildContext context, article, FavoritesViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: ArticleCard(
            article: article,
            onFavoriteToggle: () {
              viewModel.removeFromFavorites(article.title);
              Navigator.pop(context);
            },
            onRefresh: () => Navigator.pop(context),
            onLoadSimilarArticle: () {
              // Önce modal'ı kapat
              Navigator.pop(context);
              
              // Ana sayfadaki ViewModel'e erişip benzer makale getir
              final articleViewModel = Provider.of<ArticleViewModel>(context, listen: false);
              
              // Yükleniyor bildirimi göster
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text('Benzer içerik aranıyor...'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(milliseconds: 2000),
                ),
              );
              
              // Benzer içerik yükle ve ana sayfaya dön
              articleViewModel.loadSimilarArticle().then((_) {
                // Ana sayfaya dön
                Navigator.pop(context);
                
                // Yeni içerik bildirimi göster
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Text('Benzer içerik bulundu, ana sayfaya dönülüyor...'),
                      ],
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              });
            },
          ),
        );
      },
    );
  }
} 