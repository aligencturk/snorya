import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/wiki_service.dart';
import 'services/gemini_service.dart';
import 'services/storage_service.dart';
import 'viewmodels/article_view_model.dart';
import 'viewmodels/favorites_view_model.dart';
import 'views/screens/home_screen.dart';
import 'utils/constants.dart';

void main() {
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
        // ViewModeller
        ChangeNotifierProvider<ArticleViewModel>(
          create: (context) => ArticleViewModel(
            wikiService: context.read<WikiService>(),
            geminiService: context.read<GeminiService>(),
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
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
