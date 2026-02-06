import 'api_service.dart';

class GeminiChatService {
  final String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent';
  final geminiApiKey = 'AIzaSyBJctwBSW3u65Bq-VcVrh2LOdGankdqw8s';
  final ApiService apiService;
  GeminiChatService({required this.apiService});
  Future<dynamic> generateText({required String prompt}) async {
    final headers = {
      'x-goog-api-key': geminiApiKey,
      'Content-Type': 'application/json',
    };
    final message = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    };
    final response = await apiService.post(
      headers: headers,
      data: message,
      baseUrl: baseUrl,
    );
    return response['candidates'][0]['content']['parts'][0]['text'];
  }
}
