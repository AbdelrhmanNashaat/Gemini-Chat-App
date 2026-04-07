import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:chat_bot_gemini/features/chat/data/models/gemini_response_model.dart';
import 'package:chat_bot_gemini/features/chat/data/repos/gemini_chat_repo_impl.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGeminiChatService extends Mock implements GeminiChatService {}

void main() {
  late MockGeminiChatService mockGeminiChatService;
  late GeminiChatRepoImpl geminiChatRepoImpl;

  // Runs before every test.
  // Creates fresh clean instances.
  setUp(() {
    mockGeminiChatService = MockGeminiChatService();

    geminiChatRepoImpl = GeminiChatRepoImpl(
      geminiChatService: mockGeminiChatService,
    );
  });

  /// =========================
  /// VALIDATION TESTS
  /// =========================
  group('sendMessage validation', () {
    test(
      'should return Left(ServerFailure) and never call service when messages list is empty',
      () async {
        // Act
        final result = await geminiChatRepoImpl.sendMessage(messages: []);

        // Assert
        expect(result, isA<Left<Failure, String>>());

        result.fold((failure) {
          expect(
            failure.errorMessage,
            contains('Messages list cannot be empty'),
          );
        }, (_) => fail('Expected Left but got Right'));

        // Most important validation assertion:
        // API service must never be called
        verifyNever(
          () => mockGeminiChatService.generateText(
            messages: any(named: 'messages'),
          ),
        );
      },
    );

    test('should return failure when all messages are empty', () async {
      // Arrange
      final messages = [ChatMessageModel(role: 'user', message: '   ')];

      // Act
      final result = await geminiChatRepoImpl.sendMessage(messages: messages);

      // Assert
      expect(result, isA<Left<Failure, String>>());

      verifyNever(
        () => mockGeminiChatService.generateText(
          messages: any(named: 'messages'),
        ),
      );
    });
  });

  /// =========================
  /// SUCCESS TESTS
  /// =========================
  group('sendMessage success', () {
    test('should return Right(trimmed text) when service succeeds', () async {
      // Arrange
      final messages = [ChatMessageModel(role: 'user', message: 'Hello')];

      when(
        () => mockGeminiChatService.generateText(messages: messages),
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

      // Act
      final result = await geminiChatRepoImpl.sendMessage(messages: messages);

      // Assert
      expect(result, equals(const Right('Hello from Gemini')));

      verify(
        () => mockGeminiChatService.generateText(messages: messages),
      ).called(1);
    });
  });

  /// =========================
  /// FAILURE MAPPING TESTS
  /// =========================
  group('sendMessage failures', () {
    test(
      'should return Left(ServerFailure) when service throws ServerFailure',
      () async {
        // Arrange
        final messages = [ChatMessageModel(role: 'user', message: 'Hello')];

        when(
          () => mockGeminiChatService.generateText(messages: messages),
        ).thenThrow(const ServerFailure(errorMessage: 'Server crashed'));

        // Act
        final result = await geminiChatRepoImpl.sendMessage(messages: messages);

        // Assert
        expect(result, isA<Left<Failure, String>>());
      },
    );

    test('should map DioException into ServerFailure', () async {
      // Arrange
      final messages = [ChatMessageModel(role: 'user', message: 'Hello')];

      when(
        () => mockGeminiChatService.generateText(messages: messages),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          message: 'Network error',
        ),
      );

      // Act
      final result = await geminiChatRepoImpl.sendMessage(messages: messages);

      // Assert
      expect(result, isA<Left<Failure, String>>());
    });

    test('should map unknown exception into ServerFailure', () async {
      // Arrange
      final messages = [ChatMessageModel(role: 'user', message: 'Hello')];

      when(
        () => mockGeminiChatService.generateText(messages: messages),
      ).thenThrow(const ServerFailure(errorMessage: 'Unexpected'));

      // Act
      final result = await geminiChatRepoImpl.sendMessage(messages: messages);

      // Assert
      expect(result, isA<Left<Failure, String>>());
    });
  });
}
