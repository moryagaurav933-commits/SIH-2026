import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'providers/weather_provider.dart';
import 'screens/home_screen.dart';

class KrishiSaarthiApp extends StatelessWidget {
  const KrishiSaarthiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'कृषि-सारथी | Krishi-Saarthi',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            themeMode: ThemeMode.light,
            home: const HomeScreen(),
            // Localization
            locale: languageProvider.locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('hi', 'IN'),
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), // Deep Green primary
        primary: const Color(0xFF2E7D32),
        secondary: const Color(0xFF1B5E20), // Darker forest green
        tertiary: const Color(0xFFFFC107), // Yellow accent
        surface: const Color(0xFFFFFFFF),
        error: const Color(0xFFD32F2F), // Red accent
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F9F5), // Soft green-white
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFFF5F9F5),
        foregroundColor: Color(0xFF1B5E20),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE0E8E0)),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF2E7D32),
        unselectedItemColor: Color(0xFF6B8F6B),
        elevation: 8,
      ),
    );
  }
}
