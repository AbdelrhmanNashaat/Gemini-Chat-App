import 'package:dio/dio.dart';

abstract class Failure {
  final String errorMessage;
  const Failure({required this.errorMessage});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.errorMessage});

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
