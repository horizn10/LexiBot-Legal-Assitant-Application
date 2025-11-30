// Improved Nepali/Hindi extraction aligned with Hindi model behavior.
// Adds Devanagari punctuation handling, robust bullet/numbered item splitting,
// and safer cleanup of mixed-language artifacts while preserving Nepali text.

class BnssData {
  final List<Chapter> chapters;

  BnssData({required this.chapters});

  factory BnssData.fromJson(Map<String, dynamic> json) {
    return BnssData(
      chapters: (json['chapters'] as List)
          .map((chapter) => Chapter.fromJson(chapter))
          .toList(),
    );
  }
}

class Chapter {
  final String chapterNumber;
  final String chapterTitle;
  final List<Section> sections;

  Chapter({
    required this.chapterNumber,
    required this.chapterTitle,
    required this.sections,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterNumber: (json['chapter_no'] ?? json['chapter'] ?? '').toString(),
      chapterTitle: _normalizeText(
          (json['chapter_title'] ?? json['title'] ?? '').toString()),
      sections: (json['sections'] as List<dynamic>?)
              ?.map((section) =>
                  Section.fromJson(section as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Section {
  final String sectionNumber;
  final String sectionTitle;
  final List<String> paragraphs;

  Section({
    required this.sectionNumber,
    required this.sectionTitle,
    required this.paragraphs,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    String content =
        (json['content'] ?? json['body'] ?? json['text'] ?? '').toString();
    content = _normalizeText(content);

    final splitRegex = RegExp(
        r'(?:(?<=\n)|^)[\s\-–•]*((?:[\(\[]?[\d\u0966-\u096F]+[\)\].])|[\-–•])\s+',
        multiLine: true);

    List<String> paragraphs = content
        .split(splitRegex)
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paragraphs.length < 2) {
      paragraphs = content
          .split(RegExp(r'\n\s*\n+'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    }

    return Section(
      sectionNumber: (json['section_no'] ?? json['section'] ?? '').toString(),
      sectionTitle: _normalizeText(
          (json['title_line'] ?? json['title'] ?? '').toString()),
      paragraphs: paragraphs,
    );
  }
}

String _normalizeText(String s) {
  s = s.replaceAll('\u00A0', ' ');
  s = s.replaceAll('\u200B', '');
  s = s.replaceAll('**', '');
  s = s.replaceAllMapped(RegExp(r'\(([^\u0900-\u097F]{2,}?)\)'), (m) => '');
  s = s.replaceAll('।', '।\n');
  s = s.replaceAll(RegExp(r'[\u2022\u2023\u25E6\u2043\u2219]'), '•');
  s = s.replaceAll(RegExp(r'[\-–—]+'), '–');
  s = s.replaceAll(RegExp(r'\s+\n'), '\n');
  s = s.replaceAll(RegExp(r'\n\s+'), '\n');
  s = s.replaceAll(RegExp(r' +'), ' ');
  s = s.replaceAllMapped(
      RegExp(r'(^|\n)\s*[\(\[]?[\d\u0966-\u096F]+[\)\].]\s*', multiLine: true),
      (match) => match.group(0)!.startsWith('\n') ? '\n' : '');
  return s.trim();
}
