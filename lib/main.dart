import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'data/word_bank.dart';
import 'screens/home_screen.dart';
import 'services/word_lite_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WordBank.loadEmbeddedPacks();
  final WordLiteRepository repo = WordLiteRepository();
  await repo.init();
  runApp(WordLiteApp(repository: repo));
}

class WordLiteApp extends StatelessWidget {
  const WordLiteApp({super.key, required this.repository});

  final WordLiteRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WordLiteRepository>.value(
      value: repository,
      child: Consumer<WordLiteRepository>(
        builder: (BuildContext context, WordLiteRepository r, _) {
          return MaterialApp(
            title: 'WordLite',
            theme: buildWordLiteTheme(r.stats.unlockedSkinLevel),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
