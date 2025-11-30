class ChatResponse {
  final String language;
  final String title;
  final String explanation;
  final List<String> penalties;
  final List<Reference> references;
  final String disclaimer;
  final String sourceCode;
  final String sourceName;

  ChatResponse({
    required this.language,
    required this.title,
    required this.explanation,
    required this.penalties,
    required this.references,
    required this.disclaimer,
    required this.sourceCode,
    required this.sourceName,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      language: json['language'] ?? '',
      title: json['title'] ?? '',
      explanation: json['explanation'] ?? '',
      penalties: List<String>.from(
          (json['penalties'] ?? []).map((p) => _capitalizeFirst(p.toString()))),
      references: (json['references'] as List<dynamic>?)
              ?.map((ref) => Reference.fromJson(ref))
              .toList() ??
          [],
      disclaimer: json['disclaimer'] ?? '',
      sourceCode: json['source_code'] ?? '',
      sourceName: json['source_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'title': title,
      'explanation': explanation,
      'penalties': penalties,
      'references': references.map((ref) => ref.toJson()).toList(),
      'disclaimer': disclaimer,
      'source_code': sourceCode,
      'source_name': sourceName,
    };
  }
}

class Reference {
  final String id;
  final String title;
  final String section;
  final String source;
  final String sourceName;
  final String type;
  final double score;
  final String chapter;

  Reference({
    required this.id,
    required this.title,
    required this.section,
    required this.source,
    required this.sourceName,
    required this.type,
    required this.score,
    required this.chapter,
  });

  factory Reference.fromJson(Map<String, dynamic> json) {
    return Reference(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      section: json['section'] ?? '',
      source: json['source'] ?? '',
      sourceName: json['source_name'] ?? '',
      type: json['type'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      chapter: json['chapter'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'section': section,
      'source': source,
      'source_name': sourceName,
      'type': type,
      'score': score,
      'chapter': chapter,
    };
  }
}

String _capitalizeFirst(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
