import '../../features/chat/data/models/chat_message_model.dart';

mixin ChatServiceValidationMixin {
  void validateInputMessages(List<ChatMessageModel> messages) {
    if (messages.isEmpty) {
      throw Exception('Messages list cannot be empty');
    }

    final hasValidMessage = messages.any(
      (message) => message.message.trim().isNotEmpty,
    );

    if (!hasValidMessage) {
      throw Exception('All messages are empty');
    }
  }

  String validateOutputText(String text) {
    final cleaned = text.trim();

    if (cleaned.isEmpty) {
      throw Exception('AI returned empty response');
    }

    return cleaned;
  }
}
