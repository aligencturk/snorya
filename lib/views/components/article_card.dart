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
                                    Colors.black.withOpacity(0.9),
                                    Colors.black.withOpacity(0.6),
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
                            const SizedBox(height: 16),
                            
                            // Makale özeti - Gradient arka plan ile
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.9),
                                    Colors.black.withOpacity(0.7),
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
                                  height: 1.6, // Satır aralığını arttır
                                  letterSpacing: 0.3, // Harfler arası mesafeyi arttır
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
                                          const Color(0xFF8B5A2B), // Koyu kahverengi
                                          const Color(0xFFA67C52), // Açık kahverengi
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
                                        const Color(0xFF6B4226), // Koyu kahverengi
                                        const Color(0xFF8B5A2B), // Orta kahverengi
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
                opacity: 0, // Butonları görünmez yap (tamamen kaldırmak yerine)
                duration: const Duration(milliseconds: 0),
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
  
  // Tam içerik sayfası - Modern tasarım
  Widget _buildFullContentPage(String title, String content, String imageUrl) {
    // Wikipedia içeriğinden referans kısımlarını temizleyen işlev - geliştirilmiş versiyonu
    final cleanedContent = _cleanWikipediaContent(content);
    
    // İçeriği işleyerek başlıkları tespit et
    final formattedContent = _formatWikipediaContent(cleanedContent);
    
    // Kitap sayfası renkleri - daha sarımsı, göz yorgunluğunu azaltan renk
    final Color pageBgColor = const Color(0xFFF5E8C6); // Daha sarımsı, kitap sayfası rengi
    final Color textColor = const Color(0xFF3A3A3A); // Koyu gri metin rengi
    
    return Container(
      color: Colors.black, // Siyah arka plan
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
            
            // Görsel ve içerik alanı - Kitap benzeri tasarım
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: pageBgColor, // Vintage sarı kağıt rengi
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
                        // Görsel - Daha yüksek ve şık
                        if (imageUrl.isNotEmpty)
                          Container(
                            height: 250, // Daha yüksek görsel
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
                            // Görsel üzerine gradient overlay ekle
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
                          
                        // İçerik başlığı ve metin - Vintage kitap tasarımı
                        Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Başlık - Daha büyük ve dikkat çekici
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4A3B22), // Koyu kahverengi başlık
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Vintage ayırıcı çizgi
                              Container(
                                height: 3,
                                width: 100,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFF8B5A2B), const Color(0xFFD2B48C)],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // İşlenmiş içerik (başlıkları zenginleştirilmiş)
                              formattedContent,
                              
                              // Ek görseller varsa göster - Tasarım iyileştirildi
                              if (widget.article.additionalImages != null && 
                                  widget.article.additionalImages!.isNotEmpty &&
                                  widget.article.additionalImages is List)
                                _buildAdditionalImagesModern(widget.article.additionalImages!),
                              
                              // Metadata varsa göster - Tasarım iyileştirildi
                              if (widget.article.metadata != null)
                                _buildMetadataModern(widget.article.metadata!),
                                
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
  
  // Wikipedia içeriğinden referans kısımlarını daha güçlü şekilde temizle
  String _cleanWikipediaContent(String content) {
    final referenceHeaders = [
      'Kaynakça',
      'Ayrıca bakınız',
      'Dış bağlantılar',
      'Notlar',
      'Referanslar',
      'Not ve referanslar',
      'Dipnotlar',
      'İlgili maddeler',
      'İlgili konular',
      'Bibliyografya',
      'Ayrıca bkz.',
      'Kaynak',
      'Kaynaklar',
      'Ayrıca bakınız',
      'Ek okumalar',
      'Dış kaynaklar',
      'Kaynaklar ve notlar',
      'Ayrıca okuyun',
      'Linkler',
      'Bağlantılar',
      'Daha fazla bilgi',
      'Referans listesi',
      'Makale notları',
      'Dış linkler',
      'Ek bilgi',
      'Diğer bilgiler',
      'Referans kaynakları',
      'Referanslar ve dipnotlar',
    ];
    
    // Daha fazla varyasyon yakalamak için küçük harfe çevirip kontrol edelim
    final contentLower = content.toLowerCase();
    
    // Önce basit bir şekilde başlık kontrolü yaparak içeriği kırpalım
    for (final header in referenceHeaders) {
      final headerLower = header.toLowerCase();
      
      // Tüm olası başlık formatlarını kontrol et
      final patterns = [
        '\n$headerLower\n',
        '\n $headerLower\n',
        '\n$headerLower \n',
        '\n $headerLower \n',
        '\n$headerLower',
        '\n $headerLower',
        '== $headerLower ==',
        '==$headerLower==',
        '=== $headerLower ===',
        '===$headerLower===',
      ];
      
      for (final pattern in patterns) {
        final headerIndex = contentLower.indexOf(pattern);
        if (headerIndex != -1) {
          return content.substring(0, headerIndex);
        }
      }
      
      // Daha esnek bir regex yaklaşımı
      final alternativePattern = RegExp(r'(\n\s*)(={2,})?\s*' + RegExp.escape(headerLower) + r'\s*(={2,})?(\s*\n|\s*$)', caseSensitive: false);
      final alternativeMatch = alternativePattern.firstMatch(contentLower);
      
      if (alternativeMatch != null) {
        return content.substring(0, alternativeMatch.start);
      }
    }
    
    // Ardışık === veya == arasında referans başlığı içeren tüm kalıpları kontrol et
    final headingPattern = RegExp(r'(={2,})\s*(' + referenceHeaders.map((h) => RegExp.escape(h.toLowerCase())).join('|') + r')\s*\1', caseSensitive: false);
    final headingMatch = headingPattern.firstMatch(contentLower);
    
    if (headingMatch != null) {
      return content.substring(0, headingMatch.start);
    }
    
    return content;
  }
  
  // Wikipedia içeriğini işle, başlıkları tespit et ve özel biçimde göster - Daha dengeli başlıklar
  Widget _formatWikipediaContent(String content) {
    // İçeriği satırlara böl
    final lines = content.split('\n');
    final formattedWidgets = <Widget>[];
    
    bool isInList = false;
    List<Widget> listItems = [];
    
    // Vintage kitap renkleri
    final Color textColor = const Color(0xFF473C2E); // Daha koyu, okunabilir metin rengi
    final Color headingColor = const Color(0xFF4A3B22); // Koyu kahverengi başlık rengi
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Boş satırları atla
      if (line.isEmpty) {
        // Eğer listeden çıkıyorsak listeyi ekle
        if (isInList && listItems.isNotEmpty) {
          formattedWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: listItems,
              ),
            )
          );
          listItems = [];
          isInList = false;
        }
        continue;
      }
      
      // Madde işaretli liste öğelerini tespit et
      if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
        // Madde işaretli listenin başlangıcı
        isInList = true;
        final itemText = line.substring(2);
        
        listItems.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8, right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5A2B), // Koyu kahverengi nokta
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    itemText,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }
      
      // Önceki listeden çıkılıyorsa, listeyi ekle
      if (isInList && listItems.isNotEmpty) {
        formattedWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: listItems,
            ),
          )
        );
        listItems = [];
        isInList = false;
      }
      
      // Başlıkları tespit et - Geliştirilmiş versiyon
      bool isHeading = false;
      int headingLevel = 3; // Varsayılan en düşük başlık seviyesi
      
      // Başlık tespiti için daha kesin bir yaklaşım
      // 1. = veya == ile işaretlenen başlıklar (Wikipedia formatı)
      if (line.startsWith('=') && line.endsWith('=')) {
        isHeading = true;
        final equalsCount = line.indexOf(' ');
        headingLevel = equalsCount > 0 ? 4 - equalsCount.clamp(1, 3) : 1;
        // Başlık metnini al
        final headingText = line.replaceAll(RegExp(r'^=+\s*|\s*=+$'), '');
        
        // Başlıksa özel stil ver
        formattedWidgets.add(
          _buildStylizedHeading(headingText, headingLevel, headingColor)
        );
        continue;
      }
      
      // 2. Satır uzunluğu, sınırlar ve sonraki satır kriterlerine göre başlıkları tespit etme
      if (line.length < 60 && i < lines.length - 1) {
        if (lines[i + 1].trim().isEmpty || lines[i + 1].trim().startsWith('=')) {
          isHeading = true;
          
          // Başlık seviyesini daha tutarlı bir şekilde tahmin et
          if (line.length < 25) headingLevel = 1;
          else if (line.length < 40) headingLevel = 2;
          else headingLevel = 3;
        } 
        
        // Yaygın başlık kalıplarını kontrol et
        if (line.endsWith(':')) {
          isHeading = true;
          headingLevel = 2;
        }
      }
      
      // Başlıksa özel stil ver
      if (isHeading) {
        formattedWidgets.add(
          _buildStylizedHeading(line, headingLevel, headingColor)
        );
      } else {
        // Normal metinse vintage kitap stili paragraf olarak ekle
        formattedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              line,
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: textColor, // Kitap benzeri metin rengi
                letterSpacing: 0.2, // Harfler arası mesafe
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      }
    }
    
    // Eğer listeden çıkmadan kalmışsa listeyi ekle
    if (isInList && listItems.isNotEmpty) {
      formattedWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: listItems,
          ),
        )
      );
    }
    
    // Tüm biçimlendirilmiş widgetları bir sütunda birleştir
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formattedWidgets,
    );
  }
  
  // Özelleştirilmiş, daha dengeli başlık bileşeni
  Widget _buildStylizedHeading(String text, int level, Color headingColor) {
    // Kitap temasına uygun kahverengi tonları - Daha tutarlı ve dengeli
    final List<List<Color>> levelColors = [
      [const Color(0xFF5D4037), const Color(0xFF8D6E63)], // Level 1 - En koyu kahverengi
      [const Color(0xFF795548), const Color(0xFFA1887F)], // Level 2 - Orta kahverengi
      [const Color(0xFF8D6E63), const Color(0xFFBCAAA4)], // Level 3 - Açık kahverengi
    ];
    
    // Başlık seviyesine göre font boyutu ve çizgi uzunluğu - Daha dengeli görünüm
    final double fontSize = level == 1 ? 22 : (level == 2 ? 19 : 16);
    final double lineWidth = level == 1 ? 80 : (level == 2 ? 60 : 40);
    final double topPadding = level == 1 ? 28 : (level == 2 ? 24 : 18);
    
    // Başlık metnini temizle - Wikipedia formatındaki = işaretlerini kaldır
    final cleanText = text.replaceAll(RegExp(r'^=+\s*|\s*=+$'), '');
    
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık metni
          Container(
            padding: EdgeInsets.symmetric(vertical: level == 1 ? 8 : 6, horizontal: level == 1 ? 14 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E8C6), // Kitap sayfası rengiyle uyumlu arka plan
              border: Border(
                left: BorderSide(
                  color: levelColors[level - 1][0],
                  width: level == 1 ? 4 : (level == 2 ? 3 : 2),
                ),
                bottom: BorderSide(
                  color: levelColors[level - 1][0].withOpacity(0.5),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              cleanText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: headingColor,
                letterSpacing: 0.2,
              ),
            ),
          ),
          
          // Ayırıcı çizgi - Daha zarif görünüm
          Container(
            height: 2,
            width: lineWidth,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [levelColors[level - 1][0], levelColors[level - 1][1].withOpacity(0.3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ek görselleri vintage kitap temasına uygun göster
  Widget _buildAdditionalImagesModern(List<Map<String, dynamic>> images) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Vintage tarzı başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E8C6), // Sarımsı kitap sayfası temasıyla uyumlu
              border: Border(
                left: const BorderSide(
                  color: Color(0xFF8B5A2B),
                  width: 3,
                ),
                bottom: BorderSide(
                  color: const Color(0xFF8B5A2B).withOpacity(0.5),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Ek Görseller',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A3B22), // Koyu kahverengi
              ),
            ),
          ),
          // Ayırıcı çizgi
          Container(
            height: 2,
            width: 60,
            margin: const EdgeInsets.only(top: 6, bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF8B5A2B), const Color(0xFFD2B48C).withOpacity(0.3)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          
          // Modern görsel galeri - Kitap temasına uygun
          SizedBox(
            height: 180, // Daha büyük görsel kartları
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
                
                // Vintage kitap tarzı görsel kartı
                return Container(
                  width: 220, // Daha geniş
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(
                      color: const Color(0xFF8B5A2B).withOpacity(0.3),
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
                          const Color(0xFF4A3B22).withOpacity(0.8), // Kahverengi, kitap temasıyla uyumlu
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
      // Herhangi bir hata durumunda boş bir widget döndür
      return const SizedBox.shrink();
    }
  }
  
  // Metadata bilgilerini vintage kitap temasına uygun göster
  Widget _buildMetadataModern(Map<String, dynamic> metadata) {
    try {
      if (metadata.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Container(
        margin: const EdgeInsets.only(top: 32, bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5E8C6).withOpacity(0.7), // Sarımsı kitap sayfası rengiyle uyumlu
          border: Border.all(
            color: const Color(0xFF8B5A2B).withOpacity(0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metadata['originalSource'] != null)
              _buildMetadataItemModern('Kaynak', metadata['originalSource'].toString()),
            if (metadata['url'] != null)
              _buildMetadataItemModern('URL', metadata['url'].toString()),
            // Diğer metadata bilgileri
            ...metadata.entries
                .where((e) => e.key != 'originalSource' && e.key != 'url' && e.value != null)
                .map((e) => _buildMetadataItemModern(e.key, e.value.toString())),
          ],
        ),
      );
    } catch (e) {
      // Herhangi bir hata durumunda boş bir widget döndür
      return const SizedBox.shrink();
    }
  }
  
  // Vintage metadata öğesi
  Widget _buildMetadataItemModern(String key, String value) {
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
              color: const Color(0xFFF5ECD7),
              border: Border.all(
                color: const Color(0xFFD2B48C),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: const Color(0xFF4A3B22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Değer
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF3A3A3A),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 