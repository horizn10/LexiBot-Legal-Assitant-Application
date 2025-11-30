import 'package:flutter/material.dart';
import '../l10n/en.dart' as en;
import '../l10n/hi.dart' as hi;
import '../l10n/ne.dart' as ne;
import '../services/api_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  Map<String, String> _localizedStrings = en.localizedStrings;
  Map<String, String> get localizedStrings => _localizedStrings;

  final ApiService _apiService = ApiService();

  void changeLanguage(String langCode) async {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      switch (langCode) {
        case 'hi':
          _localizedStrings = hi.localizedStrings;
          break;
        case 'ne':
          _localizedStrings = ne.localizedStrings;
          break;
        case 'en':
        default:
          _localizedStrings = en.localizedStrings;
          break;
      }
      notifyListeners();

      // Notify backend about language change
      try {
        await _apiService.changeLanguage(langCode);
      } catch (e) {
        // Handle error if needed
        debugPrint('Failed to notify backend of language change: $e');
      }
    }
  }

  String getString(String key) {
    return _localizedStrings[key] ?? key;
  }
}
