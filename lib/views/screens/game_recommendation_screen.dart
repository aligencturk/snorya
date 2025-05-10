import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_view_model.dart';
import '../../utils/constants.dart';
import '../components/game_card.dart';
import 'favorites_screen.dart';

class GameRecommendationScreen extends StatefulWidget {
  const GameRecommendationScreen({super.key});

  @override
  State<GameRecommendationScreen> createState() => _GameRecommendationScreenState();
}

class _GameRecommendationScreenState extends State<GameRecommendationScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(
    viewportFraction: 1.0,
    keepPage: true,
  );
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isScrolling = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingSimilarContent = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchBar = false;
  
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
    
    // ViewModel'i başlat ve ilk oyunu yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<GameViewModel>(context, listen: false);
      viewModel.initialize();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Geri',
          ),
        ),
        title: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: _showSearchBar 
                ? _buildSearchBar()
                : const Text(
                    'Oyun Önerileri',
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
            );
          },
        ),
        actions: [
          // Arama butonu
          Container(
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _showSearchBar ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                  if (_showSearchBar) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _searchFocusNode.requestFocus();
                    });
                  } else {
                    _searchController.clear();
                  }
                });
              },
              tooltip: _showSearchBar ? 'Aramayı Kapat' : 'Oyun Ara',
            ),
          ),
        ],
      ),
      body: Consumer<GameViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.state == GameLoadingState.initial || 
              (viewModel.state == GameLoadingState.loading && viewModel.games.isEmpty)) {
            return _buildLoadingPlaceholder('Oyun önerileri yükleniyor...');
          }
          
          if (viewModel.state == GameLoadingState.error && viewModel.games.isEmpty) {
            return _buildErrorWidget(viewModel);
          }
          
          if (viewModel.state == GameLoadingState.empty && viewModel.games.isEmpty) {
            return _buildEmptyResultWidget(viewModel);
          }
          
          // İçerik yüklendiyse TikTok tarzı sonsuz scroll göster
          return Container(
            color: Colors.black,
            child: Stack(
              children: [
                // Oyun sayfaları
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: (index) {
                    // Kaydırma durumunu güncelle
                    _isScrolling = true;
                    
                    // AnimationController'ı yeniden başlat
                    _animationController.reset();
                    _animationController.forward();
                    
                    // Sonsuz kaydırma için kontrol et
                    viewModel.checkAndLoadMoreGames(index);
                    
                    // Kısa bir süre sonra kaydırma durumunu kapat
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) {
                        setState(() {
                          _isScrolling = false;
                        });
                      }
                    });
                  },
                  itemCount: viewModel.games.length,
                  itemBuilder: (context, index) {
                    // Oyun kartı
                    final game = viewModel.games[index];
                    
                    // Sonsuz kaydırma kontrolü
                    if (index >= viewModel.games.length - 3) {
                      // Son elemandan 3 oyun önce, otomatik olarak daha fazla içerik yükle
                      Future.microtask(() {
                        viewModel.checkAndLoadMoreGames(index);
                      });
                    }
                    
                    return FadeTransition(
                      opacity: _animation,
                      child: GameCard(
                        game: game,
                        onFavoriteToggle: () {
                          // Favori durumunu değiştir
                          viewModel.toggleFavorite();
                          
                          // Kullanıcıya görsel geri bildirim
                          final message = game.isFavorite ? 'Favorilerden kaldırıldı' : 'Favorilere eklendi';
                          final icon = game.isFavorite ? Icons.bookmark_remove : Icons.bookmark_add;
                          
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
                        onRefresh: () {
                          // Yeni bir oyun yükle
                          viewModel.refreshGameRecommendation();
                        },
                        onVerticalScroll: () {
                          // Bir sonraki oyuna kaydır
                          if (_pageController.page!.toInt() < viewModel.games.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuint,
                            );
                          }
                        },
                        onLoadSimilarGame: () {
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
                                  Text('Benzer oyun aranıyor...'),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(milliseconds: 2000),
                            ),
                          );
                          
                          // Benzer oyun yükle
                          viewModel.loadSimilarGameRecommendation().then((_) {
                            if (viewModel.games.isNotEmpty) {
                              // Başarılı bildirimi göster
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green),
                                      const SizedBox(width: 12),
                                      Text('Benzer oyun bulundu!'),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(milliseconds: 1500),
                                ),
                              );
                              
                              // Animasyon için bir geçiş efekti
                              _animationController.reset();
                              
                              // Sayfa geçişi
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _pageController.animateToPage(
                                  viewModel.games.length - 1,
                                  duration: const Duration(milliseconds: 700),
                                  curve: Curves.fastLinearToSlowEaseIn,
                                ).then((_) {
                                  // İçerik animasyonunu başlat
                                  _animationController.forward();
                                  
                                  // Yükleme durumunu güncelle
                                  setState(() {
                                    _isLoadingSimilarContent = false;
                                  });
                                });
                              });
                            } else {
                              // Yükleme durumunu güncelle
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
                                content: Text('Benzer oyun getirilirken hata oluştu'),
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
                
                // Arama mesajı gösterimi
                if (viewModel.isSearching)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${viewModel.lastQuery} için oyun önerileri aranıyor...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Arama çubuğu
  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'GTA tarzı oyun, RPG oyunu...',
          hintStyle: TextStyle(color: Colors.white70),
          prefixIcon: Icon(Icons.search, color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            // Arama sorgusunu viewModel'e gönder ve filtre parametresini kaldır
            final gameViewModel = Provider.of<GameViewModel>(context, listen: false);
            gameViewModel.generateGameRecommendation(value);
            
            // Arama yaptığında sadece arama çubuğunu gizle
            setState(() {
              _showSearchBar = false;
            });
          }
        },
      ),
    );
  }
  
  /// Hata ekranı widget'ı
  Widget _buildErrorWidget(GameViewModel viewModel) {
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
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (viewModel.games.isNotEmpty && viewModel.games[0].content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
                child: Text(
                  viewModel.games[0].content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showSearchBar = true;
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _searchFocusNode.requestFocus();
                      });
                    });
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Farklı Bir Sorgu'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.purple.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    viewModel.refreshGameRecommendation();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                viewModel.generateGameRecommendation('popüler oyun önerisi');
              },
              icon: const Icon(Icons.play_circle_outline, color: Colors.white70),
              label: const Text(
                'Popüler Oyun Önerisi Al', 
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Boş sonuç ekranı widget'ı
  Widget _buildEmptyResultWidget(GameViewModel viewModel) {
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
            const Icon(
              Icons.videogame_asset_off,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Aradığınız kriterlere uygun bir oyun bulunamadı.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Son arama sorgusu: ${viewModel.lastQuery}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showSearchBar = true;
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _searchFocusNode.requestFocus();
                  });
                });
              },
              icon: const Icon(Icons.search),
              label: const Text('Farklı Bir Oyun Ara'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                viewModel.generateGameRecommendation('popüler oyun önerisi');
              },
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label: const Text(
                'Popüler Oyun Önerilerini Getir', 
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Yükleme ekranı widget'ı
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
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 