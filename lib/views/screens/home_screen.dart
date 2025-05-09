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
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isScrolling = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
                      onNavigateToFavorites: () => _navigateToFavorites(context),
                    ),
                  );
                },
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
                          
                          // Wikimedia Kaynakları başlığı
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Wikimedia Kaynakları',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // WikiSpecies
                          ListTile(
                            leading: Icon(Icons.pets, color: Colors.green.shade300),
                            title: Text(
                              'WikiSpecies',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Türler hakkında bilgiler',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showWikiSpeciesDialog(context, viewModel);
                            },
                          ),
                          
                          // Commons
                          ListTile(
                            leading: Icon(Icons.image, color: Colors.amber.shade300),
                            title: Text(
                              'Wikimedia Commons',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Görsel ve medya içerikleri',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showCommonsDialog(context, viewModel);
                            },
                          ),
                          
                          // Gisburn Forest
                          ListTile(
                            leading: Icon(Icons.forest, color: Colors.green),
                            title: Text(
                              'Gisburn Forest',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Orman hakkında bilgiler',
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              viewModel.loadGisburnForestInfo();
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
        
        // Eğer özel kategoriyse ve seçili değilse, önce değiştir
        if (category == AppConstants.categoryCustom && !isSelected) {
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
        // Diğer kategoriler için sadece kategoriyi değiştir
        else {
          viewModel.changeCategory(category);
          _animationController.reset();
          _animationController.forward();
        }
      },
    );
  }
  
  // WikiSpecies için Dialog
  void _showWikiSpeciesDialog(BuildContext context, ArticleViewModel viewModel) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('WikiSpecies Ara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bir tür adı girin (Türkçe veya Latince):',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Örn: Köpek, Canis lupus...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Öneriler: Urocyon littoralis (Island Fox), Homo sapiens, Panthera tigris',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final species = controller.text.trim();
              if (species.isNotEmpty) {
                Navigator.pop(context);
                viewModel.loadWikiSpeciesInfo(species);
              }
            },
            child: Text('Ara'),
          ),
        ],
      ),
    );
  }
  
  // Commons için Dialog
  void _showCommonsDialog(BuildContext context, ArticleViewModel viewModel) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Commons Görselleri Ara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Görselleri aramak için bir konu girin:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Örn: Istanbul, Nature...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Öneriler: Gisburn Forest, Van Gogh, Famous Landmarks',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final topic = controller.text.trim();
              if (topic.isNotEmpty) {
                Navigator.pop(context);
                viewModel.loadCommonsImages(topic);
              }
            },
            child: Text('Ara'),
          ),
        ],
      ),
    );
  }
} 