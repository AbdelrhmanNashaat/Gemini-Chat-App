import '../../features/chat/data/models/chat_message_model.dart';
import 'api_service.dart';

class GeminiChatService {
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';
  final geminiApiKey = 'AIzaSyDRD4L7wsZfzWCol2F7f81mvCUgTDgpjtw';
  final ApiService apiService;
  GeminiChatService({required this.apiService});
  Future<String> generateText({
    required List<ChatMessageModel> messages,
  }) async {
    final headers = {
      'x-goog-api-key': geminiApiKey,
      'Content-Type': 'application/json',
    };

    final body = {
      'contents': messages.map((msg) {
        return {
          'role': msg.role,
          'parts': [
            {'text': msg.message},
          ],
        };
      }).toList(),
    };

    const nonRetryStatusCodes = {400, 401, 403, 404};
    const retryableStatusCodes = {408, 429, 500, 502, 503, 504};

    for (int i = 0; i < 3; i++) {
      final response = await apiService.post(
        headers: headers,
        data: body,
        baseUrl: baseUrl,
      );

      final statusCode = response['statusCode'];

      if (statusCode == 200) {
        final candidates = response['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] ?? '';
          }
        }
        return '';
      }

      if (nonRetryStatusCodes.contains(statusCode)) {
        return '';
      }
      if (retryableStatusCodes.contains(statusCode)) {
        if (i == 2) return '';
        continue;
      }
      return '';
    }
    return '';
  }
}
