import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/wiki_service.dart';
import 'services/python_summary_service.dart';
import 'services/pure_python_summary_service.dart';
import 'services/storage_service.dart';
import 'services/preload_service.dart';
import 'viewmodels/article_view_model.dart';
import 'viewmodels/favorites_view_model.dart';
import 'views/screens/splash_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();
  
  // Tam ekran modu
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  
  // Python servisi başlatma talimatlarını göster
  print('🐍 SNORYA - PYTHON SERVİSİ MODU');
  print('================================');
  print(PurePythonSummaryService.getStartupInstructions());
  
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
        Provider<PythonSummaryService>(
          create: (_) => PythonSummaryService(),
        ),
        // SADECE PYTHON SERVİSİ - GEMİNİ FALLBACK YOK
        Provider<PurePythonSummaryService>(
          create: (_) => PurePythonSummaryService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<PreloadService>(
          create: (context) => PreloadService(
            wikiService: context.read<WikiService>(),
            // Hybrid yerine pure python servisi kullan
            purePythonSummaryService: context.read<PurePythonSummaryService>(),
          ),
        ),
        // ViewModeller
        ChangeNotifierProvider<ArticleViewModel>(
          create: (context) => ArticleViewModel(
            wikiService: context.read<WikiService>(),
            // Hybrid yerine pure python servisi kullan
            purePythonSummaryService: context.read<PurePythonSummaryService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider<FavoritesViewModel>(
          create: (context) => FavoritesViewModel(
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
