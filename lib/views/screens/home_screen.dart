import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/article_view_model.dart';
import '../../utils/constants.dart';
import '../components/article_card.dart';
import 'favorites_screen.dart';
import 'custom_topic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(
    viewportFraction: 1.0, // Tam ekran gösterim
    keepPage: true, // Sayfa durumunu koru
  );
  late AnimationController _animationController;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingSimilarContent = false; // Benzer içerik yükleme durumu

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
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            tooltip: 'Menü',
          ),
        ),
        title: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Consumer<ArticleViewModel>(
                builder: (context, viewModel, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      if (viewModel.selectedCategory != AppConstants.categoryMixed)
                        Padding(
                          padding: const EdgeInsets.only(left: 28, top: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getCategoryIcon(viewModel.selectedCategory),
                                color: Colors.white,
                                size: 12,
                                shadows: [
                                  Shadow(
                                    color: Colors.black45,
                                    blurRadius: 8.0,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                viewModel.selectedCategory,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8.0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                }
              ),
            );
          },
        ),
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
          return Container(
            // Arka plan rengi siyah olacak, beyaz flash önlenir
            color: Colors.black,
            child: Stack(
              children: [
                // Makale sayfaları
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  // Sayfa geçişini yumuşatmak için physics ekleyelim
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) {
                    // AnimationController'ı yeniden başlat
                    _animationController.reset();
                    _animationController.forward();
                    
                    // ViewModel'e bildir ve gerekliyse yeni içerik yüklemesini sağla
                    viewModel.checkAndLoadMoreArticles(index);
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
                        onFavoriteToggle: () {
                          // Favori durumunu değiştir
                          viewModel.toggleFavorite();
                          
                          // Kullanıcıya görsel geri bildirim
                          final message = article.isFavorite ? 'Favorilerden kaldırıldı' : 'Favorilere eklendi';
                          final icon = article.isFavorite ? Icons.bookmark_remove : Icons.bookmark_add;
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(icon, color: Colors.amber),
                                  const SizedBox(width: 12),
                                  Text(message),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        },
                        onNavigateToFavorites: () {
                          // Favoriler sayfasına git
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FavoritesScreen(),
                            ),
                          );
                        },
                        onRefresh: () {
                          // Yeni bir makale yükle
                          viewModel.refreshArticle();
                        },
                        onVerticalScroll: () {
                          // Bir sonraki makaleye kaydır
                          if (_pageController.page!.toInt() < viewModel.articles.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuint,
                            );
                          }
                        },
                        onSwipeRight: () {
                          // Sağa kaydırma ile tam içeriğe geçiş
                          // Bu callback ArticleCard içinde tam sayfa geçişi için kullanılacak
                        },
                        onLoadSimilarArticle: () {
                          if (_isLoadingSimilarContent) return; // Yükleme devam ediyorsa çıkış yap
                          
                          setState(() {
                            _isLoadingSimilarContent = true; // Yükleme durumunu güncelle
                          });
                          
                          // Benzer içerik yükleniyor bildirimi göster
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
                          
                          // Benzer içerik yükle
                          viewModel.loadSimilarArticle().then((_) {
                            if (viewModel.articles.isNotEmpty) {
                              // Başarılı bildirimi göster
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 12),
                                      Text('Benzer içerik bulundu!'),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(milliseconds: 1500),
                                ),
                              );
                              
                              // Animasyon için bir geçiş efekti ekleyelim
                              // Önce mevcut animasyonu sıfırla
                              _animationController.reset();
                              
                              // Sayfa geçişi - yüksek öncelikli animasyon kuyruğu kullanarak
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _pageController.animateToPage(
                                  viewModel.articles.length - 1,
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.fastLinearToSlowEaseIn, // Özel eğri - yumuşak geçiş
                                ).then((_) {
                                  // Sayfa geçişi tamamlandıktan sonra içerik animasyonunu başlat
                                  _animationController.forward();
                                  
                                  // Yükleme durumunu güncelle
                                  setState(() {
                                    _isLoadingSimilarContent = false;
                                  });
                                });
                              });
                            } else {
                              // Hata durumunda yükleme durumunu güncelle
                              setState(() {
                                _isLoadingSimilarContent = false;
                              });
                            }
                          }).catchError((error) {
                            // Hata durumunda yükleme durumunu güncelle
                            setState(() {
                              _isLoadingSimilarContent = false;
                            });
                            
                            // Hata bildirimi göster
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Benzer içerik getirilirken hata oluştu'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red,
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
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
  
  /// Favoriler ekranına git
  void _navigateToFavorites(BuildContext context) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const FavoritesScreen()),
    );
  }
  
  /// Drawer widget
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Consumer<ArticleViewModel>(
        builder: (context, viewModel, child) {
          return Container(
            color: Colors.blue.shade900,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık - Sabit kalacak
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Snorya',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: Colors.white24),
                  
                  // İçerik - Kaydırılabilir yapıldı
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Kategoriler başlığı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Kategoriler',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Kategori listesi
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryMixed, 
                            Icons.shuffle, 
                            viewModel.selectedCategory == AppConstants.categoryMixed,
                            viewModel
                          ),
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryScience, 
                            Icons.science, 
                            viewModel.selectedCategory == AppConstants.categoryScience,
                            viewModel
                          ),
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryHistory, 
                            Icons.history_edu, 
                            viewModel.selectedCategory == AppConstants.categoryHistory,
                            viewModel
                          ),
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryTechnology, 
                            Icons.computer, 
                            viewModel.selectedCategory == AppConstants.categoryTechnology,
                            viewModel
                          ),
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryCulture, 
                            Icons.theater_comedy, 
                            viewModel.selectedCategory == AppConstants.categoryCulture,
                            viewModel
                          ),
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryGames, 
                            Icons.sports_esports, 
                            viewModel.selectedCategory == AppConstants.categoryGames,
                            viewModel
                          ),
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryMoviesTv, 
                            Icons.movie, 
                            viewModel.selectedCategory == AppConstants.categoryMoviesTv,
                            viewModel
                          ),
                          _buildCategoryTile(
                            context, 
                            AppConstants.categoryCustom, 
                            Icons.topic, 
                            viewModel.selectedCategory == AppConstants.categoryCustom,
                            viewModel
                          ),
                          Divider(color: Colors.white24),
                          // Favoriler kısmı
                          ListTile(
                            leading: Icon(Icons.bookmark, color: Colors.amber),
                            title: Text(
                              'Favoriler',
                              style: TextStyle(color: Colors.white),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToFavorites(context);
                            },
                          ),
                          
                          // Telif hakkı - Scroll edilebilir alanda olmalı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              '© ${DateTime.now().year} Snorya',
                              style: TextStyle(color: Colors.white60),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Kategori liste öğesi
  Widget _buildCategoryTile(BuildContext context, String category, IconData icon, bool isSelected, ArticleViewModel viewModel) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white70,
      ),
      title: Text(
        category,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.shade700,
      onTap: () {
        // Drawer'ı kapat
        Navigator.pop(context);
        
        // Oyun kategorisi için özel işleme
        if (category == AppConstants.categoryGames) {
          // Sadece normal kategori değişimi yap
          viewModel.changeCategory(category);
          _animationController.reset();
          _animationController.forward();
        }
        // Dizi/Film kategorisi için özel işleme
        else if (category == AppConstants.categoryMoviesTv) {
          // Sadece normal kategori değişimi yap
          viewModel.changeCategory(category);
          _animationController.reset();
          _animationController.forward();
        }
        // Eğer özel kategoriyse ve seçili değilse, önce değiştir
        else if (category == AppConstants.categoryCustom && !isSelected) {
          viewModel.changeCategory(category);
          Future.delayed(Duration(milliseconds: 300), () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomTopicScreen()),
            );
          });
        } 
        // Eğer özel kategori seçiliyse ve zaten seçiliyse, topic ekranına git
        else if (category == AppConstants.categoryCustom && isSelected) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomTopicScreen()),
          );
        }
        // Diğer kategoriler için normal işleme
        else {
          viewModel.changeCategory(category);
          _animationController.reset();
          _animationController.forward();
        }
      },
    );
  }

  // Kategori ikonunu belirle
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case AppConstants.categoryScience:
        return Icons.science;
      case AppConstants.categoryHistory:
        return Icons.history_edu;
      case AppConstants.categoryTechnology:
        return Icons.computer;
      case AppConstants.categoryCulture:
        return Icons.theater_comedy;
      case AppConstants.categoryGames:
        return Icons.sports_esports;
      case AppConstants.categoryMoviesTv:
        return Icons.movie;
      case AppConstants.categoryCustom:
        return Icons.topic;
      default:
        return Icons.shuffle; // Karışık kategori
    }
  }
} 