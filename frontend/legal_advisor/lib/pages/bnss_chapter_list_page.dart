import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/number_utils.dart';
import 'bnss_section_list_page.dart';

class BnssChapterListPage extends StatelessWidget {
  const BnssChapterListPage({super.key});

  List<Map<String, dynamic>> getChapters(BuildContext context) {
    final strings =
        Provider.of<LanguageProvider>(context, listen: false).localizedStrings;
    return [
      {
        'number': '1',
        'title': strings['bnss_chapter_1_title'],
        'sections': '${strings['sections']} 1–5',
      },
      {
        'number': '2',
        'title': strings['bnss_chapter_2_title'],
        'sections': '${strings['sections']} 6–20',
      },
      {
        'number': '3',
        'title': strings['bnss_chapter_3_title'],
        'sections': '${strings['sections']} 21–29',
      },
      {
        'number': '4',
        'title': strings['bnss_chapter_4_title'],
        'sections': '${strings['sections']} 30–34',
      },
      {
        'number': '5',
        'title': strings['bnss_chapter_5_title'],
        'sections': '${strings['sections']} 35–62',
      },
      {
        'number': '6',
        'title': strings['bnss_chapter_6_title'],
        'sections': '${strings['sections']} 63–93',
      },
      {
        'number': '7',
        'title': strings['bnss_chapter_7_title'],
        'sections': '${strings['sections']} 94–110',
      },
      {
        'number': '8',
        'title': strings['bnss_chapter_8_title'],
        'sections': '${strings['sections']} 111–124',
      },
      {
        'number': '9',
        'title': strings['bnss_chapter_9_title'],
        'sections': '${strings['sections']} 125–143',
      },
      {
        'number': '10',
        'title': strings['bnss_chapter_10_title'],
        'sections': '${strings['sections']} 144–147',
      },
      {
        'number': '11',
        'title': strings['bnss_chapter_11_title'],
        'sections': '${strings['sections']} 148–167',
      },
      {
        'number': '12',
        'title': strings['bnss_chapter_12_title'],
        'sections': '${strings['sections']} 168–172',
      },
      {
        'number': '13',
        'title': strings['bnss_chapter_13_title'],
        'sections': '${strings['sections']} 173–196',
      },
      {
        'number': '14',
        'title': strings['bnss_chapter_14_title'],
        'sections': '${strings['sections']} 197–209',
      },
      {
        'number': '15',
        'title': strings['bnss_chapter_15_title'],
        'sections': '${strings['sections']} 210–222',
      },
      {
        'number': '16',
        'title': strings['bnss_chapter_16_title'],
        'sections': '${strings['sections']} 223–226',
      },
      {
        'number': '17',
        'title': strings['bnss_chapter_17_title'],
        'sections': '${strings['sections']} 227–233',
      },
      {
        'number': '18',
        'title': strings['bnss_chapter_18_title'],
        'sections': '${strings['sections']} 234–247',
      },
      {
        'number': '19',
        'title': strings['bnss_chapter_19_title'],
        'sections': '${strings['sections']} 248–260',
      },
      {
        'number': '20',
        'title': strings['bnss_chapter_20_title'],
        'sections': '${strings['sections']} 261–273',
      },
      {
        'number': '21',
        'title': strings['bnss_chapter_21_title'],
        'sections': '${strings['sections']} 274–282',
      },
      {
        'number': '22',
        'title': strings['bnss_chapter_22_title'],
        'sections': '${strings['sections']} 283–288',
      },
      {
        'number': '23',
        'title': strings['bnss_chapter_23_title'],
        'sections': '${strings['sections']} 289–300',
      },
      {
        'number': '24',
        'title': strings['bnss_chapter_24_title'],
        'sections': '${strings['sections']} 301–306',
      },
      {
        'number': '25',
        'title': strings['bnss_chapter_25_title'],
        'sections': '${strings['sections']} 307–336',
      },
      {
        'number': '26',
        'title': strings['bnss_chapter_26_title'],
        'sections': '${strings['sections']} 337–366',
      },
      {
        'number': '27',
        'title': strings['bnss_chapter_27_title'],
        'sections': '${strings['sections']} 367–378',
      },
      {
        'number': '28',
        'title': strings['bnss_chapter_28_title'],
        'sections': '${strings['sections']} 379–391',
      },
      {
        'number': '29',
        'title': strings['bnss_chapter_29_title'],
        'sections': '${strings['sections']} 392–406',
      },
      {
        'number': '30',
        'title': strings['bnss_chapter_30_title'],
        'sections': '${strings['sections']} 407–412',
      },
      {
        'number': '31',
        'title': strings['bnss_chapter_31_title'],
        'sections': '${strings['sections']} 413–435',
      },
      {
        'number': '32',
        'title': strings['bnss_chapter_32_title'],
        'sections': '${strings['sections']} 436–445',
      },
      {
        'number': '33',
        'title': strings['bnss_chapter_33_title'],
        'sections': '${strings['sections']} 446–452',
      },
      {
        'number': '34',
        'title': strings['bnss_chapter_34_title'],
        'sections': '${strings['sections']} 453–477',
      },
      {
        'number': '35',
        'title': strings['bnss_chapter_35_title'],
        'sections': '${strings['sections']} 478–496',
      },
      {
        'number': '36',
        'title': strings['bnss_chapter_36_title'],
        'sections': '${strings['sections']} 497–505',
      },
      {
        'number': '37',
        'title': strings['bnss_chapter_37_title'],
        'sections': '${strings['sections']} 506–512',
      },
      {
        'number': '38',
        'title': strings['bnss_chapter_38_title'],
        'sections': '${strings['sections']} 513–519',
      },
      {
        'number': '39',
        'title': strings['bnss_chapter_39_title'],
        'sections': '${strings['sections']} 520–531',
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
          '${strings['chapter_list']} - ${strings['bnss']}',
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
              strings['bnss_title'] ??
                  'Bharatiya Nagarik Suraksha Sanhita (BNSS)',
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
                        BnssSectionListPage(chapterNumber: chapter['number']),
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
