import 'dart:developer';
import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/core/mixin/chat_service_validation_mixin.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/chat_repo.dart';
import '../models/chat_message_model.dart';

class GeminiChatRepoImpl extends ChatRepo with ChatServiceValidationMixin {
  final GeminiChatService geminiChatService;
  GeminiChatRepoImpl({required this.geminiChatService});

  @override
  Future<Either<Failure, String>> sendMessage({
    required List<ChatMessageModel> messages,
  }) async {
    try {
      validateInputMessages(messages);
      final response = await geminiChatService.generateText(messages: messages);
      validateOutputText(response.text);
      return Right(response.text.trim());
    } on ServerFailure catch (failure) {
      log('[ChatRepo] ServerFailure: ${failure.errorMessage}');
      return Left(failure);
    } on DioException catch (e) {
      log('[ChatRepo] DioException: ${e.message}');
      return Left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('[ChatRepo] Unexpected: $e');
      return Left(ServerFailure(errorMessage: e.toString()));
    }
  }
}
