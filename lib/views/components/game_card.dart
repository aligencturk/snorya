import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../models/game.dart';

class GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onRefresh;
  final VoidCallback? onNavigateToFavorites;
  final VoidCallback? onVerticalScroll;
  final VoidCallback? onLoadSimilarGame;
  
  const GameCard({
    super.key,
    required this.game,
    required this.onFavoriteToggle,
    this.onRefresh,
    this.onNavigateToFavorites,
    this.onVerticalScroll,
    this.onLoadSimilarGame,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> with SingleTickerProviderStateMixin {
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
    final String title = widget.game.title;
    final String summary = widget.game.summary;
    final String content = widget.game.content;
    final String imageUrl = widget.game.imageUrl;
    final bool isFavorite = widget.game.isFavorite;
    final String genre = widget.game.genre;
    final String platform = widget.game.platform;
    
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
          _buildSummaryPage(title, summary, genre, platform, isFavorite),
          
          // İkinci sayfa - Tam içerik
          _buildFullContentPage(title, content, imageUrl, genre, platform),
        ],
      ),
    );
  }
  
  // Özet sayfası - Oyun özelliklerine göre uyarlandı
  Widget _buildSummaryPage(String title, String summary, String genre, String platform, bool isFavorite) {
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
                  
                  // Başlık ve özet kısmı
                  Expanded(
                    child: ClipRect(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Oyun başlığı - Oyun konsolu stilinde tasarım
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF1A237E).withOpacity(0.9), // Koyu mavi
                                    const Color(0xFF3F51B5).withOpacity(0.6), // Mor-mavi
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
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
                            const SizedBox(height: 8),
                            
                            // Tür ve platform bilgisi
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  // Tür bilgisi
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.category,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            genre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Platform bilgisi
                                  if (platform.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.devices,
                                            color: Colors.lightBlueAccent,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              platform,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Oyun özeti - Konsol stilinde tasarım
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.9),
                                    const Color(0xFF222222).withOpacity(0.7), // Daha açık siyah
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
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
                                  height: 1.6,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Alt buton grubu
                            Column(
                              children: [
                                // Tam oyun detaylarını göster butonu
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF673AB7),
                                        const Color(0xFF3F51B5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
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
                                    icon: const Icon(Icons.videogame_asset, color: Colors.white),
                                    label: const Text(
                                      'Detaylı Oyun Bilgisini Gör',
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
                                
                                // Benzer oyun getir butonu
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF303F9F),
                                        const Color(0xFF1A237E),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        spreadRadius: 1,
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (widget.onLoadSimilarGame != null) {
                                        HapticFeedback.mediumImpact();
                                        widget.onLoadSimilarGame!();
                                      }
                                    },
                                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                                    label: const Text(
                                      'Benzer Oyun Önerisi',
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
                                        // Bir sonraki oyuna kaydır
                                        if (widget.onVerticalScroll != null) {
                                          widget.onVerticalScroll!();
                                        }
                                      },
                                      tooltip: 'Sonraki oyun',
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
          ],
        );
      },
    );
  }
  
  // Tam içerik sayfası - Oyun stili tasarım
  Widget _buildFullContentPage(String title, String content, String imageUrl, String genre, String platform) {
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
                ],
              ),
            ),
            
            // Görsel ve içerik alanı - Oyun konsolu benzeri tasarım
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A237E),
                      Color(0xFF000A24),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, -3),
                    ),
                  ],
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
                        // Görsel - Konsol stil
                        if (imageUrl.isNotEmpty)
                          Container(
                            height: 250,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            // Görsel üzerine gradient overlay
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.4),
                                  ],
                                  stops: const [0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                          
                        // Tür ve platform bilgisi
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Tür bilgisi
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        genre,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Platform bilgisi
                              if (platform.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.devices,
                                        color: Colors.lightBlueAccent,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          platform,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                          
                        // İçerik başlığı ve metin
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Neon ayırıcı çizgi
                              Container(
                                height: 3,
                                width: 100,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.purpleAccent, Colors.blueAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purpleAccent.withOpacity(0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // İçerik metni
                              Text(
                                content,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.6,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              
                              // Puanlar ve değerlendirmeler
                              _buildRatingsSection(widget.game.ratings),
                              _buildReviewsSection(widget.game.reviews),
                              
                              // Veri bulunmadığı durumda bilgilendirme mesajı göster
                              if ((widget.game.ratings == null || widget.game.ratings!.isEmpty) && 
                                  (widget.game.reviews == null || widget.game.reviews!.isEmpty))
                                Container(
                                  margin: const EdgeInsets.only(top: 32, bottom: 32),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.amber,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Bu oyun için değerlendirme ve puan bilgisi bulunamadı.',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Daha yaygın bir oyun için arama yapabilirsiniz.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              
                              // Altta ekstra boşluk
                              const SizedBox(height: 40),
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
  
  // Ek görseller
  Widget _buildAdditionalImages(List<Map<String, dynamic>> images) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white24,
                width: 1,
              ),
            ),
            child: const Text(
              'Ek Görseller',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Görsel galeri
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              physics: const BouncingScrollPhysics(),
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
                
                // Görsel kartı
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      title.replaceAll('File:', '').replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 5,
                          ),
                        ],
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
      // Hata durumunda boş widget döndür
      return const SizedBox.shrink();
    }
  }
  
  // Metadata bilgileri
  Widget _buildMetadata(Map<String, dynamic> metadata) {
    try {
      if (metadata.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Container(
        margin: const EdgeInsets.only(top: 32, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metadata['wikiUrl'] != null)
              _buildMetadataItem('Wikipedia', metadata['wikiUrl'].toString()),
            if (metadata['originalQuery'] != null)
              _buildMetadataItem('Arama Sorgusu', metadata['originalQuery'].toString()),
            // Diğer metadata bilgileri
            ...metadata.entries
                .where((e) => e.key != 'wikiUrl' && e.key != 'originalQuery' && e.key != 'searchTitle' && e.value != null)
                .map((e) => _buildMetadataItem(e.key, e.value.toString())),
          ],
        ),
      );
    } catch (e) {
      // Hata durumunda boş widget döndür
      return const SizedBox.shrink();
    }
  }
  
  // Metadata öğesi
  Widget _buildMetadataItem(String key, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiket
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.white24,
                width: 1,
              ),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Değer
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Oyun puanlarını gösteren widget
  Widget _buildRatingsSection(Map<String, dynamic>? ratings) {
    if (ratings == null || ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.withOpacity(0.5),
            Colors.blue.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'OYUN PUANLARI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Metacritic puanı
          if (ratings.containsKey('metacritic') && 
              ratings['metacritic'] != null &&
              ratings['metacritic']['score'] != null)
            _buildRatingItem(
              'Metacritic',
              '${ratings['metacritic']['score']}',
              ratings['metacritic']['score'] >= 75 ? Colors.green : 
              ratings['metacritic']['score'] >= 50 ? Colors.amber : Colors.red,
              '${ratings['metacritic']['count'] ?? 'Bilinmiyor'} inceleme',
              showBar: true,
              scoreValue: ratings['metacritic']['score'] / 100,
            ),
            
          // IGN puanı
          if (ratings.containsKey('ign') && 
              ratings['ign'] != null &&
              ratings['ign']['score'] != null)
            _buildRatingItem(
              'IGN',
              '${ratings['ign']['score']}/10',
              ratings['ign']['score'] >= 7.5 ? Colors.green : 
              ratings['ign']['score'] >= 5 ? Colors.amber : Colors.red,
              ratings['ign']['summary'] ?? '',
            ),
            
          // Steam değerlendirmesi
          if (ratings.containsKey('steam') && 
              ratings['steam'] != null &&
              ratings['steam']['positive_percent'] != null)
            _buildRatingItem(
              'Steam',
              '${ratings['steam']['positive_percent']}%',
              ratings['steam']['positive_percent'] >= 70 ? Colors.green : 
              ratings['steam']['positive_percent'] >= 50 ? Colors.amber : Colors.red,
              '${ratings['steam']['summary'] ?? ''} (${ratings['steam']['review_count'] ?? 'Bilinmiyor'} değerlendirme)',
              showBar: true,
              scoreValue: ratings['steam']['positive_percent'] / 100,
            ),
            
            // Eğer puan yoksa bilgilendirme göster
            if (!(ratings.containsKey('metacritic') && ratings['metacritic'] != null && ratings['metacritic']['score'] != null) &&
                !(ratings.containsKey('ign') && ratings['ign'] != null && ratings['ign']['score'] != null) &&
                !(ratings.containsKey('steam') && ratings['steam'] != null && ratings['steam']['positive_percent'] != null))
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Bu oyun için puan bilgisi bulunamadı.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// Oyun değerlendirmelerini gösteren widget
  Widget _buildReviewsSection(List<Map<String, dynamic>>? reviews) {
    if (reviews == null || reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.5),
            Colors.deepPurple.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rate_review, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'ELEŞTİRMEN YORUMLARI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sadece ilk değerlendirmeyi göster
          _buildReviewItem(reviews.first),
          
        ],
      ),
    );
  }

  /// Tek bir puan öğesi
  Widget _buildRatingItem(String source, String scoreText, Color scoreColor, String details, {bool showBar = false, double scoreValue = 0.0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Kaynak adı
              Text(
                source,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              // Puan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: scoreColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  scoreText,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          // Detay bilgisi
          if (details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                details,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          // İsteğe bağlı puan çubuğu
          if (showBar)
            Container(
              height: 4,
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: scoreValue,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scoreColor.withOpacity(0.7),
                        scoreColor,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Tek bir yorum öğesi
  Widget _buildReviewItem(Map<String, dynamic> review) {
    final String source = review['source'] ?? '';
    final String author = review['author'] ?? '';
    final String comment = review['comment'] ?? '';
    final String score = review['score'] ?? '';
    final String date = review['date'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst kısım - Kaynak, yazar, puan, tarih
          Row(
            children: [
              // Kaynak ve Yazar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      source,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (author.isNotEmpty)
                      Text(
                        author,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Puan varsa göster
              if (score.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    score,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          
          // Yorum içeriği
          if (comment.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                '"$comment"',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
            // Tarih varsa göster
            if (date.isNotEmpty)
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ),
        ],
      ),
    );
  }
} 