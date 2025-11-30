import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Language',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListView(
            shrinkWrap: true,
            children: [
              _buildLanguageOption(context, 'en', 'English', 'English', languageProvider),
              _buildLanguageOption(context, 'hi', 'हिन्दी', 'Hindi', languageProvider),
              _buildLanguageOption(context, 'ne', 'नेपाली', 'Nepali', languageProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String code, String nativeName, String englishName, LanguageProvider languageProvider) {
    final isSelected = languageProvider.currentLanguage == code;
    return ListTile(
      title: Text(nativeName, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(englishName),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        languageProvider.changeLanguage(code);
        Navigator.of(context).pop();
      },
    );
  }
}
