import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // for IOHttpClientAdapter (Dio v5)
import 'package:flutter/foundation.dart';

import '../utils/constant.dart';

class DioClient {
  // Singleton
  static final DioClient instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() => instance;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: Constant.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
        },
      ),
    );

    // Keep-alive, connection pool (mobile/desktop). Browser handles this on web.
    if (!kIsWeb) {
      final adapter = dio.httpClientAdapter as IOHttpClientAdapter;
      // ignore: deprecated_member_use
      adapter.onHttpClientCreate = (HttpClient client) {
        client.idleTimeout = const Duration(seconds: 30);
        client.connectionTimeout = const Duration(seconds: 15);
        client.maxConnectionsPerHost = 8;
        return client;
      };
    }
  }

  /// Call this when your token changes
  void setAuthToken(String? token) {
    if (token == null || token.isEmpty) {
      dio.options.headers.remove(HttpHeaders.authorizationHeader);
    } else {
      dio.options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
  }

  /// If you need to set/override any header at runtime
  void setHeader(String key, String? value) {
    if (value == null) {
      dio.options.headers.remove(key);
    } else {
      dio.options.headers[key] = value;
    }
  }
}
