import 'package:bloc_test/bloc_test.dart';
import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/features/chat/data/models/chat_message_model.dart';
import 'package:chat_bot_gemini/features/chat/domain/chat_repo.dart';
import 'package:chat_bot_gemini/features/chat/presentation/manager/chat_cubit/chat_cubit.dart';
import 'package:chat_bot_gemini/features/chat/presentation/manager/chat_cubit/chat_state.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepo extends Mock implements ChatRepo {}

void main() {
  late MockChatRepo mockChatRepo;

  setUp(() {
    mockChatRepo = MockChatRepo();
  });

  group('ChatCubit', () {
    blocTest<ChatCubit, ChatState>(
      'sendQuestion emits loading then success and sends only the user message',
      build: () {
        when(
          () => mockChatRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer((_) async => const Right('Hello from Gemini'));

        return ChatCubit(chatRepo: mockChatRepo);
      },
      act: (cubit) async {
        cubit.messageController.text = '  Hello Gemini  ';
        await cubit.sendQuestion();
      },
      expect: () => [isA<ChatCubitLoading>(), isA<ChatCubitSuccess>()],
      verify: (cubit) {
        final verification = verify(
          () =>
              mockChatRepo.sendMessage(messages: captureAny(named: 'messages')),
        );
        final sentMessages =
            verification.captured.single as List<ChatMessageModel>;

        expect(sentMessages, hasLength(1));
        expect(sentMessages.first.role, equals('user'));
        expect(sentMessages.first.message, equals('Hello Gemini'));
        expect(cubit.messageController.text, isEmpty);
        expect(cubit.messages, hasLength(2));
        expect(cubit.messages.last.message, equals('Hello from Gemini'));
      },
    );

    blocTest<ChatCubit, ChatState>(
      'resendLastQuestion retries the failed prompt without sending the blank placeholder',
      build: () {
        var callCount = 0;

        when(
          () => mockChatRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer((_) async {
          callCount++;

          if (callCount == 1) {
            return const Left(
              ServerFailure(errorMessage: 'No internet connection'),
            );
          }

          return const Right('Retried answer');
        });

        return ChatCubit(chatRepo: mockChatRepo);
      },
      act: (cubit) async {
        cubit.messageController.text = 'Retry me';
        await cubit.sendQuestion();
        await cubit.resendLastQuestion();
      },
      expect: () => [
        isA<ChatCubitLoading>(),
        isA<ChatCubitError>(),
        isA<ChatCubitLoading>(),
        isA<ChatCubitSuccess>(),
      ],
      verify: (cubit) {
        final verification = verify(
          () =>
              mockChatRepo.sendMessage(messages: captureAny(named: 'messages')),
        );
        final firstAttempt = verification.captured[0] as List<ChatMessageModel>;
        final secondAttempt =
            verification.captured[1] as List<ChatMessageModel>;

        // The resend should replay the failed user prompt, not the UI loading placeholder.
        expect(firstAttempt, hasLength(1));
        expect(secondAttempt, hasLength(1));
        expect(secondAttempt.single.role, equals('user'));
        expect(secondAttempt.single.message, equals('Retry me'));
        expect(cubit.state, isA<ChatCubitSuccess>());
        expect(cubit.messages.last.message, equals('Retried answer'));
      },
    );

    blocTest<ChatCubit, ChatState>(
      'resendLastQuestion emits nothing when the cubit is not in error state',
      build: () => ChatCubit(chatRepo: mockChatRepo),
      act: (cubit) => cubit.resendLastQuestion(),
      expect: () => <ChatState>[],
      verify: (_) {
        verifyNever(
          () => mockChatRepo.sendMessage(messages: any(named: 'messages')),
        );
      },
    );
  });
}
