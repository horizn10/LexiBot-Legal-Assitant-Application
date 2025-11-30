import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/number_utils.dart';
import 'bns_chapter_list_page.dart';
import 'bnss_chapter_list_page.dart';
import 'bsa_chapter_list_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  List<Map<String, dynamic>> getActs(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final strings = lang.localizedStrings;
    return [
      {
        'id': 'bns',
        'title': strings['bns_title'] ?? 'Bharatiya Nyaya Sanhita (BNS)',
        'chapters': 20,
        'sections': 358,
      },
      {
        'id': 'bnss',
        'title': strings['bnss_title'] ??
            'Bharatiya Nagarik Suraksha Sanhita (BNSS)',
        'chapters': 39,
        'sections': 531,
      },
      {
        'id': 'bsa',
        'title': strings['bsa_title'] ?? 'Bharatiya Sakshya Adhiniyam (BSA)',
        'chapters': 12,
        'sections': 170,
      },
    ];
  }

  void _onActTap(BuildContext context, String actId) {
    // Navigate to the respective chapter list page
    Widget? targetPage;
    if (actId == 'bns') {
      targetPage = const BnsChapterListPage();
    } else if (actId == 'bnss') {
      targetPage = const BnssChapterListPage();
    } else if (actId == 'bsa') {
      targetPage = const BsaChapterListPage();
    }

    if (targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetPage!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final strings = lang.localizedStrings;
    final acts = getActs(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            Text(
              strings['app_name'] ?? 'LexiBot',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontFamily: 'Roboto',
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings['acts'] ?? 'ACTS',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: acts.length,
                itemBuilder: (context, index) {
                  final act = acts[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        act['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${strings['chapters'] ?? 'Chapters'}: ${convertToLocalizedNumbers(act['chapters'].toString(), lang.currentLanguage)} · ${strings['sections'] ?? 'Sections'}: ${convertToLocalizedNumbers(act['sections'].toString(), lang.currentLanguage)}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _onActTap(context, act['id']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
