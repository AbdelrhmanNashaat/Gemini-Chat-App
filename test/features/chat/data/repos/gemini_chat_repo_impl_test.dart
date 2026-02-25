import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:chat_bot_gemini/features/chat/data/repos/gemini_chat_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class GeminiChatRepoImplTest {}

class GeminiChatServiceMock extends Mock implements GeminiChatService {}

void main() {
  late GeminiChatServiceMock geminiChatServiceMock;
  late GeminiChatRepoImpl geminiChatRepoImpl;

  setUp(() {
    geminiChatServiceMock = GeminiChatServiceMock();
    geminiChatRepoImpl = GeminiChatRepoImpl(
      geminiChatService: geminiChatServiceMock,
    );
  });

  group('GeminiChatRepoImpl Full Coverage', () {
    // 1️⃣ input validation
    test('Returns failure when messages list is empty', () async {
      final result = await geminiChatRepoImpl.sendMessage(messages: []);
      expect(result.isLeft(), true);
    });
    test('List with empty message', () async {
      final result = await geminiChatRepoImpl.sendMessage(
        messages: [ChatMessageModel(role: 'user', message: '')],
      );
      expect(result.isLeft(), true);
    });
    test('List with empty message & empty role', () async {
      final result = await geminiChatRepoImpl.sendMessage(
        messages: [ChatMessageModel(role: '', message: '')],
      );
      expect(result.isLeft(), true);
    });
    test('List with wrong role', () async {
      final result = await geminiChatRepoImpl.sendMessage(
        messages: [ChatMessageModel(role: 'wrong_role', message: 'test')],
      );
      expect(result.isLeft(), true);
    });
    test('Does not call service when messages list is empty', () async {
      await geminiChatRepoImpl.sendMessage(messages: []);

      verifyNever(
        () => geminiChatServiceMock.generateText(
          messages: any(named: 'messages'),
        ),
      );
    });
  });

  group('GeminiChatRepoImpl output', () {
    // 2️⃣ output validation
    test('Returns success when service returns success', () async {
      when(
        () => geminiChatServiceMock.generateText(
          messages: any(named: 'messages'),
        ),
      ).thenAnswer((_) async => 'Success');

      final result = await geminiChatRepoImpl.sendMessage(
        messages: [ChatMessageModel(role: 'user', message: 'Hello')],
      );

      expect(result.isRight(), true);
    });

    test('Returns failure when service throws exception', () async {
      when(
        () => geminiChatServiceMock.generateText(
          messages: any(named: 'messages'),
        ),
      ).thenThrow(Exception('Service error'));

      final result = await geminiChatRepoImpl.sendMessage(
        messages: [ChatMessageModel(role: 'user', message: 'Hello')],
      );
      expect(result.isLeft(), true);
    });
    test('Returns failure when service returns empty string', () async {
      when(
        () => geminiChatServiceMock.generateText(
          messages: any(named: 'messages'),
        ),
      ).thenAnswer((_) async => '');

      final result = await geminiChatRepoImpl.sendMessage(
        messages: [ChatMessageModel(role: 'user', message: 'Hello')],
      );

      expect(result.isLeft(), true);
    });
    test('Calls service once on valid input', () async {
      when(
        () => geminiChatServiceMock.generateText(
          messages: any(named: 'messages'),
        ),
      ).thenAnswer((_) async => 'Success');

      await geminiChatRepoImpl.sendMessage(
        messages: [ChatMessageModel(role: 'user', message: 'Hello')],
      );

      verify(
        () => geminiChatServiceMock.generateText(
          messages: any(named: 'messages'),
        ),
      ).called(1);
    });
  });
}
