import 'package:chat_bot_gemini/core/errors/failures.dart';
import '../../features/chat/data/models/chat_message_model.dart';
import 'api_service.dart';

class GeminiChatService {
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  final String _geminiApiKey = 'YOUR_API_KEY';
  final ApiService apiService;

  GeminiChatService({required this.apiService});

  Future<String> generateText({
    required List<ChatMessageModel> messages,
  }) async {
    return ServerFailure.withRetry(() => _callApi(messages));
  }

  Future<String> _callApi(List<ChatMessageModel> messages) async {
    final response = await apiService.post(
      baseUrl: _baseUrl,
      headers: {
        'x-goog-api-key': _geminiApiKey,
        'Content-Type': 'application/json',
      },
      data: {
        'contents': messages
            .map(
              (m) => {
                'role': m.role,
                'parts': [
                  {'text': m.message},
                ],
              },
            )
            .toList(),
      },
    );

    final candidates = response['candidates'] as List?;
    final parts = candidates?.firstOrNull?['content']?['parts'] as List?;
    return parts?.firstOrNull?['text'] ?? '';
  }
}
