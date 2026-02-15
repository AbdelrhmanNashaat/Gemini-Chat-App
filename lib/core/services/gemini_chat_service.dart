import '../../features/chat/data/models/chat_message_model.dart';
import 'api_service.dart';

class GeminiChatService {
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';
  final geminiApiKey = 'AIzaSyCK2a8vUXR2xLwo6l0KztedRJ2gFM135Ik';
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

    final response = await apiService.post(
      headers: headers,
      data: body,
      baseUrl: baseUrl,
    );
    final botMessage = response['candidates'][0]['content']['parts'][0]['text'];
    return botMessage;
  }
}
