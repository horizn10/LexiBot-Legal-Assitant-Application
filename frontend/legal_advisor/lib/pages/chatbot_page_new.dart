import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../models/chat_request.dart';
import '../models/chat_response.dart';
import '../models/bns_model.dart' as bns_model;
import '../models/bnss_model.dart' as bnss_model;
import '../models/bsa_model.dart' as bsa_model;
import '../services/api_service.dart';
import '../providers/language_provider.dart';
import 'bns_section_list_page.dart';
import 'bsa_section_list_page.dart';
import 'bnss_section_list_page.dart';

class ChatbotPageNew extends StatefulWidget {
  const ChatbotPageNew({Key? key}) : super(key: key);

  @override
  _ChatbotPageNewState createState() => _ChatbotPageNewState();
}

class _ChatbotPageNewState extends State<ChatbotPageNew> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<_ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Speech to text variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _speechText = '';
  bool _isFromSpeech = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller.addListener(_capitalizeFirstLetter);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _capitalizeFirstLetter() {
    // Skip capitalization if text is coming from speech recognition
    if (_isFromSpeech) {
      _isFromSpeech = false;
      return;
    }

    final text = _controller.text;
    if (text.isNotEmpty &&
        text.length == 1 &&
        text[0].toLowerCase() == text[0]) {
      final capitalized = text[0].toUpperCase() + text.substring(1);
      _controller.value = TextEditingValue(
        text: capitalized,
        selection: TextSelection.collapsed(offset: capitalized.length),
      );
    }
  }

  void _listen() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final strings = lang.localizedStrings;

    // Request microphone permission
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(strings['microphone_permission'] ??
                'Microphone permission is required for voice input')),
      );
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Speech recognition error: ${val.errorMsg ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            final recognizedText = val.recognizedWords ?? '';
            print('Recognized text: $recognizedText');
            if (recognizedText.isNotEmpty) {
              setState(() {
                _isFromSpeech = true;
                _speechText = recognizedText;
                _controller.text = _speechText;
              });
            }
          },
          localeId: 'en-US', // Fixed locale for Windows compatibility
          listenFor: const Duration(seconds: 30), // Increase listen duration
          pauseFor: const Duration(seconds: 10), // Allow pause before stopping
          partialResults:
              false, // Disable partial results to avoid Windows plugin issues
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  String _getTranslatedLabel(String key, String language) {
    final translations = {
      'en': {
        'references': 'References:',
        'penalties': 'Penalties:',
        'disclaimer': 'Disclaimer:',
        'source_code': 'Source Code:',
        'source_name': 'Source Name:',
        'answer': 'Answer:',
        'context': 'Context:',
      },
      'hi': {
        'references': 'संदर्भ:',
        'penalties': 'दंड:',
        'disclaimer': 'अस्वीकरण:',
        'source_code': 'स्रोत कोड:',
        'source_name': 'स्रोत नाम:',
        'answer': 'उत्तर:',
        'context': 'संदर्भ:',
      },
      'ne': {
        'references': 'संदर्भहरू:',
        'penalties': 'दण्डहरू:',
        'disclaimer': 'अस्वीकरण:',
        'source_code': 'स्रोत कोड:',
        'source_name': 'स्रोत नाम:',
        'answer': 'उत्तर:',
        'context': 'संदर्भ:',
      },
    };
    return translations[language]?[key] ?? translations['en']![key]!;
  }

  List<Widget> _buildExplanationSections(ChatResponse response) {
    final explanation = response.explanation;
    final language = response.language;

    // Parse the explanation to separate sections based on new format
    final parts = explanation.split('\n\n');
    final widgets = <Widget>[];

    for (final part in parts) {
      if (part.contains('Based on') && part.contains(',')) {
        // This is the main answer section
        final colonIndex = part.indexOf(':');
        final answerText =
            colonIndex != -1 ? part.substring(colonIndex + 1).trim() : part;
        widgets.addAll([
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Legal Answer',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  (language == 'hi' || language == 'ne')
                      ? answerText.replaceAll('**', '')
                      : answerText,
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ]);
      } else if (part.startsWith('For complete context') ||
          part.contains('legal provision')) {
        // This is the legal provision section
        final provisionText =
            part.contains(':') ? part.split(':').last.trim() : part;
        widgets.addAll([
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.article,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Legal Provision',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  (language == 'hi' || language == 'ne')
                      ? provisionText.replaceAll('**', '')
                      : provisionText,
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ]);
      } else if (part.startsWith('According to') ||
          part.startsWith('Based on the legal provisions')) {
        // This is a fallback response - display as a general legal information section
        final infoText = part;
        widgets.addAll([
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Legal Information',
                      style: TextStyle(
                        fontFamily: 'NotoSans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  (language == 'hi' || language == 'ne')
                      ? infoText.replaceAll('**', '')
                      : infoText,
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ]);
      } else {
        // Fallback for any other content
        widgets.add(
          SelectableText(
            (language == 'hi' || language == 'ne')
                ? part.replaceAll('**', '')
                : part,
            style: const TextStyle(
              fontFamily: 'NotoSansDevanagari',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Future<void> _sendMessage() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current language from provider
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      final currentLanguage = languageProvider.currentLanguage;

      final request = ChatRequest(query: query, language: currentLanguage);
      final response = await _apiService.sendChatQuery(request);

      setState(() {
        _isLoading = false;
        if (response != null) {
          _messages
              .add(_ChatMessage(userMessage: query, botResponse: response));
        } else {
          // Show error message if response is null
          final lang = Provider.of<LanguageProvider>(context, listen: false);
          final strings = lang.localizedStrings;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings['failed_response'] ??
                  'Failed to get response. Please check your connection and try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _controller.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      final strings = lang.localizedStrings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${strings['error'] ?? 'Error:'} ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _buildUserMessage(String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBotMessage(ChatResponse response) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gavel,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          response.title,
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (response.sourceName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      response.sourceName,
                      style: TextStyle(
                        fontFamily: 'NotoSansDevanagari',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Parse and display Answer and Context sections
            ..._buildExplanationSections(response),
            if (response.penalties.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _getTranslatedLabel('penalties', response.language),
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              for (var p in response.penalties)
                Text(
                  '- $p',
                  style: const TextStyle(
                    fontFamily: 'NotoSansDevanagari',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
            ],
            if (response.references.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.library_books,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTranslatedLabel('references', response.language),
                          style: TextStyle(
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...response.references.take(3).map((r) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _navigateToSection(r),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.title,
                                            style: TextStyle(
                                              fontFamily: 'NotoSansDevanagari',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Section ${r.section} • ${r.sourceName}',
                                            style: TextStyle(
                                              fontFamily: 'NotoSansDevanagari',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Score: ${r.score.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontFamily: 'NotoSans',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
            if (response.disclaimer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _getTranslatedLabel('disclaimer', response.language),
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                response.disclaimer,
                style: const TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
            if (response.sourceCode.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_getTranslatedLabel('source_code', response.language)} ${response.sourceCode}',
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
            if (response.sourceName.isNotEmpty) ...[
              Text(
                '${_getTranslatedLabel('source_name', response.language)} ${response.sourceName}',
                style: const TextStyle(
                  fontFamily: 'NotoSansDevanagari',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLawCodeFromSource(String? source) {
    if (source == null) return 'Unknown';
    if (source.contains('BNS')) return 'BNS';
    if (source.contains('BNSS')) return 'BNSS';
    if (source.contains('BSA')) return 'BSA';
    return 'Other';
  }

  Future<String?> _findChapterForSection(Reference reference) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.currentLanguage;

    String jsonFile;
    if (reference.source == 'BNS') {
      jsonFile = currentLanguage == 'hi'
          ? 'Dataset/BNS_master_hindi.json'
          : currentLanguage == 'ne'
              ? 'Dataset/BNS_master_nepali.json'
              : 'Dataset/BNS_master.json';
    } else if (reference.source == 'BNSS') {
      jsonFile = currentLanguage == 'hi'
          ? 'Dataset/BNSS_master_hindi.json'
          : currentLanguage == 'ne'
              ? 'Dataset/BNSS_master_nepali.json'
              : 'Dataset/BNSS_master.json';
    } else if (reference.source == 'BSA') {
      jsonFile = currentLanguage == 'hi'
          ? 'Dataset/BSA_master_hindi.json'
          : currentLanguage == 'ne'
              ? 'Dataset/BSA_master_nepali.json'
              : 'Dataset/BSA_master.json';
    } else {
      return null; // Unknown source
    }

    try {
      final String jsonString = await rootBundle.loadString(jsonFile);
      final List<dynamic> jsonData = json.decode(jsonString);

      for (var chapterJson in jsonData) {
        final chapter = bns_model.Chapter.fromJson(chapterJson);
        if (chapter.sections.any((s) => s.sectionNumber == reference.section)) {
          return chapter.chapterNumber;
        }
      }
    } catch (e) {
      print('Error loading data for chapter lookup: $e');
    }
    return null;
  }

  Future<void> _navigateToSection(Reference reference) async {
    // Debug print to check reference data
    print(
        'Navigating to section: ${reference.section}, chapter: ${reference.chapter}, source: ${reference.source}, id: ${reference.id}');

    // Use chapter from reference if available, otherwise find it
    String chapterNumber = reference.chapter;
    if (chapterNumber.isEmpty) {
      chapterNumber = await _findChapterForSection(reference) ?? '';
      if (chapterNumber.isEmpty) {
        print('Could not find chapter for section: ${reference.section}');
        final lang = Provider.of<LanguageProvider>(context, listen: false);
        final strings = lang.localizedStrings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings['chapter_not_found'] ??
                'Unable to find chapter for section ${reference.section}.'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
    }

    final sectionNumber = reference.section;
    if (sectionNumber.isEmpty) {
      print('Section number is empty');
      return;
    }

    print(
        'Final navigation: chapter $chapterNumber, section $sectionNumber, source ${reference.source}');

    Widget page;
    if (reference.source == 'BNS') {
      page = BnsSectionListPage(
          chapterNumber: chapterNumber, sectionNumber: sectionNumber);
    } else if (reference.source == 'BSA') {
      page = BsaSectionListPage(
          chapterNumber: chapterNumber, sectionNumber: sectionNumber);
    } else if (reference.source == 'BNSS') {
      page = BnssSectionListPage(
          chapterNumber: chapterNumber, sectionNumber: sectionNumber);
    } else {
      print('Unknown source: ${reference.source}');
      return; // Unknown source
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _navigateWithSectionOnly(Reference reference) {
    // Try to navigate to section list page without chapter
    // This is a fallback for cases where chapter info is missing
    print('Attempting navigation with section only: ${reference.section}');

    // For now, we'll show a message that navigation requires chapter info
    // In a real implementation, you might have a section-only page or search functionality
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final strings = lang.localizedStrings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings['navigation_requires_chapter'] ??
            'Navigation to section ${reference.section} requires chapter information. Please try a different reference.'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final strings = lang.localizedStrings;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings['chatbot_title'] ?? 'Legal Assistant Chatbot',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings['ask_legal_question'] ??
                              'Ask a legal question...',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final chatMessage = _messages[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildUserMessage(chatMessage.userMessage),
                          _buildBotMessage(chatMessage.botResponse),
                        ],
                      );
                    },
                  ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: strings['type_question'] ??
                          'Type your question here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _listen,
                  style: IconButton.styleFrom(
                    backgroundColor: _isListening
                        ? Colors.red
                        : Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String userMessage;
  final ChatResponse botResponse;

  _ChatMessage({required this.userMessage, required this.botResponse});
}
