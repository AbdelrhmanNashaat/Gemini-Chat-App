import 'chat_message_model.dart';

class GeminiRequestModel {
  final List<ChatMessageModel> messages;

  const GeminiRequestModel({required this.messages});

  Map<String, dynamic> toJson() {
    return {
      'contents': messages.map((message) {
        return {
          'role': message.role,
          'parts': [
            {'text': message.message},
          ],
        };
      }).toList(),
    };
  }
}
