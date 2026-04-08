import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:chat_bot_gemini/features/chat/data/models/gemini_response_model.dart';
import 'package:chat_bot_gemini/features/chat/data/repos/gemini_chat_repo_impl.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGeminiChatService extends Mock implements GeminiChatService {}

void main() {
  late MockGeminiChatService mockGeminiChatService;
  late GeminiChatRepoImpl geminiChatRepoImpl;

  final validMessages = [ChatMessageModel(role: 'user', message: 'Hello')];

  setUp(() {
    mockGeminiChatService = MockGeminiChatService();
    geminiChatRepoImpl = GeminiChatRepoImpl(
      geminiChatService: mockGeminiChatService,
    );
  });

  String expectLeftMessage(Either<Failure, String> result) {
    return result.fold((failure) => failure.errorMessage, (_) {
      fail('Expected Left but got Right');
    });
  }

  String expectRightValue(Either<Failure, String> result) {
    return result.fold((failure) {
      fail('Expected Right but got Left(${failure.errorMessage})');
    }, (message) => message);
  }

  group('GeminiChatRepoImpl.sendMessage validation', () {
    test(
      'returns failure and skips service when messages list is empty',
      () async {
        final result = await geminiChatRepoImpl.sendMessage(messages: []);

        expect(result, isA<Left<Failure, String>>());
        expect(
          expectLeftMessage(result),
          contains('Messages list cannot be empty'),
        );
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
      'calls service when at least one message contains real text',
      () async {
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

        expect(expectRightValue(result), equals('Accepted'));
        verify(
          () => mockGeminiChatService.generateText(messages: messages),
        ).called(1);
      },
    );
  });

  group('GeminiChatRepoImpl.sendMessage success', () {
    test('returns trimmed text when service succeeds', () async {
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

    test(
      'returns empty string when the service response text is blank',
      () async {
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

        // This documents the current repo behavior: text is trimmed, but not rejected.
        expect(expectRightValue(result), isEmpty);
      },
    );
  });

  group('GeminiChatRepoImpl.sendMessage failure mapping', () {
    test('returns the same ServerFailure thrown by the service', () async {
      const failure = ServerFailure(errorMessage: 'Server crashed');

      when(
        () => mockGeminiChatService.generateText(messages: validMessages),
      ).thenThrow(failure);

      final result = await geminiChatRepoImpl.sendMessage(
        messages: validMessages,
      );

      expect(expectLeftMessage(result), equals('Server crashed'));
    });

    test(
      'maps DioException connection timeout into ServerFailure message',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/chat'),
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
      'maps DioException bad response using the API error message',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/chat'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/chat'),
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

        expect(expectLeftMessage(result), equals('Invalid API key'));
      },
    );

    test(
      'maps unexpected exceptions into ServerFailure with exception text',
      () async {
        when(
          () => mockGeminiChatService.generateText(messages: validMessages),
        ).thenThrow(Exception('Unexpected crash'));

        final result = await geminiChatRepoImpl.sendMessage(
          messages: validMessages,
        );

        expect(
          expectLeftMessage(result),
          equals('Exception: Unexpected crash'),
        );
      },
    );
  });
}
