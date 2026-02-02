import 'package:dio/dio.dart';

class ApiService {
  final Dio dio;

  ApiService({required this.dio});

  Future<Map<String, dynamic>> post({
    required Map<String, dynamic>? headers,
    required Object? data,
    required String baseUrl,
  }) async {
    final response = await dio.post(
      baseUrl,
      options: Options(headers: headers),
      data: data,
    );
    return response.data;
  }
}
