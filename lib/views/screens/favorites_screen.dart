import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/favorites_view_model.dart';
import '../components/article_card.dart';

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
          ),
        );
      },
    );
  }
} 