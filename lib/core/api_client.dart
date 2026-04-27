import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.example.com/', // Gerçek API ile değiştirilecek
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // API anahtarı veya token burada eklenebilir
          options.headers['Authorization'] = 'Bearer YOUR_TOKEN';
          return handler.next(options);
        },
      ),
    );
}
