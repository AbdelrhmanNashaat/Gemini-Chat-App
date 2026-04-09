// -----------------------------------------------------------------------------
// GeminiChatRepoImpl unit tests
// -----------------------------------------------------------------------------
// Unit under test : GeminiChatRepoImpl  (lib/features/chat/data/repos/)
// Dependency mocked: GeminiChatService
//
// What this file covers
//   1. Input validation  — empty list, all-blank list, partial-blank list.
//   2. Success path      — trimmed response text is returned as Right(String).
//   3. Output validation — blank AI response is rejected by the mixin.
//   4. Failure mapping   — every DioExceptionType is mapped to the correct
//                          ServerFailure message, plus raw ServerFailure
//                          pass-through and generic exception wrapping.
//
// Key concepts used
//   • dartz Either<L, R> — the repo returns Left(Failure) on error and
//     Right(String) on success.  The helper functions expectLeftMessage and
//     expectRightValue unwrap the Either and fail the test if the wrong side
//     is returned — giving a clear error message instead of a cast exception.
//   • verifyZeroInteractions — confirms GeminiChatService was never reached
//     when the input is invalid (validation must happen before any network
//     call).
//   • ChatServiceValidationMixin — the repo uses this mixin for both input
//     and output validation.  validateOutputText throws
//     Exception('AI returned empty response') when the AI reply is blank, so
//     that case maps to Left instead of Right('').
// -----------------------------------------------------------------------------

import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:chat_bot_gemini/features/chat/data/models/gemini_response_model.dart';
import 'package:chat_bot_gemini/features/chat/data/repos/gemini_chat_repo_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Test double
// ---------------------------------------------------------------------------
class MockGeminiChatService extends Mock implements GeminiChatService {}

void main() {
  // -------------------------------------------------------------------------
  // Shared fixtures
  // -------------------------------------------------------------------------

  late MockGeminiChatService mockGeminiChatService;
  late GeminiChatRepoImpl geminiChatRepoImpl;

  // A single valid message used as the "happy path" input.
  final validMessages = [ChatMessageModel(role: 'user', message: 'Hello')];

  setUp(() {
    mockGeminiChatService = MockGeminiChatService();
    geminiChatRepoImpl = GeminiChatRepoImpl(
      geminiChatService: mockGeminiChatService,
    );
  });

  // -------------------------------------------------------------------------
  // Helper functions
  // -------------------------------------------------------------------------
  // These helpers unwrap the Either<Failure, String> result.
  // If the wrong side is returned the test fails with a descriptive message
  // rather than a cryptic type error.

  /// Extracts the error message from a Left.  Fails if the result is a Right.
  String expectLeftMessage(Either<Failure, String> result) {
    return result.fold(
      (failure) => failure.errorMessage,
      (_) => fail('Expected Left (failure) but got Right (success)'),
    );
  }

  /// Extracts the string value from a Right.  Fails if the result is a Left.
  String expectRightValue(Either<Failure, String> result) {
    return result.fold(
      (failure) => fail(
        'Expected Right (success) but got Left: ${failure.errorMessage}',
      ),
      (message) => message,
    );
  }

  // =========================================================================
  // Group 1 — Input validation
  // =========================================================================
  // The mixin validates messages before the service is ever called.
  // All three tests assert verifyZeroInteractions to guarantee that no
  // network request is made when the input is obviously invalid.

  group('GeminiChatRepoImpl.sendMessage — input validation', () {
    test(
      'returns failure and skips service when messages list is empty',
      () async {
        final result = await geminiChatRepoImpl.sendMessage(messages: []);

        // An empty list must produce a Left, not cause a crash.
        expect(result, isA<Left<Failure, String>>());
        expect(
          expectLeftMessage(result),
          contains('Messages list cannot be empty'),
        );

        // No HTTP call should have been attempted for invalid input.
        verifyZeroInteractions(mockGeminiChatService);
      },
    );

    test(
      'returns failure and skips service when all messages are blank',
      () async {
        final messages = [
          ChatMessageModel(role: 'user', message: '   '),
          ChatMessageModel(role: 'model', message: '\n'),
        ];

        final result = await geminiChatRepoImpl.sendMessage(messages: messages);

        expect(result, isA<Left<Failure, String>>());
        expect(expectLeftMessage(result), contains('All messages are empty'));
        verifyZeroInteractions(mockGeminiChatService);
      },
    );

    test(
      'calls service when at least one message has non-blank text',
      () async {
        // One blank message + one real message — the list is considered valid.
        final messages = [
          ChatMessageModel(role: 'user', message: '   '),
          ChatMessageModel(role: 'model', message: 'Previous answer'),
        ];

        when(
          () => mockGeminiChatService.generateText(messages: messages),
        ).thenAnswer(
          (_) async => const GeminiResponseModel(
            candidates: [
              GeminiCandidateModel(
                content: GeminiContentModel(
                  parts: [GeminiPartModel(text: 'Accepted')],
                ),
              ),
            ],
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(messages: messages);

        // Mixed-blank input is valid — the repo should reach the service.
        expect(expectRightValue(result), equals('Accepted'));
        verify(
          () => mockGeminiChatService.generateText(messages: messages),
        ).called(1);
      },
    );
  });

  // =========================================================================
  // Group 2 — Success path
  // =========================================================================

  group('GeminiChatRepoImpl.sendMessage — success', () {
    test('returns trimmed text when service succeeds', () async {
      // Leading/trailing whitespace in the AI reply must be stripped.
      when(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).thenAnswer(
        (_) async => const GeminiResponseModel(
          candidates: [
            GeminiCandidateModel(
              content: GeminiContentModel(
                parts: [GeminiPartModel(text: '   Hello from Gemini   ')],
              ),
            ),
          ],
        ),
      );

      final result = await geminiChatRepoImpl.sendMessage(
        messages: validMessages,
      );

      expect(expectRightValue(result), equals('Hello from Gemini'));
      verify(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).called(1);
    });

    // -----------------------------------------------------------------------
    // Output validation edge case
    // -----------------------------------------------------------------------
    // When the AI returns a blank (whitespace-only) reply, the mixin method
    // validateOutputText() throws Exception('AI returned empty response').
    // The repo's catch-all handler wraps that into a ServerFailure, so the
    // caller receives a Left instead of a Right with an empty string.

    test('returns failure when the AI response text is blank', () async {
      when(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).thenAnswer(
        (_) async => const GeminiResponseModel(
          candidates: [
            GeminiCandidateModel(
              content: GeminiContentModel(
                parts: [GeminiPartModel(text: '   ')],
              ),
            ),
          ],
        ),
      );

      final result = await geminiChatRepoImpl.sendMessage(
        messages: validMessages,
      );

      // The mixin throws, the repo maps it to Left(ServerFailure).
      expect(result, isA<Left<Failure, String>>());
      expect(expectLeftMessage(result), contains('AI returned empty response'));
    });
  });

  // =========================================================================
  // Group 3 — Failure mapping
  // =========================================================================
  // The repo's catch blocks convert every exception type into a ServerFailure
  // with a human-readable message.  Each test drives one specific path.

  group('GeminiChatRepoImpl.sendMessage — failure mapping', () {
    // -----------------------------------------------------------------------
    // ServerFailure pass-through
    // -----------------------------------------------------------------------
    // If the service itself throws a ServerFailure (e.g. after exhausting
    // retries), the repo must return it as-is without re-wrapping it.

    test('passes through a ServerFailure thrown by the service', () async {
      const failure = ServerFailure(errorMessage: 'Server crashed');

      when(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).thenThrow(failure);

      final result = await geminiChatRepoImpl.sendMessage(
        messages: validMessages,
      );

      expect(expectLeftMessage(result), equals('Server crashed'));
    });

    // -----------------------------------------------------------------------
    // DioException mapping — one test per DioExceptionType
    // -----------------------------------------------------------------------
    // ServerFailure.fromDioException has a switch on DioExceptionType.
    // Each case below drives a different branch of that switch and verifies
    // the exact message string defined in failures.dart.

    test(
      'maps DioException.connectionTimeout → "Connection timeout, please try again"',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        expect(
          expectLeftMessage(result),
          equals('Connection timeout, please try again'),
        );
      },
    );

    test(
      'maps DioException.sendTimeout → "Send timeout, please try again"',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.sendTimeout,
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        expect(
          expectLeftMessage(result),
          equals('Send timeout, please try again'),
        );
      },
    );

    test(
      'maps DioException.receiveTimeout → "Receive timeout, please try again"',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        expect(
          expectLeftMessage(result),
          equals('Receive timeout, please try again'),
        );
      },
    );

    test(
      'maps DioException.connectionError → "No internet connection"',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        expect(expectLeftMessage(result), equals('No internet connection'));
      },
    );

    test('maps DioException.badCertificate → "Bad certificate"', () async {
      when(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.badCertificate,
        ),
      );

      final result = await geminiChatRepoImpl.sendMessage(
        messages: validMessages,
      );

      expect(expectLeftMessage(result), equals('Bad certificate'));
    });

    test('maps DioException.cancel → "Request was cancelled"', () async {
      when(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.cancel,
        ),
      );

      final result = await geminiChatRepoImpl.sendMessage(
        messages: validMessages,
      );

      expect(expectLeftMessage(result), equals('Request was cancelled'));
    });

    test('maps DioException.unknown → "Unexpected error occurred"', () async {
      when(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).thenThrow(DioException(requestOptions: RequestOptions(path: '/')));

      final result = await geminiChatRepoImpl.sendMessage(
        messages: validMessages,
      );

      expect(expectLeftMessage(result), equals('Unexpected error occurred'));
    });

    // -----------------------------------------------------------------------
    // badResponse — ServerFailure.fromResponse
    // -----------------------------------------------------------------------
    // badResponse reaches ServerFailure.fromResponse which inspects the HTTP
    // status code.  We test the 400-range branch that extracts the API's own
    // error message from response['error']['message'].

    test(
      'maps DioException.badResponse (400) using the API error message',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/'),
              statusCode: 400,
              data: {
                'error': {'message': 'Invalid API key'},
              },
            ),
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        // The error message comes from the JSON body, not a hardcoded string.
        expect(expectLeftMessage(result), equals('Invalid API key'));
      },
    );

    test(
      'maps DioException.badResponse (404) → "Your request was not found…"',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/'),
              statusCode: 404,
              data: {},
            ),
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        expect(
          expectLeftMessage(result),
          equals('Your request was not found, please try later'),
        );
      },
    );

    test(
      'maps DioException.badResponse (500) → "Internal server error…"',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/'),
              statusCode: 500,
              data: {},
            ),
          ),
        );

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        expect(
          expectLeftMessage(result),
          equals('Internal server error, please try later'),
        );
      },
    );

    // -----------------------------------------------------------------------
    // Generic exception
    // -----------------------------------------------------------------------
    // Any exception that is not a ServerFailure or DioException is wrapped
    // with its toString() so the caller always receives a descriptive message.

    test(
      'wraps unexpected exceptions in ServerFailure using exception.toString()',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(Exception('Unexpected crash'));

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        // Exception.toString() prefixes the message with 'Exception: '.
        expect(
          expectLeftMessage(result),
          equals('Exception: Unexpected crash'),
        );
      },
    );
  });
}
