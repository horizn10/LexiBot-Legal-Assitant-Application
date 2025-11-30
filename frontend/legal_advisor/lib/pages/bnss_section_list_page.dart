import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/bnss_model.dart';
import '../../providers/language_provider.dart';
import '../../utils/number_utils.dart';

class BnssSectionListPage extends StatefulWidget {
  final String chapterNumber;
  final String? sectionNumber;

  const BnssSectionListPage(
      {super.key, required this.chapterNumber, this.sectionNumber});

  @override
  _BnssSectionListPageState createState() => _BnssSectionListPageState();
}

class _BnssSectionListPageState extends State<BnssSectionListPage> {
  BnssData? bnssData;
  String? errorMessage;
  late LanguageProvider _langProvider;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey targetCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _langProvider = Provider.of<LanguageProvider>(context, listen: false);
    _langProvider.addListener(_reloadData);
    loadData();
  }

  @override
  void dispose() {
    _langProvider.removeListener(_reloadData);
    _scrollController.dispose();
    super.dispose();
  }

  void _reloadData() {
    setState(() {
      bnssData = null;
      errorMessage = null;
    });
    loadData();
  }

  Future<void> loadData() async {
    try {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      String jsonFile = 'Dataset/BNSS_master.json';
      if (lang.currentLanguage == 'hi') {
        jsonFile = 'Dataset/BNSS_master_hindi.json';
      } else if (lang.currentLanguage == 'ne') {
        jsonFile = 'Dataset/BNSS_master_nepali.json';
      }
      final String jsonString = await rootBundle.loadString(jsonFile);
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        bnssData = BnssData.fromJson({'chapters': jsonData});
        errorMessage = null;
      });
      // Scroll to the target section after data is loaded
      if (widget.sectionNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTarget();
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data: $e';
        bnssData = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  void _scrollToTarget() {
    Future.delayed(const Duration(milliseconds: 100), () {
      final ctx = targetCardKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final strings = lang.localizedStrings;

    if (bnssData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${strings['section_list']} - ${strings['bnss']} ${strings['chapter']} ${convertToLocalizedNumbers(widget.chapterNumber, lang.currentLanguage)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
        ),
        body: errorMessage != null
            ? Center(child: Text(errorMessage!))
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final chapter = bnssData!.chapters.firstWhere(
      (ch) => ch.chapterNumber == widget.chapterNumber,
      orElse: () =>
          Chapter(chapterNumber: '', chapterTitle: 'Not Found', sections: []),
    );

    final targetSectionIndex = widget.sectionNumber != null
        ? chapter.sections
            .indexWhere((s) => s.sectionNumber == widget.sectionNumber)
        : -1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${strings['section_list']} - ${strings['bnss']} ${strings['chapter']} ${convertToLocalizedNumbers(widget.chapterNumber, lang.currentLanguage)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              chapter.chapterTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: chapter.sections.length,
        itemBuilder: (context, index) {
          final section = chapter.sections[index];
          return Card(
            key: index == targetSectionIndex ? targetCardKey : null,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              initiallyExpanded: index == targetSectionIndex,
              title: Text(
                '${strings['section']} ${convertToLocalizedNumbers(section.sectionNumber, lang.currentLanguage)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              childrenPadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.sectionTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      ...section.paragraphs
                          .map((paragraph) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  paragraph,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
