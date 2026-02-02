import 'dart:developer';

import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'chat_repo.dart';

class ChatRepoImpl extends ChatRepo {
  final GeminiChatService geminiChatService;
  ChatRepoImpl({required this.geminiChatService});
  @override
  Future<Either<Failure, String>> sendMessage({required String message}) async {
    try {
      final response = await geminiChatService.generateText(prompt: message);
      log('response: $response');
      return Right(response);
    } catch (ex) {
      if (ex is DioException) {
        log('server error: ${ex.message}');
        return Left(ServerFailure.fromDioException(ex));
      } else {
        log('error: $ex');
        return Left(ServerFailure(errorMessage: ex.toString()));
      }
    }
  }
}
