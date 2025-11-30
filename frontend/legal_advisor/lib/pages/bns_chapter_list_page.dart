import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/number_utils.dart';
import 'bns_section_list_page.dart';

class BnsChapterListPage extends StatelessWidget {
  const BnsChapterListPage({super.key});

  List<Map<String, dynamic>> getChapters(BuildContext context) {
    final strings =
        Provider.of<LanguageProvider>(context, listen: false).localizedStrings;
    return [
      {
        'number': '1',
        'title': strings['bns_chapter_1_title'],
        'sections': '${strings['sections']} 1–3',
      },
      {
        'number': '2',
        'title': strings['bns_chapter_2_title'],
        'sections': '${strings['sections']} 4–13',
      },
      {
        'number': '3',
        'title': strings['bns_chapter_3_title'],
        'sections': '${strings['sections']} 14–44',
      },
      {
        'number': '4',
        'title': strings['bns_chapter_4_title'],
        'sections': '${strings['sections']} 45–62',
      },
      {
        'number': '5',
        'title': strings['bns_chapter_5_title'],
        'sections': '${strings['sections']} 63–99',
      },
      {
        'number': '6',
        'title': strings['bns_chapter_6_title'],
        'sections': '${strings['sections']} 100–146',
      },
      {
        'number': '7',
        'title': strings['bns_chapter_7_title'],
        'sections': '${strings['sections']} 147–158',
      },
      {
        'number': '8',
        'title': strings['bns_chapter_8_title'],
        'sections': '${strings['sections']} 159–168',
      },
      {
        'number': '9',
        'title': strings['bns_chapter_9_title'],
        'sections': '${strings['sections']} 169–177',
      },
      {
        'number': '10',
        'title': strings['bns_chapter_10_title'],
        'sections': '${strings['sections']} 178–188',
      },
      {
        'number': '11',
        'title': strings['bns_chapter_11_title'],
        'sections': '${strings['sections']} 189–197',
      },
      {
        'number': '12',
        'title': strings['bns_chapter_12_title'],
        'sections': '${strings['sections']} 198–205',
      },
      {
        'number': '13',
        'title': strings['bns_chapter_13_title'],
        'sections': '${strings['sections']} 206–226',
      },
      {
        'number': '14',
        'title': strings['bns_chapter_14_title'],
        'sections': '${strings['sections']} 227–269',
      },
      {
        'number': '15',
        'title': strings['bns_chapter_15_title'],
        'sections': '${strings['sections']} 270–297',
      },
      {
        'number': '16',
        'title': strings['bns_chapter_16_title'],
        'sections': '${strings['sections']} 298–302',
      },
      {
        'number': '17',
        'title': strings['bns_chapter_17_title'],
        'sections': '${strings['sections']} 303–334',
      },
      {
        'number': '18',
        'title': strings['bns_chapter_18_title'],
        'sections': '${strings['sections']} 335–350',
      },
      {
        'number': '19',
        'title': strings['bns_chapter_19_title'],
        'sections': '${strings['sections']} 351–357',
      },
      {
        'number': '20',
        'title': strings['bns_chapter_20_title'],
        'sections': '${strings['sections']} 358',
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
          '${strings['chapter_list']} - ${strings['bns']}',
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
              strings['bns_title'] ?? 'Bharatiya Nyaya Sanhita (BNS)',
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
                        BnsSectionListPage(chapterNumber: chapter['number']),
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
