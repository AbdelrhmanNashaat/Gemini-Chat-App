import 'package:dio/dio.dart';
import '../../features/chat/data/models/chat_message_model.dart';
import '../../features/chat/data/models/gemini_request_model.dart';
import '../../features/chat/data/models/gemini_response_model.dart';
import 'api_service.dart';

class GeminiChatService {
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final String _geminiApiKey = 'AIzaSyB3sNYcGJcZeduB6WRrKj7wmrKBJ2eVZL8';
  final ApiService apiService;
  GeminiChatService({required this.apiService});

  Map<String, String> get _headers => {
    'x-goog-api-key': _geminiApiKey,
    'Content-Type': 'application/json',
  };

  Future<GeminiResponseModel> generateText({
    required List<ChatMessageModel> messages,
  }) async {
    return _callApi(messages);
  }

  Future<GeminiResponseModel> _callApi(List<ChatMessageModel> messages) async {
    const maxRetries = 3;
    final request = GeminiRequestModel(messages: messages);

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final response = await apiService.post(
          baseUrl: _baseUrl,
          headers: _headers,
          data: request.toJson(),
        );

        return GeminiResponseModel.fromJson(response);
      } on DioException catch (e) {
        final isLastAttempt = attempt == maxRetries - 1;

        if (!_shouldRetry(e) || isLastAttempt) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    throw StateError('Retry loop exited unexpectedly');
  }

  bool _shouldRetry(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError;
  }
}
