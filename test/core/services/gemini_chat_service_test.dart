import 'package:chat_bot_gemini/core/services/api_service.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Mock only external dependency.
/// Real retry logic stays inside service.
class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApiService;
  late GeminiChatService geminiChatService;

  final messages = [ChatMessageModel(role: 'user', message: 'Hello')];

  final successResponse = {
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': 'Hello from Gemini'},
          ],
        },
      },
    ],
  };

  setUp(() {
    mockApiService = MockApiService();

    geminiChatService = GeminiChatService(apiService: mockApiService);
  });

  group('GeminiChatService retry logic', () {
    test('should retry once and succeed on second attempt', () async {
      // Arrange
      int callCount = 0;

      when(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {
        callCount++;

        if (callCount == 1) {
          throw DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          );
        }

        return successResponse;
      });

      // Act
      final result = await geminiChatService.generateText(messages: messages);

      // Assert
      expect(result.text, equals('Hello from Gemini'));

      verify(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).called(2);
    });

    test('should retry 3 times then throw DioException', () async {
      // Arrange
      when(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {
        throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        );
      });

      // Act + Assert
      await expectLater(
        geminiChatService.generateText(messages: messages),
        throwsA(isA<DioException>()),
      );

      verify(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).called(3);
    });

    test('should not retry non retryable DioException', () async {
      // Arrange
      when(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {
        throw DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.badCertificate,
        );
      });

      // Act + Assert
      await expectLater(
        geminiChatService.generateText(messages: messages),
        throwsA(isA<DioException>()),
      );

      verify(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).called(1);
    });
  });
}
