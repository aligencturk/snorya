import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/movie.dart';
import '../../services/gemini_service.dart';
import '../../services/storage_service.dart';
import '../../services/wiki_service.dart';
import '../../utils/constants.dart';
import '../../viewmodels/movie_view_model.dart';
import 'dart:convert';

class MovieRecommendationScreen extends StatefulWidget {
  const MovieRecommendationScreen({super.key});

  @override
  State<MovieRecommendationScreen> createState() => _MovieRecommendationScreenState();
}

class _MovieRecommendationScreenState extends State<MovieRecommendationScreen> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  final PageController _detailsPageController = PageController(viewportFraction: 1.0);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  bool _showDetails = false;
  Map<String, dynamic> _movieDetails = {};
  bool _isLoadingDetails = false;
  
  // Filtreleme değişkenleri
  String? _selectedType; // 'movie' veya 'tv' veya null (her ikisi)
  String? _selectedGenre; // Seçilen tür veya null (tüm türler)
  bool _showFilterMenu = false;
  final List<String> _availableGenres = [
    'Aksiyon', 'Komedi', 'Dram', 'Bilim Kurgu', 'Korku', 
    'Romantik', 'Macera', 'Animasyon', 'Suç', 'Belgesel', 
    'Fantastik', 'Tarih', 'Müzikal', 'Gizem', 'Savaş'
  ];
  
  @override
  void initState() {
    super.initState();
    
    // ViewModel'i başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final movieViewModel = Provider.of<MovieViewModel>(context, listen: false);
      movieViewModel.initialize();
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _detailsPageController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showDetails) {
          setState(() {
            _showDetails = false;
            _detailsPageController.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
          return false;
        }
        
        if (_showFilterMenu) {
          setState(() {
            _showFilterMenu = false;
          });
          return false;
        }
        
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterChips(),
              _buildSearchBar(),
              Expanded(
                child: Consumer<MovieViewModel>(
                  builder: (context, movieViewModel, child) {
                    if (movieViewModel.state == MovieLoadingState.initial ||
                        (movieViewModel.state == MovieLoadingState.loading && 
                         movieViewModel.movies.isEmpty)) {
                      return _buildLoadingWidget();
                    }
                    
                    if (movieViewModel.state == MovieLoadingState.error && 
                        movieViewModel.movies.isEmpty) {
                      return _buildErrorWidget(movieViewModel.errorMessage);
                    }
                    
                    // Filtreleme uygula
                    final filteredMovies = _filterMovies(movieViewModel.movies);
                    
                    if (filteredMovies.isEmpty) {
                      return _buildEmptyResultWidget();
                    }
                    
                    return _buildMovieList(movieViewModel, filteredMovies);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Film/dizileri filtreleme
  List<Movie> _filterMovies(List<Movie> movies) {
    return movies.where((movie) {
      // İçerik tipine göre filtreleme (film/dizi)
      if (_selectedType != null && movie.type != _selectedType) {
        return false;
      }
      
      // Türe göre filtreleme
      if (_selectedGenre != null && !movie.genres.contains(_selectedGenre)) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Text(
                'Dizi/Film Önerileri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          // Filtreleme butonu
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedType != null || _selectedGenre != null 
                  ? Colors.amber 
                  : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showFilterMenu = !_showFilterMenu;
              });
              _showFilterDialog();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips() {
    if (_selectedType == null && _selectedGenre == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedType != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  _selectedType == 'movie' ? 'Film' : 'Dizi',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.blue.shade700,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white,
                ),
                onDeleted: () {
                  setState(() {
                    _selectedType = null;
                  });
                  _applyFilters();
                },
              ),
            ),
            
          if (_selectedGenre != null)
            Chip(
              label: Text(
                _selectedGenre!,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.indigo.shade700,
              deleteIcon: const Icon(
                Icons.close,
                size: 18,
                color: Colors.white,
              ),
              onDeleted: () {
                setState(() {
                  _selectedGenre = null;
                });
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }
  
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtreler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // İçerik tipi seçimi (Film/Dizi)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'İçerik Tipi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildTypeFilterChip(
                            'Tümü', 
                            null, 
                            setModalState
                          ),
                          const SizedBox(width: 8),
                          _buildTypeFilterChip(
                            'Film', 
                            'movie', 
                            setModalState
                          ),
                          const SizedBox(width: 8),
                          _buildTypeFilterChip(
                            'Dizi', 
                            'tv', 
                            setModalState
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Tür seçimi
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tür',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildGenreFilterChip(
                            'Tümü', 
                            null, 
                            setModalState
                          ),
                          ..._availableGenres.map((genre) => 
                            _buildGenreFilterChip(
                              genre, 
                              genre, 
                              setModalState
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Filtreleri uygula butonu
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text(
                        'Filtreleri Uygula',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
  
  Widget _buildTypeFilterChip(String label, String? value, StateSetter setModalState) {
    final isSelected = _selectedType == value;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
        ),
      ),
      selected: isSelected,
      checkmarkColor: Colors.white,
      selectedColor: Colors.blue,
      backgroundColor: Colors.grey.shade800,
      onSelected: (selected) {
        setModalState(() {
          _selectedType = selected ? value : null;
        });
        setState(() {
          _selectedType = selected ? value : null;
        });
      },
    );
  }
  
  Widget _buildGenreFilterChip(String label, String? value, StateSetter setModalState) {
    final isSelected = _selectedGenre == value;
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
        ),
      ),
      selected: isSelected,
      checkmarkColor: Colors.white,
      selectedColor: Colors.indigo,
      backgroundColor: Colors.grey.shade800,
      onSelected: (selected) {
        setModalState(() {
          _selectedGenre = selected ? value : null;
        });
        setState(() {
          _selectedGenre = selected ? value : null;
        });
      },
    );
  }
  
  void _applyFilters() {
    final movieViewModel = Provider.of<MovieViewModel>(context, listen: false);
    
    // Görünüm modelinde filtreleri ayarla
    movieViewModel.selectedType = _selectedType;
    movieViewModel.selectedGenre = _selectedGenre;
    
    // Eğer filtrelenmiş bir sonuç yoksa yeni içerik iste
    if (_filterMovies(movieViewModel.movies).isEmpty) {
      String filterQuery = '';
      
      if (_selectedType != null) {
        filterQuery += _selectedType == 'movie' ? 'film ' : 'dizi ';
      }
      
      if (_selectedGenre != null) {
        filterQuery += _selectedGenre!;
      }
      
      if (filterQuery.isNotEmpty) {
        movieViewModel.searchMovies(filterQuery, type: _selectedType, genre: _selectedGenre);
      } else {
        movieViewModel.reset();
        movieViewModel.initialize();
      }
    } else {
      // Sayfayı yeniden yüklemek için state'i güncelleyelim
      setState(() {});
    }
  }
  
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Behzat Ç tarzı dizi, komedi filmi...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    setState(() {
                      _isSearching = false;
                    });
                    Provider.of<MovieViewModel>(context, listen: false).clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (query) {
          if (query.isNotEmpty) {
            setState(() {
              _isSearching = true;
              // Filtreleri sıfırla
              _selectedType = null;
              _selectedGenre = null;
            });
            Provider.of<MovieViewModel>(context, listen: false).searchMovies(query);
          }
        },
      ),
    );
  }
  
  Widget _buildLoadingWidget() {
    return ListView.builder(
      itemCount: 5, // Gösterilecek shimmer sayısı
      itemBuilder: (context, index) => _buildMovieCardShimmer(),
    );
  }
  
  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            'Bir sorun oluştu',
            style: TextStyle(
              color: Colors.white, 
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<MovieViewModel>(context, listen: false).reset();
              Provider.of<MovieViewModel>(context, listen: false).initialize();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyResultWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.movie_filter,
            color: Colors.grey,
            size: 70,
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir arama terimi deneyin',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMovieList(MovieViewModel viewModel, List<Movie> movies) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: movies.length + 1, // Son elemandan sonra bir yükleme göstergesi
      onPageChanged: (index) {
        // Son sayfaya yaklaşıldığında daha fazla yükle (son 3 elemana gelince)
        if (index >= movies.length - 3 && index < movies.length) {
          viewModel.loadMore();
        }
        
        // Mevcut filmi ayarla (son eleman yüklenme göstergesi değilse)
        if (index < movies.length) {
          final movie = movies[index];
          viewModel.setCurrentMovie(movie);
          
          // Detay ekranını sıfırla
          setState(() {
            _showDetails = false;
            _movieDetails = {};
          });
        }
      },
      itemBuilder: (context, index) {
        // Son eleman için yükleme göstergesi göster
        if (index == movies.length) {
          return _buildLoadingMoreIndicator(viewModel);
        }
        
        final movie = movies[index];
        return _buildMoviePageItem(movie, viewModel);
      },
    );
  }
  
  Widget _buildLoadingMoreIndicator(MovieViewModel viewModel) {
    // Son eleman için yükleme göstergesi göster
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          const SizedBox(height: 16),
          Text(
            'Daha fazla içerik yükleniyor...',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => viewModel.loadMore(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoviePageItem(Movie movie, MovieViewModel viewModel) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Sağa kaydırma hareketi algılandı (negatif hız sağa kaydırma anlamına gelir)
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          _showMovieDetails(movie);
        }
      },
      child: PageView(
        controller: _detailsPageController,
        physics: _showDetails ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _showDetails = index == 1;
          });
        },
        children: [
          _buildMovieCard(movie, viewModel),
          _buildMovieDetailsPage(movie, viewModel),
        ],
      ),
    );
  }
  
  Future<void> _showMovieDetails(Movie movie) async {
    setState(() {
      _showDetails = true;
      _isLoadingDetails = true;
    });
    
    _detailsPageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    try {
      // Wikipedia API'sinden film detaylarını al
      final wikiService = Provider.of<WikiService>(context, listen: false);
      final Map<String, dynamic>? details = await wikiService.fetchArticleByTitle(movie.title);
      
      // IMDb ve diğer detayları al
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final String prompt = 'Şu film veya dizi hakkında IMDb puanı, Rotten Tomatoes puanı ve kısa inceleme bilgilerini bul: "${movie.title}". Sadece JSON formatında dön: {"imdbRating": "7.5", "rottenTomatoesRating": "85%", "review": "Kısa bir inceleme"}. Bilgi bulunamazsa null değer döndür.';
      final String response = await geminiService.generateContent(prompt);
      
      Map<String, dynamic> ratingData = {};
      try {
        // JSON yanıtını ayıkla
        String jsonText = response;
        
        if (jsonText.contains("{") && jsonText.contains("}")) {
          int startIndex = jsonText.indexOf('{');
          int endIndex = jsonText.lastIndexOf('}') + 1;
          
          if (startIndex >= 0 && endIndex > startIndex) {
            jsonText = jsonText.substring(startIndex, endIndex);
            ratingData = Map<String, dynamic>.from(json.decode(jsonText));
          }
        }
      } catch (e) {
        print('Rating veri ayrıştırma hatası: $e');
      }
      
      setState(() {
        _movieDetails = {
          ...details ?? {},
          ...ratingData
        };
        _isLoadingDetails = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }
  
  Widget _buildMovieCard(Movie movie, MovieViewModel viewModel) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filmin resmi
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: movie.posterUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.posterUrl,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[800]!,
                              highlightColor: Colors.grey[700]!,
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade900,
                              child: const Center(
                                child: Icon(
                                  Icons.movie,
                                  color: Colors.grey,
                                  size: 70,
                                ),
                              ),
                            ),
                            fit: BoxFit.cover,
                          )
                        : FutureBuilder<String>(
                            future: viewModel.getPosterUrl(movie.title, movie.type ?? 'movie'),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[800]!,
                                  highlightColor: Colors.grey[700]!,
                                  child: Container(
                                    color: Colors.white,
                                  ),
                                );
                              }
                              
                              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                // Bu durumda viewModel'de movie.posterUrl'i snapshot.data ile güncelleyebiliriz
                                // ama bu örnekte doğrudan CachedNetworkImage kullanıyoruz
                                return CachedNetworkImage(
                                  imageUrl: snapshot.data!,
                                  placeholder: (context, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[800]!,
                                    highlightColor: Colors.grey[700]!,
                                    child: Container(
                                      color: Colors.white,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade900,
                                    child: const Center(
                                      child: Icon(
                                        Icons.movie,
                                        color: Colors.grey,
                                        size: 70,
                                      ),
                                    ),
                                  ),
                                  fit: BoxFit.cover,
                                );
                              }
                              
                              return Container(
                                color: Colors.grey.shade900,
                                child: const Center(
                                  child: Icon(
                                    Icons.movie,
                                    color: Colors.grey,
                                    size: 70,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Film başlığı
              Text(
                movie.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Film türleri
              Wrap(
                spacing: 8,
                children: movie.genres.map((genre) {
                  return Chip(
                    label: Text(
                      genre,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.blue.shade900,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Film özeti
              Expanded(
                flex: 2,
                child: Text(
                  movie.overview,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Favori butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      movie.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: movie.isFavorite ? Colors.amber : Colors.white,
                    ),
                    onPressed: () => viewModel.toggleFavorite(movie),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // İleri butonu
        Positioned(
          right: 30,
          top: 575,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => _showMovieDetails(movie),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'İleri',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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
  }
  
  Widget _buildMovieDetailsPage(Movie movie, MovieViewModel viewModel) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Boşluk (appbar için)
              const SizedBox(height: 40),
              
              // Film posteri ve detaylar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 120,
                      height: 180,
                      child: movie.posterUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: movie.posterUrl,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[800]!,
                                highlightColor: Colors.grey[700]!,
                                child: Container(
                                  color: Colors.white,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey.shade900,
                                child: const Center(
                                  child: Icon(
                                    Icons.movie,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              ),
                              fit: BoxFit.cover,
                            )
                          : FutureBuilder<String>(
                              future: viewModel.getPosterUrl(movie.title, movie.type ?? 'movie'),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey[800]!,
                                    highlightColor: Colors.grey[700]!,
                                    child: Container(
                                      color: Colors.white,
                                    ),
                                  );
                                }
                                
                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  return CachedNetworkImage(
                                    imageUrl: snapshot.data!,
                                    placeholder: (context, url) => Shimmer.fromColors(
                                      baseColor: Colors.grey[800]!,
                                      highlightColor: Colors.grey[700]!,
                                      child: Container(
                                        color: Colors.white,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey.shade900,
                                      child: const Center(
                                        child: Icon(
                                          Icons.movie,
                                          color: Colors.grey,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                  );
                                }
                                
                                return Container(
                                  color: Colors.grey.shade900,
                                  child: const Center(
                                    child: Icon(
                                      Icons.movie,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Detaylar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.rating.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          movie.type == 'movie' ? 'Film' : 'Dizi',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yayın Tarihi: ${movie.releaseDate}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // IMDB Puanı
              if (_isLoadingDetails)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Dizi/film detayları yükleniyor...',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                )
              else ...[
                if (_movieDetails.containsKey('imdbRating') && _movieDetails['imdbRating'] != null) ...[
                  _buildRatingSection('IMDb Puanı', _movieDetails['imdbRating'].toString(), Icons.star, Colors.amber),
                  const SizedBox(height: 16),
                ],
                
                if (_movieDetails.containsKey('rottenTomatoesRating') && _movieDetails['rottenTomatoesRating'] != null) ...[
                  _buildRatingSection('Rotten Tomatoes', _movieDetails['rottenTomatoesRating'].toString(), Icons.thumb_up, Colors.red),
                  const SizedBox(height: 16),
                ],
                
                // Yönetmen
                Text(
                  'Yönetmen',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  movie.director,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Türler
                Text(
                  'Türler',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: movie.genres.map((genre) {
                    return Chip(
                      label: Text(
                        genre,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.blue.shade900,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // İnceleme
                if (_movieDetails.containsKey('review') && _movieDetails['review'] != null) ...[
                  Text(
                    'İnceleme',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Text(
                      _movieDetails['review'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Özet göster
                Text(
                  'Özet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.overview,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Favori butonu
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => viewModel.toggleFavorite(movie),
                  icon: Icon(
                    movie.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    color: Colors.white,
                  ),
                  label: Text(
                    movie.isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
        
        // Geri butonu (Yeniden tasarlanmış)
        Positioned(
          left: 16,
          top: 5,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () {
                setState(() {
                  _showDetails = false;
                });
                _detailsPageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Geri',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
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
  }
  
  Widget _buildRatingSection(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 22,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Film kartı için Shimmer efekti widget'ı
  Widget _buildMovieCardShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Container(width: double.infinity, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Container(width: MediaQuery.of(context).size.width * 0.4, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: MediaQuery.of(context).size.width * 0.3, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Container(width: MediaQuery.of(context).size.width * 0.5, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
} 