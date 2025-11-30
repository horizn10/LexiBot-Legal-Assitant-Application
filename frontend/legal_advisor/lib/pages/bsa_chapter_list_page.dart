import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/number_utils.dart';
import 'bsa_section_list_page.dart';

class BsaChapterListPage extends StatelessWidget {
  const BsaChapterListPage({super.key});

  List<Map<String, dynamic>> getChapters(BuildContext context) {
    final strings =
        Provider.of<LanguageProvider>(context, listen: false).localizedStrings;
    return [
      {
        'number': '1',
        'title': strings['bsa_chapter_1_title'],
        'sections': '${strings['sections']} 1 to 2',
      },
      {
        'number': '2',
        'title': strings['bsa_chapter_2_title'],
        'sections': '${strings['sections']} 3 to 50',
      },
      {
        'number': '3',
        'title': strings['bsa_chapter_3_title'],
        'sections': '${strings['sections']} 51 to 53',
      },
      {
        'number': '4',
        'title': strings['bsa_chapter_4_title'],
        'sections': '${strings['sections']} 54 to 55',
      },
      {
        'number': '5',
        'title': strings['bsa_chapter_5_title'],
        'sections': '${strings['sections']} 56 to 93',
      },
      {
        'number': '6',
        'title': strings['bsa_chapter_6_title'],
        'sections': '${strings['sections']} 94 to 103',
      },
      {
        'number': '7',
        'title': strings['bsa_chapter_7_title'],
        'sections': '${strings['sections']} 104 to 120',
      },
      {
        'number': '8',
        'title': strings['bsa_chapter_8_title'],
        'sections': '${strings['sections']} 121 to 123',
      },
      {
        'number': '9',
        'title': strings['bsa_chapter_9_title'],
        'sections': '${strings['sections']} 124 to 139',
      },
      {
        'number': '10',
        'title': strings['bsa_chapter_10_title'],
        'sections': '${strings['sections']} 140 to 168',
      },
      {
        'number': '11',
        'title': strings['bsa_chapter_11_title'],
        'sections': '${strings['sections']} 169 to 169',
      },
      {
        'number': '12',
        'title': strings['bsa_chapter_12_title'],
        'sections': '${strings['sections']} 170 to 170',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final strings = lang.localizedStrings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${strings['chapter_list']} - ${strings['bsa']}',
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
              strings['bsa_title'] ?? 'Bharatiya Sakshya Adhiniyam (BSA)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: getChapters(context).length,
        itemBuilder: (context, index) {
          final chapter = getChapters(context)[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  convertToLocalizedNumbers(
                      chapter['number'], lang.currentLanguage),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                chapter['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(convertToLocalizedNumbers(
                  chapter['sections'], lang.currentLanguage)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BsaSectionListPage(chapterNumber: chapter['number']),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
