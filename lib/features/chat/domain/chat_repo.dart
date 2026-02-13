import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

import '../data/models/chat_message_model.dart';

abstract class ChatRepo {
  Future<Either<Failure, String>> sendMessage({
    required List<ChatMessageModel> messages,
  });
}
