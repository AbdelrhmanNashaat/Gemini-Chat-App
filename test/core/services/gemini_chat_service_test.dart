// -----------------------------------------------------------------------------
// GeminiChatService unit tests
// -----------------------------------------------------------------------------
// Unit under test : GeminiChatService  (lib/core/services/gemini_chat_service.dart)
// Dependency mocked: ApiService
//
// What this file covers
//   1. Happy path  — service returns a parsed GeminiResponseModel on the first
//                    attempt.
//   2. Request shape — the correct URL, headers, and body are forwarded to
//                      ApiService.post().
//   3. Retry logic  — retryable DioException types trigger up to 3 attempts
//                     before re-throwing; non-retryable types fail immediately.
//
// Key concepts used
//   • mocktail — creates a Mock double of ApiService so no real HTTP calls
//     are made.  `when(...)` stubs return values; `verify(...)` asserts call
//     counts.
//   • captureAny — captures the actual argument passed to a mock so we can
//     inspect it after the call.
//   • for-loop parametrization — each DioExceptionType that belongs to the
//     same category is tested with the same logic without copy-pasting code.
// -----------------------------------------------------------------------------

import 'package:chat_bot_gemini/core/services/api_service.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test double
// ---------------------------------------------------------------------------
// MockApiService replaces the real ApiService.  Because ApiService makes real
// Dio HTTP calls, we replace it here so the tests run offline and instantly.
class MockApiService extends Mock implements ApiService {}

void main() {
  // -------------------------------------------------------------------------
  // Shared fixtures
  // -------------------------------------------------------------------------

  late MockApiService mockApiService;
  late GeminiChatService geminiChatService;

  // The exact URL the service must use — checked in the "request shape" test.
  const baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  // A minimal one-message conversation used as input in most tests.
  final messages = [ChatMessageModel(role: 'user', message: 'Hello Gemini')];

  // A minimal valid Gemini API JSON payload — mirrors the real API contract.
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

  // Retryable types: the service should call ApiService again after one of
  // these errors because they are transient network conditions.
  final retryableTypes = <DioExceptionType>[
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ];

  // Non-retryable types: the service must fail immediately without retrying
  // because the error is either permanent or requires user action.
  final nonRetryableTypes = <DioExceptionType>[
    DioExceptionType.badCertificate,
    DioExceptionType.badResponse, // e.g. HTTP 400/500 — no point retrying
    DioExceptionType.cancel,
    DioExceptionType.unknown,
  ];

  // Runs before every test: create fresh instances so no state leaks between
  // tests.
  setUp(() {
    mockApiService = MockApiService();
    geminiChatService = GeminiChatService(apiService: mockApiService);
  });

  // =========================================================================
  // Group 1 — generateText
  // =========================================================================
  group('GeminiChatService.generateText', () {
    // -----------------------------------------------------------------------
    // Happy path
    // -----------------------------------------------------------------------

    test('returns parsed response on the first successful attempt', () async {
      // Arrange: stub ApiService to return a valid JSON payload.
      when(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => successResponse);

      // Act
      final result = await geminiChatService.generateText(messages: messages);

      // Assert: GeminiResponseModel is correctly parsed from the JSON.
      expect(result.candidates, hasLength(1));
      expect(result.text, equals('Hello from Gemini'));

      // Exactly one HTTP call was made — no unexpected retries.
      verify(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).called(1);
    });

    // -----------------------------------------------------------------------
    // Request shape
    // -----------------------------------------------------------------------
    // This test white-boxes the request that GeminiChatService builds.
    // It verifies three things:
    //   • The correct Gemini endpoint URL is used.
    //   • The x-goog-api-key and Content-Type headers are present.
    //   • The message list is serialized into the 'contents' structure that
    //     the Gemini API requires.

    test('sends the expected endpoint, headers, and request body', () async {
      when(
        () => mockApiService.post(
          baseUrl: any(named: 'baseUrl'),
          headers: any(named: 'headers'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => successResponse);

      await geminiChatService.generateText(messages: messages);

      // captureAny records the actual argument values so we can inspect them.
      // The order of captured values matches the order of the named parameters
      // as listed inside verify().
      final verification = verify(
        () => mockApiService.post(
          baseUrl: captureAny(named: 'baseUrl'),
          headers: captureAny(named: 'headers'),
          data: captureAny(named: 'data'),
        ),
      );

      final capturedBaseUrl = verification.captured[0] as String;
      final capturedHeaders = verification.captured[1] as Map<String, dynamic>;
      final capturedData = verification.captured[2] as Map<String, dynamic>;

      // URL must target the exact Gemini 2.0 Flash endpoint.
      expect(capturedBaseUrl, equals(baseUrl));

      // API key header must be present and non-empty.
      expect(capturedHeaders['x-goog-api-key'], isNotEmpty);

      // Content-Type must be JSON so the API server can parse the body.
      expect(capturedHeaders['Content-Type'], equals('application/json'));

      // The 'contents' array must match the Gemini request schema.
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

    // -----------------------------------------------------------------------
    // Retry logic — retryable types
    // -----------------------------------------------------------------------
    // The service has a 3-attempt budget for transient errors.
    // These two sub-tests run for every retryable DioExceptionType:
    //   a) First attempt fails, second succeeds → exactly 2 calls.
    //   b) All 3 attempts fail            → 3 calls, then re-throw.

    for (final type in retryableTypes) {
      // (a) Retry succeeds on the second attempt.
      test(
        'retries once and succeeds for retryable DioException $type',
        () async {
          // Use a counter instead of `thenThrow` so we can make the first call
          // fail and every subsequent call succeed from the same stub.
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

          // Two calls: 1 failure + 1 success.
          verify(
            () => mockApiService.post(
              baseUrl: any(named: 'baseUrl'),
              headers: any(named: 'headers'),
              data: any(named: 'data'),
            ),
          ).called(2);
        },
      );

      // (b) All retries exhausted — rethrow after 3 attempts.
      test(
        'retries three times then rethrows for retryable DioException $type',
        () async {
          // thenThrow always throws the same error — simulates a persistent
          // network failure across every retry.
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

          // expectLater + throwsA is the idiomatic way to assert that a Future
          // completes with a specific exception type and properties.
          await expectLater(
            geminiChatService.generateText(messages: messages),
            throwsA(isA<DioException>().having((e) => e.type, 'type', type)),
          );

          // Exactly 3 calls: the service used the whole retry budget.
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

    // -----------------------------------------------------------------------
    // Retry logic — non-retryable types
    // -----------------------------------------------------------------------
    // Non-retryable errors are not transient — retrying them would waste
    // time and bandwidth.  The service must re-throw after a single attempt.

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
          throwsA(isA<DioException>().having((e) => e.type, 'type', type)),
        );

        // Exactly 1 call: the error was not retried.
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
