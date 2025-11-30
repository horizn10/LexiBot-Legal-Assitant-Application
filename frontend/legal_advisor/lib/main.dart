import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/splash_page.dart';
import 'pages/home_page.dart';
import 'pages/main_menu_page.dart';
import 'pages/language_page.dart';
import 'pages/chatbot_page_new.dart';
import 'pages/settings_page.dart';
import 'providers/language_provider.dart';
import 'widgets/bottom_nav_bar.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    const seed = Colors.blue; // Placeholder, can be replaced with extracted colors

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LexiBot',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0.5),
        cardTheme: CardTheme(
          elevation: 2,
          margin: const EdgeInsets.all(0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const SplashPage(),
      routes: {
        '/main': (context) => const MainApp(),
        '/home': (context) => const HomePage(),
        '/main_menu': (context) => const MainMenuPage(),
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const LanguagePage(),
    const ChatbotPageNew(),
    const SettingsPage(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
