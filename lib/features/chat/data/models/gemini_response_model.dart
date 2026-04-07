class GeminiResponseModel {
  final List<GeminiCandidateModel> candidates;

  const GeminiResponseModel({required this.candidates});

  factory GeminiResponseModel.fromJson(Map<String, dynamic> json) {
    return GeminiResponseModel(
      candidates: (json['candidates'] as List<dynamic>? ?? [])
          .map((e) => GeminiCandidateModel.fromJson(e))
          .toList(),
    );
  }

  String get text {
    if (candidates.isEmpty) return '';

    final parts = candidates.first.content.parts;
    if (parts.isEmpty) return '';

    return parts.first.text;
  }
}

class GeminiCandidateModel {
  final GeminiContentModel content;
  final String? finishReason;
  final int? index;

  const GeminiCandidateModel({
    required this.content,
    this.finishReason,
    this.index,
  });

  factory GeminiCandidateModel.fromJson(Map<String, dynamic> json) {
    return GeminiCandidateModel(
      content: GeminiContentModel.fromJson(
        json['content'] as Map<String, dynamic>? ?? {},
      ),
      finishReason: json['finishReason'],
      index: json['index'],
    );
  }
}

class GeminiContentModel {
  final List<GeminiPartModel> parts;
  final String? role;

  const GeminiContentModel({required this.parts, this.role});

  factory GeminiContentModel.fromJson(Map<String, dynamic> json) {
    return GeminiContentModel(
      role: json['role'],
      parts: (json['parts'] as List<dynamic>? ?? [])
          .map((e) => GeminiPartModel.fromJson(e))
          .toList(),
    );
  }
}

class GeminiPartModel {
  final String text;

  const GeminiPartModel({required this.text});

  factory GeminiPartModel.fromJson(Map<String, dynamic> json) {
    return GeminiPartModel(text: json['text'] ?? '');
  }
}
