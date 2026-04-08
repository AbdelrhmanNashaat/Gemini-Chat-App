import 'package:chat_bot_gemini/core/services/api_service.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApiService;
  late GeminiChatService geminiChatService;

  const baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final messages = [ChatMessageModel(role: 'user', message: 'Hello Gemini')];

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

  final retryableTypes = <DioExceptionType>[
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ];

  final nonRetryableTypes = <DioExceptionType>[
    DioExceptionType.badCertificate,
    DioExceptionType.cancel,
    DioExceptionType.unknown,
  ];

  setUp(() {
    mockApiService = MockApiService();
    geminiChatService = GeminiChatService(apiService: mockApiService);
  });

  group('GeminiChatService.generateText', () {
    test('returns parsed response on the first successful attempt', () async {
      when(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => successResponse);

      final result = await geminiChatService.generateText(messages: messages);

      expect(result.candidates, hasLength(1));
      expect(result.text, equals('Hello from Gemini'));

      verify(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    test('sends the expected endpoint headers and request body', () async {
      when(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => successResponse);

      await geminiChatService.generateText(messages: messages);

      final verification = verify(
        () => mockApiService.post(
          baseUrl: captureAny(named: 'baseUrl'),
          headers: captureAny(named: 'headers'),
          data: captureAny(named: 'data'),
        ),
      );

      final capturedArguments = verification.captured;
      final capturedBaseUrl = capturedArguments[0] as String;
      final capturedHeaders = capturedArguments[1] as Map<String, dynamic>;
      final capturedData = capturedArguments[2] as Map<String, dynamic>;

      // This checks that the service itself builds the Gemini request correctly.
      expect(capturedBaseUrl, equals(baseUrl));
      expect(capturedHeaders['x-goog-api-key'], equals(''));
      expect(capturedHeaders['Content-Type'], equals('application/json'));
      expect(
        capturedData,
        equals({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'Hello Gemini'},
              ],
            },
          ],
        }),
      );
    });

    for (final type in retryableTypes) {
      test(
        'retries once and succeeds for retryable DioException $type',
        () async {
          var callCount = 0;

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
                requestOptions: RequestOptions(path: baseUrl),
                type: type,
              );
            }

            return successResponse;
          });

          final result = await geminiChatService.generateText(
            messages: messages,
          );

          expect(result.text, equals('Hello from Gemini'));
          verify(
            () => mockApiService.post(
              baseUrl: any(named: 'baseUrl'),
              headers: any(named: 'headers'),
              data: any(named: 'data'),
            ),
          ).called(2);
        },
      );

      test(
        'retries three times then rethrows for retryable DioException $type',
        () async {
          when(
            () => mockApiService.post(
              baseUrl: any(named: 'baseUrl'),
              headers: any(named: 'headers'),
              data: any(named: 'data'),
            ),
          ).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: baseUrl),
              type: type,
            ),
          );

          await expectLater(
            geminiChatService.generateText(messages: messages),
            throwsA(
              isA<DioException>().having((error) => error.type, 'type', type),
            ),
          );

          // Three calls means the service used the whole retry budget before failing.
          verify(
            () => mockApiService.post(
              baseUrl: any(named: 'baseUrl'),
              headers: any(named: 'headers'),
              data: any(named: 'data'),
            ),
          ).called(3);
        },
      );
    }

    for (final type in nonRetryableTypes) {
      test('does not retry for non-retryable DioException $type', () async {
        when(
          () => mockApiService.post(
            baseUrl: any(named: 'baseUrl'),
            headers: any(named: 'headers'),
            data: any(named: 'data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: baseUrl),
            type: type,
          ),
        );

        await expectLater(
          geminiChatService.generateText(messages: messages),
          throwsA(
            isA<DioException>().having((error) => error.type, 'type', type),
          ),
        );

        verify(
          () => mockApiService.post(
            baseUrl: any(named: 'baseUrl'),
            headers: any(named: 'headers'),
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    }
  });
}
