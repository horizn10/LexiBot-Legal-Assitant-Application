import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/custom_button.dart';

class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final strings = lang.localizedStrings;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(strings['app_name'] ?? 'LexiBot'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomButton(
                label: strings['view_sections'] ?? 'View Sections',
                icon: Icons.view_list_rounded,
                onPressed: () {
                  
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: strings['ask_chatbot'] ?? 'Ask Chatbot',
                icon: Icons.chat_bubble_rounded,
                onPressed: () {
                  
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: strings['find_laws'] ?? 'Find Laws',
                icon: Icons.gavel_rounded,
                onPressed: () {
                  
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
