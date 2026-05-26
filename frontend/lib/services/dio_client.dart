import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/response_interceptor.dart';

/// Singleton Dio factory.
///
/// All API services route through `DioClient.instance` so the auth /
/// response / logging interceptors are attached exactly once.
class DioClient {
  DioClient._();

  static Dio? _instance;

  /// Set by `main.dart` so the response interceptor can hand control
  /// back to the router on 401 (e.g. pop to /login).
  static void Function()? _onUnauthenticated;

  /// Configure the global on-401 callback. Must be called before the
  /// first authenticated request fires.
  static void configureOnUnauthenticated(void Function() callback) {
    _onUnauthenticated = callback;
  }

  /// Singleton accessor. Lazily builds the Dio instance the first time
  /// it is requested.
  static Dio get instance => _instance ??= _build();

  /// Reset the singleton; mostly useful for tests.
  @visibleForTesting
  static void reset() {
    _instance = null;
  }

  static Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
        // Don't auto-throw on 4xx; services translate the envelope
        // themselves so they can keep typed errors.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      ResponseInterceptor(onUnauthenticated: () => _onUnauthenticated?.call()),
      if (kDebugMode)
        LogInterceptor(
          requestHeader: false,
          responseHeader: false,
          requestBody: true,
          responseBody: true,
        ),
    ]);

    return dio;
  }
}
