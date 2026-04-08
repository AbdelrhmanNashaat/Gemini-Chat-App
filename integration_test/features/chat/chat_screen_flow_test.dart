import 'package:chat_bot_gemini/features/chat/presentation/views/widgets/chat_view_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // should test the entire flow of sending a message in the chat screen, including:
  // 1. entering a message in the text field
  // 2. tapping the send button
  // 3. loading indicator appears
  // 4. user message appears in the chat
  // 5. bot response appears in the chat after loading
  // 6. error handling flow when the message fails to send, including tapping the resend button and successfully resending the message
  group('Test Sending Message Flow in Chat Screen', () {
    testWidgets('Send message and loading indicator appears', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ChatViewBody()));
      await tester.pumpAndSettle();
      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'Hello Gemini');
      await tester.pumpAndSettle();
    });
  });
}
