import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/wiki_service.dart';
import 'services/gemini_service.dart';
import 'services/storage_service.dart';
import 'services/preload_service.dart';
import 'viewmodels/article_view_model.dart';
import 'viewmodels/favorites_view_model.dart';
import 'viewmodels/game_view_model.dart';
import 'viewmodels/movie_view_model.dart';
import 'views/screens/splash_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env dosyasını yükle
  await dotenv.load();
  
  // Tam ekran modu
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servisler
        Provider<WikiService>(
          create: (_) => WikiService(),
        ),
        Provider<GeminiService>(
          create: (_) => GeminiService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<PreloadService>(
          create: (context) => PreloadService(
            wikiService: context.read<WikiService>(),
            geminiService: context.read<GeminiService>(),
          ),
        ),
        // ViewModeller
        ChangeNotifierProvider<ArticleViewModel>(
          create: (context) => ArticleViewModel(
            wikiService: context.read<WikiService>(),
            geminiService: context.read<GeminiService>(),
            storageService: context.read<StorageService>(),
            preloadService: context.read<PreloadService>(),
          ),
        ),
        ChangeNotifierProvider<FavoritesViewModel>(
          create: (context) => FavoritesViewModel(
            storageService: context.read<StorageService>(),
          ),
        ),
        // Oyun önerileri için ViewModel
        ChangeNotifierProvider<GameViewModel>(
          create: (context) => GameViewModel(
            geminiService: context.read<GeminiService>(),
            wikiService: context.read<WikiService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        // Dizi/Film önerileri için ViewModel
        ChangeNotifierProvider<MovieViewModel>(
          create: (context) => MovieViewModel(
            geminiService: context.read<GeminiService>(),
            wikiService: context.read<WikiService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          cardTheme: CardTheme(
            elevation: 6.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
