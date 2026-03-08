import 'dart:developer';
import 'package:chat_bot_gemini/core/errors/failures.dart';
import 'package:chat_bot_gemini/core/services/gemini_chat_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/chat_repo.dart';
import '../models/chat_message_model.dart';

class GeminiChatRepoImpl extends ChatRepo {
  final GeminiChatService geminiChatService;
  GeminiChatRepoImpl({required this.geminiChatService});

  @override
  Future<Either<Failure, String>> sendMessage({
    required List<ChatMessageModel> messages,
  }) async {
    final validationError = _validate(messages);
    if (validationError != null) return Left(validationError);

    try {
      final response = await geminiChatService.generateText(messages: messages);
      if (response.trim().isEmpty) {
        return const Left(
          ServerFailure(errorMessage: 'Received empty response from service'),
        );
      }
      return Right(response);
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

  ServerFailure? _validate(List<ChatMessageModel> messages) {
    if (messages.isEmpty) {
      return const ServerFailure(errorMessage: 'Messages list is empty');
    }
    final invalid = messages.any(
      (m) =>
          m.message.trim().isEmpty ||
          m.role.trim().isEmpty ||
          (m.role != 'user' && m.role != 'model'),
    );
    if (invalid) {
      return const ServerFailure(
        errorMessage: 'Each message must have a valid role and non-empty text',
      );
    }
    return null;
  }
}
