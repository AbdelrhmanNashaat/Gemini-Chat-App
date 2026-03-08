import 'dart:developer';
import 'dart:math' show min;
import 'package:dio/dio.dart';

abstract class Failure {
  final String errorMessage;
  const Failure({required this.errorMessage});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.errorMessage});

  static const _retryableDioTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  static const _retryableStatusCodes = {408, 429, 500};

  static const _retryableMessageKeywords = [
    'internal error',
    'backend error',
    'timeout',
    'overloaded',
    'try again',
    'temporarily unavailable',
  ];

  static bool isRetryable(DioException e) {
    if (_retryableDioTypes.contains(e.type)) return true;

    final statusCode = e.response?.statusCode;
    if (statusCode != null && _retryableStatusCodes.contains(statusCode)) {
      return true;
    }

    final message = _extractMessage(e.response?.data).toLowerCase();
    if (_retryableMessageKeywords.any((kw) => message.contains(kw))) {
      return true;
    }

    return false;
  }

  static Future<T> withRetry<T>(
    Future<T> Function() request, {
    int maxAttempts = 3,
    int baseDelayMs = 500,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await request();
      } on DioException catch (e) {
        final failure = ServerFailure.fromDioException(e);

        log(
          '[ServerFailure] attempt=${attempt + 1}/$maxAttempts '
          'type=${e.type} status=${e.response?.statusCode} '
          'message="${failure.errorMessage}"',
          name: 'ServerFailure',
        );

        final isLastAttempt = attempt == maxAttempts - 1;

        if (!isRetryable(e) || isLastAttempt) throw failure;

        final delay = baseDelayMs * (1 << min(attempt, 4));
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    throw const ServerFailure(errorMessage: 'Unexpected error occurred');
  }

  factory ServerFailure.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
        return const ServerFailure(
          errorMessage: 'Connection timeout, please try again',
        );
      case DioExceptionType.sendTimeout:
        return const ServerFailure(
          errorMessage: 'Send timeout, please try again',
        );
      case DioExceptionType.receiveTimeout:
        return const ServerFailure(
          errorMessage: 'Receive timeout, please try again',
        );
      case DioExceptionType.badCertificate:
        return const ServerFailure(errorMessage: 'Bad certificate');
      case DioExceptionType.cancel:
        return const ServerFailure(errorMessage: 'Request was cancelled');
      case DioExceptionType.connectionError:
        return const ServerFailure(errorMessage: 'No internet connection');
      case DioExceptionType.badResponse:
        return ServerFailure.fromResponse(
          statusCode: dioException.response?.statusCode ?? 0,
          response: dioException.response?.data,
        );
      default:
        return const ServerFailure(errorMessage: 'Unexpected error occurred');
    }
  }

  factory ServerFailure.fromResponse({
    required int statusCode,
    required dynamic response,
  }) {
    final String message = _extractMessage(response);

    if (statusCode == 400 || statusCode == 401 || statusCode == 403) {
      return ServerFailure(errorMessage: message);
    } else if (statusCode == 404) {
      return const ServerFailure(
        errorMessage: 'Your request was not found, please try later',
      );
    } else if (statusCode == 500) {
      return const ServerFailure(
        errorMessage: 'Internal server error, please try later',
      );
    } else {
      return const ServerFailure(
        errorMessage: 'Something went wrong, please try later',
      );
    }
  }

  static String _extractMessage(dynamic response) {
    if (response is Map<String, dynamic>) {
      if (response['error'] is Map && response['error']['message'] != null) {
        return response['error']['message'].toString();
      }
      if (response['message'] != null) {
        return response['message'].toString();
      }
    }
    return 'Something went wrong, please try later';
  }
}
