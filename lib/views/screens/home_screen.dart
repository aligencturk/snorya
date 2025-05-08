import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/article_view_model.dart';
import '../components/article_card.dart';
import '../components/category_selector.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    // ViewModel'i başlat ve ilk makaleyi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleViewModel>(context, listen: false).initialize();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snorya'),
        actions: [
          // Favoriler butonu
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () => _navigateToFavorites(context),
            tooltip: 'Favoriler',
          ),
        ],
      ),
      body: Column(
        children: [
          // Kategori seçici
          Consumer<ArticleViewModel>(
            builder: (context, viewModel, child) {
              return CategorySelector(
                selectedCategory: viewModel.selectedCategory,
                onCategorySelected: (category) {
                  viewModel.changeCategory(category);
                },
              );
            },
          ),
          
          // Makale kartları
          Expanded(
            child: Consumer<ArticleViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.state == ArticleLoadingState.initial) {
                  return const Center(child: Text('Makaleler yükleniyor...'));
                }
                
                if (viewModel.state == ArticleLoadingState.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(viewModel.errorMessage),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => viewModel.loadNextArticle(),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }
                
                // Makaleler yükleniyor
                if (viewModel.state == ArticleLoadingState.loading && viewModel.articles.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Makaleler yüklendi
                return PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: viewModel.articles.length + (viewModel.state == ArticleLoadingState.loading ? 1 : 0),
                  onPageChanged: (index) {
                    // Son sayfaya geldiğinde yeni makale yükle
                    if (index == viewModel.articles.length - 1 && 
                        viewModel.state != ArticleLoadingState.loading) {
                      viewModel.loadNextArticle();
                    }
                    
                    // Görünen makaleyi güncelle
                    if (index < viewModel.articles.length) {
                      viewModel.goToArticle(index);
                    }
                  },
                  itemBuilder: (context, index) {
                    // Yükleme göstergesi
                    if (index == viewModel.articles.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    // Makale kartı
                    final article = viewModel.articles[index];
                    return ArticleCard(
                      article: article,
                      onFavoriteToggle: () => viewModel.toggleFavorite(),
                      onRefresh: () {
                        viewModel.loadNextArticle();
                        // Yeni makaleye geç
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) {
                            _pageController.animateToPage(
                              viewModel.articles.length - 1, 
                              duration: const Duration(milliseconds: 300), 
                              curve: Curves.easeInOut,
                            );
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  /// Favoriler ekranına git
  void _navigateToFavorites(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  }
} 