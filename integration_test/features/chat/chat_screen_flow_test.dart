import 'dart:async';

import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/core/utils/service_locator.dart';
import 'package:chat_bot_gemini/features/chat/domain/chat_repo.dart';
import 'package:chat_bot_gemini/features/chat/presentation/views/chat_view.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:mocktail/mocktail.dart';

/// Mocktail mock of [ChatRepo] — lets each test script the server responses
/// without touching the network or requiring a real API key.
class ChatMockRepo extends Mock implements ChatRepo {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ChatMockRepo chatMockRepo;

  // ─── Test lifecycle ──────────────────────────────────────────────────────────

  setUp(() async {
    // Reset ALL GetIt registrations so every test starts with a clean slate.
    await getIt.reset();

    // Re-register the production dependency graph (Dio, ApiService, …).
    setupServiceLocator();

    // Swap the real ChatRepo for our controllable mock.
    // This works because service_locator.dart now registers GeminiChatRepoImpl
    // under the ChatRepo interface and ChatCubit resolves getIt<ChatRepo>().
    if (getIt.isRegistered<ChatRepo>()) {
      getIt.unregister<ChatRepo>();
    }
    chatMockRepo = ChatMockRepo();
    getIt.registerSingleton<ChatRepo>(chatMockRepo);
  });

  // ─── Shared helpers ──────────────────────────────────────────────────────────

  /// Mounts the real [ChatView] (which internally creates a [BlocProvider] for
  /// [ChatCubit]) inside a bare [MaterialApp].
  ///
  /// We deliberately use two bounded [pump] calls instead of [pumpAndSettle]
  /// to avoid a race with the real [InternetConnection] stream.  While the
  /// stream is still pending the [StreamBuilder] sits in
  /// [ConnectionState.waiting], which maps to [isChecking] = true → [isOnline]
  /// = true, so the chat UI is always shown regardless of actual network state.
  Future<void> pumpChatView(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatView()));
    // Pump 1: initial widget tree build.
    await tester.pump();
    // Pump 2: let the StreamBuilder's first snapshot settle.
    await tester.pump();
  }

  /// Types [message] into the text field and taps the send button.
  ///
  /// **Why two pumps after the tap?**
  /// [ChatCubit] uses flutter_bloc's [StreamController.broadcast()], which
  /// dispatches state changes *asynchronously* (as microtasks).  Therefore:
  ///   • Pump 1 — drains the microtask queue; the [BlocBuilder] listener fires,
  ///     [setState] is called, and the element is marked dirty.
  ///   • Pump 2 — renders the frame; the dirty [BlocBuilder] rebuilds with
  ///     [ChatCubitLoading], making [LoadingIndicator] visible on screen.
  Future<void> typeAndSend(WidgetTester tester, String message) async {
    // Enter text — this makes the send icon active (hasQuestion = true).
    await tester.enterText(find.byType(TextField), message);
    // Rebuild the ValueListenableBuilder so hasQuestion reflects the new text.
    await tester.pump();
    // Tap the send button → chatCubit.sendQuestion() → emit(ChatCubitLoading).
    await tester.tap(find.byKey(const Key('send_message_button')));
    // Pump 1: microtask queue drains — BlocBuilder listener fires, setState called.
    await tester.pump();
    // Pump 2: frame renders — BlocBuilder rebuilds to show ChatCubitLoading.
    await tester.pump();
  }

  // ─── Test group ──────────────────────────────────────────────────────────────

  group('Test Sending Message Flow in Chat Screen', () {
    // ── Case 1: entering text ──────────────────────────────────────────────────
    testWidgets('1. Entered text is visible inside the message input field', (
      WidgetTester tester,
    ) async {
      // Stub sendMessage so the cubit does not throw when later triggered.
      when(
        () => chatMockRepo.sendMessage(messages: any(named: 'messages')),
      ).thenAnswer((_) async => const Right('ok'));

      await pumpChatView(tester);

      // Type a message — do NOT tap send yet.
      await tester.enterText(find.byType(TextField), 'Hello Gemini');
      await tester.pump();

      // The typed text must be visible in the input field.
      expect(find.text('Hello Gemini'), findsOneWidget);
    });

    // ── Case 2: tapping send dispatches the request ────────────────────────────
    testWidgets(
      '2. Tapping the send button calls sendMessage on the repository',
      (WidgetTester tester) async {
        // Use a Completer so sendMessage never resolves during this test,
        // keeping the cubit in Loading state — easy to verify the call count.
        final completer = Completer<Either<Failure, String>>();
        when(
          () => chatMockRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer((_) => completer.future);

        await pumpChatView(tester);

        await typeAndSend(tester, 'Hello Gemini');

        // The repository must have been called exactly once.
        verify(
          () => chatMockRepo.sendMessage(messages: any(named: 'messages')),
        ).called(1);

        // Resolve the completer so no pending timers leak after test exit.
        completer.complete(const Right('ignored'));
      },
    );

    // ── Case 3: loading indicator ─────────────────────────────────────────────
    testWidgets(
      '3. Loading indicator is visible while awaiting the bot response',
      (WidgetTester tester) async {
        // A never-completing future keeps the cubit permanently in Loading.
        final completer = Completer<Either<Failure, String>>();
        when(
          () => chatMockRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer((_) => completer.future);

        await pumpChatView(tester);
        await typeAndSend(tester, 'Hello Gemini');

        // Loading indicator must be on screen while the response is pending.
        expect(find.byType(LoadingIndicator), findsOneWidget);

        // Resolve so the test runner does not warn about pending timers.
        completer.complete(const Right('ignored'));
      },
    );

    // ── Case 4: user message appears ──────────────────────────────────────────
    testWidgets(
      '4. User message bubble appears in the chat list after sending',
      (WidgetTester tester) async {
        when(
          () => chatMockRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer((_) async => const Right('Hello Abdelrhman'));

        await pumpChatView(tester);
        await typeAndSend(tester, 'Hello Gemini');

        // The user's own message must appear in the chat list immediately.
        expect(find.text('Hello Gemini'), findsOneWidget);
      },
    );

    // ── Case 5: bot response appears after loading ─────────────────────────────
    testWidgets(
      '5. Bot response is shown and loading disappears after the server replies',
      (WidgetTester tester) async {
        when(
          () => chatMockRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer((_) async => const Right('Hello Abdelrhman'));

        await pumpChatView(tester);
        await typeAndSend(tester, 'Hello Gemini');

        // Settle after the cubit emits ChatCubitSuccess.
        await tester.pumpAndSettle();

        // Bot response must be visible as a chat bubble.
        expect(find.text('Hello Abdelrhman'), findsOneWidget);
        // Loading indicator must be gone once the response has arrived.
        expect(find.byType(LoadingIndicator), findsNothing);
      },
    );

    // ── Case 6: error state and resend flow ────────────────────────────────────
    testWidgets(
      '6. Error widget appears on failure; tapping "Try again" resend the '
      'message and shows the bot response on success',
      (WidgetTester tester) async {
        // Hold the retry response so the test can observe the loading state
        // before the cubit transitions to success.
        final retryCompleter = Completer<Either<Failure, String>>();
        // First call fails; second call (resend) stays pending until the test
        // explicitly completes it.
        var callCount = 0;
        when(
          () => chatMockRepo.sendMessage(messages: any(named: 'messages')),
        ).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            // Simulate a network error on the first attempt.
            return Future.value(
              const Left(ServerFailure(errorMessage: 'No internet connection')),
            );
          }
          // Keep the resend in loading state until the assertion is made.
          return retryCompleter.future;
        });

        await pumpChatView(tester);

        // ── Step A: send → expect error widgets ─────────────────────────────
        await typeAndSend(tester, 'Hello Gemini');
        // Settle after the cubit emits ChatCubitError.
        await tester.pumpAndSettle();

        expect(find.text('Something went wrong'), findsOneWidget);
        expect(find.text('No internet connection'), findsOneWidget);

        // ── Step B: tap "Try again" → expect loading ─────────────────────────
        await tester.tap(find.byKey(const Key('resend_button')));
        // Pump 1: microtask queue drains — BlocBuilder listener fires, setState called.
        await tester.pump();
        // Pump 2: frame renders — BlocBuilder rebuilds to show ChatCubitLoading.
        await tester.pump();

        expect(find.byType(LoadingIndicator), findsOneWidget);

        // ── Step C: response arrives → error cleared, success shown ──────────
        // Complete the retry after loading has been verified, then render the
        // success state.
        retryCompleter.complete(const Right('Message resent successfully'));
        await tester.pump();
        await tester.pump();

        expect(find.text('Message resent successfully'), findsOneWidget);
        expect(find.byType(LoadingIndicator), findsNothing);
        expect(find.text('Something went wrong'), findsNothing);
      },
    );
  });
}
