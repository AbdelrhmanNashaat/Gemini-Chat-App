import 'package:chat_bot_gemini/core/services/api_service.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late ApiService apiService;
  late GeminiChatService geminiChatService;

  final messages = [ChatMessageModel(role: 'user', message: 'Hello')];

  setUp(() {
    apiService = MockApiService();
    geminiChatService = GeminiChatService(apiService: apiService);
  });

  group('GeminiChatService Full Coverage', () {
    // 1️⃣ Success on first call
    test('Returns message on first successful 200 response', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer(
        (_) async => {
          'statusCode': 200,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Success'},
                ],
              },
            },
          ],
        },
      );

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, 'Success');
      verify(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).called(1);
    });

    // 2️⃣ Retry until success
    test('Retries until success', () async {
      int callCount = 0;

      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount < 3) {
          return {'statusCode': 429};
        }
        return {
          'statusCode': 200,
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Recovered'},
                ],
              },
            },
          ],
        };
      });

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, 'Recovered');
      expect(callCount, 3);
    });

    // 3️⃣ Max retries
    test('Retries maximum 3 times on persistent retryable error', () async {
      int callCount = 0;

      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        return {'statusCode': 429};
      });

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
      expect(callCount, 3);
    });

    // 4️⃣ Retry then non-retryable
    test('Stops when retryable followed by non-retryable', () async {
      int callCount = 0;

      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return {'statusCode': 429};
        }
        return {'statusCode': 400};
      });

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
      expect(callCount, 2);
    });

    // 5️⃣ Non-retryable 400
    test('Stops immediately on 400 error', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async => {'statusCode': 400});

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
      verify(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).called(1);
    });

    // 6️⃣ Another non-retryable (401)
    test('Stops immediately on 401 error', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async => {'statusCode': 401});

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
    });

    // 7️⃣ 200 but empty candidates
    test('Returns empty string if 200 but candidates empty', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async => {'statusCode': 200, 'candidates': []});

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
    });

    // 8️⃣ 200 but missing candidates
    test('Returns empty string if candidates missing', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async => {'statusCode': 200});

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
    });

    // 9️⃣ 200 but empty parts
    test('Returns empty string if parts empty', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer(
        (_) async => {
          'statusCode': 200,
          'candidates': [
            {
              'content': {'parts': []},
            },
          ],
        },
      );

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
    });

    // 🔟 Unknown status code (201)
    test('Stops on unknown status code', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenAnswer((_) async => {'statusCode': 201});

      final result = await geminiChatService.generateText(messages: messages);

      expect(result, '');
    });

    // 1️⃣1️⃣ Exception thrown
    test('Throws exception when apiService throws', () async {
      when(
        () => apiService.post(
          headers: any(named: 'headers'),
          data: any(named: 'data'),
          baseUrl: any(named: 'baseUrl'),
        ),
      ).thenThrow(Exception('Network error'));

      expect(
        () => geminiChatService.generateText(messages: messages),
        throwsException,
      );
    });
  });
}
