import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

abstract class ChatRepo {
  Future<Either<Failure, String>> sendMessage({required String message});
}
