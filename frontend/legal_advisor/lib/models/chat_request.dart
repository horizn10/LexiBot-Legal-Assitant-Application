class ChatRequest {
  final String query;
  final String language;

  ChatRequest({
    required this.query,
    required this.language,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'language': language,
    };
  }

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      query: json['query'],
      language: json['language'],
    );
  }
}
