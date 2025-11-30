import 'package:flutter/material.dart';
import 'widgets/custom_button.dart';
import 'widgets/custom_card.dart';

/// Root app with Material 3 theme and clean, minimal styling.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.blue; // Primary accent color
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Legal Advisor',
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
      home: const HomePage(),
    );
  }
}

/// Main home page with AppBar, welcome section, and action cards.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _lang = 'en';

  @override
  void initState() {
    super.initState();
  }

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Advisor'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language_rounded),
            tooltip: 'Language',
            onSelected: (v) => setState(() => _lang = v),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'hi', child: Text('हिंदी')),
              PopupMenuItem(value: 'ne', child: Text('नेपाली')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Welcome to Legal Advisor (lang: $_lang)',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find laws, browse sections, or chat with our assistant.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Optional quick action buttons (reusable widget example)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      CustomButton(
                        label: 'Get Started',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => _notify(context, 'Get Started'),
                      ),
                      CustomButton(
                        label: 'Ask Chatbot',
                        icon: Icons.chat_bubble_rounded,
                        onPressed: () => _notify(context, 'Ask Chatbot'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Responsive grid of action cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      if (constraints.maxWidth >= 900) {
                        crossAxisCount = 3;
                      } else if (constraints.maxWidth >= 600) {
                        crossAxisCount = 2;
                      }
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          CustomCard(
                            title: 'Search Laws',
                            subtitle:
                                'Find acts, rules and regulations quickly.',
                            icon: Icons.search_rounded,
                            onTap: () => _notify(context, 'Search Laws'),
                          ),
                          CustomCard(
                            title: 'Ask Chatbot',
                            subtitle: 'Get quick answers powered by AI.',
                            icon: Icons.smart_toy_rounded,
                            onTap: () => _notify(context, 'Ask Chatbot'),
                          ),
                          CustomCard(
                            title: 'View Sections',
                            subtitle: 'Browse sections and summaries.',
                            icon: Icons.article_rounded,
                            onTap: () => _notify(context, 'View Sections'),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
