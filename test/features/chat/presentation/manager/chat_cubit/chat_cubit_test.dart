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

// -----------------------------------------------------------------------------
// ChatCubit unit tests
// -----------------------------------------------------------------------------
// Unit under test : ChatCubit  (presentation layer state manager)
// Dependency mocked: ChatRepo
//
// What this file covers
//   1. sendQuestion ignores blank input.
//   2. sendQuestion emits loading -> success and stores both user and model
//      messages on success.
//   3. sendQuestion emits loading -> error and leaves the temporary blank model
//      placeholder in place on failure.
//   4. resendLastQuestion retries only when the cubit is in ChatCubitError.
//   5. resendLastQuestion resends the failed user prompt without forwarding the
//      temporary blank placeholder message.
//
// Key concepts used
//   • blocTest — builds a cubit, performs actions, then asserts the exact state
//     emission sequence.
//   • verify / captureAny — inspects the exact conversation that ChatCubit
//     forwards to ChatRepo.
//   • TextEditingController — ChatCubit trims the user input, sends the trimmed
//     text, then clears the controller after submission.
// -----------------------------------------------------------------------------

void main() {
  late MockChatRepo mockChatRepo;

  setUp(() {
    mockChatRepo = MockChatRepo();
  });

  group('ChatCubit', () {
    // sendQuestion() trims the controller text. If the trimmed value is empty,
    // it should exit immediately without emitting any state or calling ChatRepo.
    blocTest<ChatCubit, ChatState>(
      'sendQuestion emits nothing and skips repo when input is blank',
      build: () => ChatCubit(chatRepo: mockChatRepo),
      act: (cubit) async {
        cubit.messageController.text = '   ';
        await cubit.sendQuestion();
      },
      expect: () => <ChatState>[],
      verify: (cubit) {
        verifyNever(
          () => mockChatRepo.sendMessage(messages: any(named: 'messages')),
        );
        expect(cubit.messageController.text, equals('   '));
        expect(cubit.messages, isEmpty);
      },
    );

    // Success flow:
    // 1. User input is trimmed.
    // 2. A loading state is emitted with a temporary blank model placeholder.
    // 3. The repo returns Right(answer).
    // 4. The placeholder is replaced with the real Gemini reply.
    blocTest<ChatCubit, ChatState>(
      'sendQuestion emits loading then success and sends only the trimmed user message',
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
        expect(cubit.messages.first.role, equals('user'));
        expect(cubit.messages.first.message, equals('Hello Gemini'));
        expect(cubit.messages.last.role, equals('model'));
        expect(cubit.messages.last.message, equals('Hello from Gemini'));
      },
    );

    // Failure flow:
    // 1. The repo returns Left(ServerFailure).
    // 2. ChatCubit emits ChatCubitError.
    // 3. The temporary blank model placeholder remains in messages so the
    //    failed request can be retried later.
    blocTest<ChatCubit, ChatState>(
      'sendQuestion emits loading then error and keeps the pending reply placeholder',
      build: () {
        when(
          () => mockChatRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer(
          (_) async =>
              const Left(ServerFailure(errorMessage: 'No internet connection')),
        );

        return ChatCubit(chatRepo: mockChatRepo);
      },
      act: (cubit) async {
        cubit.messageController.text = 'Need a reply';
        await cubit.sendQuestion();
      },
      expect: () => [isA<ChatCubitLoading>(), isA<ChatCubitError>()],
      verify: (cubit) {
        expect(cubit.state, isA<ChatCubitError>());
        expect(
          (cubit.state as ChatCubitError).errorMessage,
          equals('No internet connection'),
        );
        expect(cubit.messages, hasLength(2));
        expect(cubit.messages.first.role, equals('user'));
        expect(cubit.messages.first.message, equals('Need a reply'));
        expect(cubit.messages.last.role, equals('model'));
        expect(cubit.messages.last.message, isEmpty);
      },
    );

    // Retry flow:
    // 1. First send fails and leaves [user, blank-model-placeholder].
    // 2. resendLastQuestion() strips that blank placeholder.
    // 3. It sends only the original user prompt again.
    // 4. On success, the placeholder is replaced with the retried answer.
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
        expect(firstAttempt.single.role, equals('user'));
        expect(firstAttempt.single.message, equals('Retry me'));
        expect(secondAttempt, hasLength(1));
        expect(secondAttempt.single.role, equals('user'));
        expect(secondAttempt.single.message, equals('Retry me'));
        expect(cubit.state, isA<ChatCubitSuccess>());
        expect(cubit.messages, hasLength(2));
        expect(cubit.messages.last.role, equals('model'));
        expect(cubit.messages.last.message, equals('Retried answer'));
      },
    );

    // Guard clause: resendLastQuestion() should do nothing unless the cubit is
    // currently in ChatCubitError.
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
