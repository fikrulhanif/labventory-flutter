import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';
import '../../utils/token_storage.dart';

/// Attaches `Authorization: Bearer <token>` to every outgoing request
/// except `/auth/login` and `/auth/register` (Requirement 17.5).
class AuthInterceptor extends Interceptor {
  /// Endpoints that must NOT carry an Authorization header.
  static const List<String> _publicPaths = [
    ApiConstants.authLogin,
    ApiConstants.authRegister,
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
      final token = await TokenStorage.readToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    options.headers.putIfAbsent('Accept', () => 'application/json');
    handler.next(options);
  }
}
