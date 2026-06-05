import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'providers/match_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/callbreak/callbreak_game_screen.dart';
import 'screens/callbreak/callbreak_setup_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/history/match_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/marriage/marriage_game_screen.dart';
import 'screens/marriage/marriage_setup_screen.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.deleteMatchesOlderThan30Days();

  final themeProvider = ThemeProvider();
  await themeProvider.loadThemeMode();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => MatchProvider()),
      ],
      child: const CardScoreTrackerApp(),
    ),
  );
}

class CardScoreTrackerApp extends StatelessWidget {
  const CardScoreTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.callbreakSetup: (_) => const CallBreakSetupScreen(),
        AppRoutes.callbreakGame: (_) => const CallBreakGameScreen(),
        AppRoutes.marriageSetup: (_) => const MarriageSetupScreen(),
        AppRoutes.marriageGame: (_) => const MarriageGameScreen(),
        AppRoutes.history: (_) => const HistoryScreen(),
        AppRoutes.historyDetail: (_) => const MatchDetailScreen(),

      },
    );
  }
}
