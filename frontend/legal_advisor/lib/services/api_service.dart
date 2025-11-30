import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_request.dart';
import '../models/chat_response.dart';

class ApiService {
  static const String baseUrl =
    'http://192.168.43.185:8001'; // Change '192.168.x.x' to your laptop's LAN IP address
  static const String productionUrl =
      'https://your-backend-domain.com'; // For production

  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }

  // Get supported languages
  Future<List<String>> getSupportedLanguages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/langs'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['supported']);
      }
      return [];
    } catch (e) {
      print('Get languages error: $e');
      return [];
    }
  }

  // Send chat query
  Future<ChatResponse?> sendChatQuery(ChatRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ChatResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Send chat query error: $e');
      return null;
    }
  }

  // Notify backend about language change
  Future<void> changeLanguage(String langCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-language'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'language': langCode}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to change language');
      }
    } catch (e) {
      print('Change language error: $e');
      throw e;
    }
  }
}
