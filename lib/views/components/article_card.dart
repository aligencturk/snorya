import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/article.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onRefresh;
  final VoidCallback? onNavigateToFavorites;
  final VoidCallback? onVerticalScroll;
  final VoidCallback? onLoadSimilarArticle;
  
  const ArticleCard({
    super.key,
    required this.article,
    required this.onFavoriteToggle,
    this.onRefresh,
    this.onNavigateToFavorites,
    this.onVerticalScroll,
    this.onLoadSimilarArticle,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonAnimation;
  bool _buttonsVisible = false;
  
  @override
  void initState() {
    super.initState();
    
    // Buton animasyonu için kontrolcü oluştur
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _buttonAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Butonları 0.5 saniye sonra göster
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _buttonsVisible = true;
        });
        _buttonAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonAnimationController.dispose();
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
          _buildFullContentPage(title, content, imageUrl),
        ],
      ),
    );
  }
  
  // Özet sayfası
  Widget _buildSummaryPage(String title, String summary, bool isFavorite) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // İçerik alanı - Taşmayı önlemek için düzenleme
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Üst boşluk
                  SizedBox(height: constraints.maxHeight * 0.2),
                  
                  // Başlık ve özet kısmı - Taşma hatası buradan kaynaklanıyor
                  Expanded(
                    child: ClipRect(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Makale başlığı - Gradient arka plan ile
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withOpacity(0.8),
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Makale özeti - Gradient arka plan ile
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                summary,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                    ),
                                  ],
                                  height: 1.5,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Alt buton grubu
                            Column(
                              children: [
                                // Tam makaleyi okuma butonu
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade600,
                                        Colors.blue.shade800,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.shade700.withOpacity(0.5),
                                        spreadRadius: 1,
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _pageController.animateToPage(
                                        1,
                                        duration: const Duration(milliseconds: 500),
                                        curve: Curves.easeOutQuint,
                                      );
                                    },
                                    icon: const Icon(Icons.article, color: Colors.white),
                                    label: const Text(
                                      'Makalenin Tamamını Oku',
                                      style: TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                                // Benzer bilgi getir butonu
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.purple.shade700,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.shade700.withOpacity(0.4),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (widget.onLoadSimilarArticle != null) {
                                        HapticFeedback.mediumImpact(); // Titreşim ile geri bildirim
                                        widget.onLoadSimilarArticle!();
                                      }
                                    },
                                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                                    label: const Text(
                                      'Benzer Bilgi Getir',
                                      style: TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                                // Aşağı kaydırma butonu - sağ altta bırakıyoruz
                                const SizedBox(height: 16),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      onPressed: () {
                                        // Bir sonraki makaleye kaydır
                                        if (widget.onVerticalScroll != null) {
                                          widget.onVerticalScroll!();
                                        }
                                      },
                                      tooltip: 'Sonraki makale',
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Üst butonlar
            Positioned(
              top: 55,
              right: 20,
              child: AnimatedOpacity(
                opacity: _buttonsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                child: ScaleTransition(
                  scale: _buttonAnimation,
                  child: Row(
                    children: [
                      // Favoriler sayfasına git butonu
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.star, color: Colors.amber, size: 20),
                                onPressed: () {
                                  // Animasyonlu tıklama efekti
                                  HapticFeedback.mediumImpact();
                                  // Ölçek animasyonu
                                  final _controller = AnimationController(
                                    duration: const Duration(milliseconds: 150),
                                    vsync: this,
                                  );
                                  final _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(_controller);
                                  _controller.forward().then((_) => _controller.reverse()).then((_) => _controller.dispose());
                                  
                                  if (widget.onNavigateToFavorites != null) {
                                    widget.onNavigateToFavorites!();
                                  }
                                },
                                tooltip: 'Favoriler',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      // Favori butonu
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return ScaleTransition(
                                      scale: animation,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    isFavorite ? Icons.bookmark : Icons.bookmark_border,
                                    key: ValueKey<bool>(isFavorite),
                                    color: isFavorite ? Colors.amber : Colors.white,
                                    size: 20,
                                  ),
                                ),
                                onPressed: () {
                                  // Animasyonlu tıklama efekti
                                  HapticFeedback.mediumImpact();
                                  widget.onFavoriteToggle();
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Tam içerik sayfası - Apple/React tarzı tasarım
  Widget _buildFullContentPage(String title, String content, String imageUrl) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Modern üst bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Geri butonu
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutQuint,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Geri',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Favorilere Git butonu
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      onPressed: () {
                        // Animasyonlu tıklama efekti
                        HapticFeedback.mediumImpact();
                        if (widget.onNavigateToFavorites != null) {
                          widget.onNavigateToFavorites!();
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Favori butonu
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          widget.article.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          key: ValueKey<bool>(widget.article.isFavorite),
                          color: widget.article.isFavorite ? Colors.amber : Colors.white,
                          size: 20,
                        ),
                      ),
                      onPressed: () {
                        // Animasyonlu tıklama efekti
                        HapticFeedback.mediumImpact();
                        widget.onFavoriteToggle();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            
            // Görsel ve içerik alanı
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                margin: const EdgeInsets.only(top: 16),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Görsel
                        if (imageUrl.isNotEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          
                        // İçerik başlığı ve metin
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 4,
                                width: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade300, Colors.blue.shade700],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Tam içerik metni
                              Text(
                                content,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                              
                              // Ek görseller varsa göster
                              if (widget.article.additionalImages != null && 
                                  widget.article.additionalImages!.isNotEmpty &&
                                  widget.article.additionalImages is List)
                                _buildAdditionalImages(widget.article.additionalImages!),
                              
                              // Metadata varsa göster
                              if (widget.article.metadata != null)
                                _buildMetadata(widget.article.metadata!),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Ek görselleri göster
  Widget _buildAdditionalImages(List<Map<String, dynamic>> images) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Ek Görseller',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                if (image is! Map<String, dynamic>) {
                  return const SizedBox.shrink();
                }
                
                final String url = image['url'] ?? '';
                final String title = image['title']?.toString() ?? '';
                
                if (url.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      title.replaceAll('File:', '').replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } catch (e) {
      // Herhangi bir hata durumunda boş bir widget döndür
      return const SizedBox.shrink();
    }
  }
  
  // Metadata bilgilerini göster
  Widget _buildMetadata(Map<String, dynamic> metadata) {
    try {
      if (metadata.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (metadata['originalSource'] != null)
                  _buildMetadataItem('Kaynak', metadata['originalSource'].toString()),
                if (metadata['url'] != null)
                  _buildMetadataItem('URL', metadata['url'].toString()),
                // Diğer metadata bilgileri
                ...metadata.entries
                    .where((e) => e.key != 'originalSource' && e.key != 'url' && e.value != null)
                    .map((e) => _buildMetadataItem(e.key, e.value.toString())),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      // Herhangi bir hata durumunda boş bir widget döndür
      return const SizedBox.shrink();
    }
  }
  
  // Metadata öğesi
  Widget _buildMetadataItem(String key, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blueGrey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 