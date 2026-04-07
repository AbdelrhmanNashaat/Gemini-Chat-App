import '../../features/chat/data/models/chat_message_model.dart';
import '../../features/chat/data/models/gemini_response_model.dart';
import 'api_service.dart';

class GeminiChatService {
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final String _geminiApiKey = 'YOUR_API_KEY';
  final ApiService apiService;

  GeminiChatService({required this.apiService});

  Future<GeminiResponseModel> generateText({
    required List<ChatMessageModel> messages,
  }) async {
    return _callApi(messages);
  }

  Future<GeminiResponseModel> _callApi(List<ChatMessageModel> messages) async {
    final response = await apiService.post(
      baseUrl: _baseUrl,
      headers: {
        'x-goog-api-key': _geminiApiKey,
        'Content-Type': 'application/json',
      },
      data: {
        'contents': messages.map((m) {
          return {
            'role': m.role,
            'parts': [
              {'text': m.message},
            ],
          };
        }).toList(),
      },
    );

    return GeminiResponseModel.fromJson(response);
  }
}
