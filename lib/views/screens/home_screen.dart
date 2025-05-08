import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/article_view_model.dart';
import '../../utils/constants.dart';
import '../components/article_card.dart';
import '../components/category_selector.dart';
import 'favorites_screen.dart';
import 'custom_topic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    
    // Tam ekran modu
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Animasyon kontrolcüsü
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    _animationController.forward();
    
    // ViewModel'i başlat ve ilk makaleyi yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ArticleViewModel>(context, listen: false).initialize();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Snorya',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 10.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          // Favoriler butonu
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.bookmark, color: Colors.white),
              onPressed: () => _navigateToFavorites(context),
              tooltip: 'Favoriler',
            ),
          ),
        ],
      ),
      body: Consumer<ArticleViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == ArticleLoadingState.initial || 
              (viewModel.state == ArticleLoadingState.loading && viewModel.articles.isEmpty)) {
            return _buildLoadingPlaceholder('Makaleler yükleniyor...');
          }
          
          if (viewModel.state == ArticleLoadingState.error && viewModel.articles.isEmpty) {
            return _buildErrorWidget(viewModel);
          }
          
          // İçerik yüklendiyse TikTok tarzı sonsuz scroll göster
          return Stack(
            children: [
              // Makale sayfaları
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  // Kaydırma durumunu güncelle
                  _isScrolling = true;
                  
                  // AnimationController'ı yeniden başlat
                  _animationController.reset();
                  _animationController.forward();
                  
                  // ViewModel'e bildir ve gerekliyse yeni içerik yüklemesini sağla
                  viewModel.checkAndLoadMoreArticles(index);
                  
                  // Kısa bir süre sonra kaydırma durumunu kapat
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) {
                      setState(() {
                        _isScrolling = false;
                      });
                    }
                  });
                },
                itemCount: viewModel.articles.length,
                itemBuilder: (context, index) {
                  // Makale kartı
                  final article = viewModel.articles[index];
                  
                  // Sonsuz kaydırma kontrolü
                  if (index == viewModel.articles.length - 1) {
                    // Son elemana gelince, otomatik olarak daha fazla içerik yükle
                    Future.microtask(() {
                      viewModel.checkAndLoadMoreArticles(index);
                    });
                  }
                  
                  return FadeTransition(
                    opacity: _animation,
                    child: ArticleCard(
                      article: article,
                      onFavoriteToggle: () => viewModel.toggleFavorite(),
                      onRefresh: () => _handleRefresh(viewModel),
                    ),
                  );
                },
              ),
              
              // Üst kategori seçici
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      CategorySelector(
                        selectedCategory: viewModel.selectedCategory,
                        onCategorySelected: (category) {
                          viewModel.changeCategory(category);
                          _animationController.reset();
                          _animationController.forward();
                        },
                      ),
                      
                      // Özel kategori seçiliyse arama çubuğu göster
                      if (viewModel.selectedCategory == AppConstants.categoryCustom)
                        _buildSearchBar(viewModel),
                    ],
                  ),
                ),
              ),
              
              // Yükleme göstergesi (altta)
              if (viewModel.isLoadingMore)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Yeni makaleler yükleniyor',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Hafif kaydırma hint'i (ilk açıldığında)
              if (!_isScrolling && viewModel.currentIndex == 0)
                Positioned(
                  bottom: 80,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: 0.8,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
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
            ],
          );
        },
      ),
    );
  }
  
  /// Hata ekranı widgetı
  Widget _buildErrorWidget(ArticleViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade700,
            Colors.indigo.shade900,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 60,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.errorMessage,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              onPressed: () => viewModel.initialize(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                elevation: 8,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Yükleme ekranı
  Widget _buildLoadingPlaceholder(String message) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade700,
            Colors.indigo.shade900,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Yenileme işlemini ele al
  void _handleRefresh(ArticleViewModel viewModel) {
    viewModel.refreshArticle();
    
    // Yeni makaleye geç
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _pageController.animateToPage(
          viewModel.articles.length - 1, 
          duration: const Duration(milliseconds: 500), 
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
  
  /// Favoriler ekranına git
  void _navigateToFavorites(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  }
  
  /// Özel kategori için arama çubuğu
  Widget _buildSearchBar(ArticleViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Özel konu ara...',
                border: InputBorder.none,
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                hintStyle: TextStyle(color: Colors.grey.shade600),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  viewModel.addCustomTopic(value.trim());
                  viewModel.changeCustomTopic(value.trim());
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomTopicScreen()),
              );
            },
            tooltip: 'Konuları Yönet',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          ),
        ],
      ),
    );
  }
} 