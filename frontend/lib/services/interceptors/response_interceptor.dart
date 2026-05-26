import 'package:dio/dio.dart';

import '../../utils/token_storage.dart';

typedef OnUnauthenticated = void Function();

/// Normalizes the Labventory standardized envelope (Requirements
/// 17.1 — 17.4) before responses bubble up to services.
///
///   - On 401 Unauthenticated, the stored token is cleared and the host
///     app's [OnUnauthenticated] callback fires (typically: routing back
///     to /login).
///   - 422 validation responses are re-thrown as DioException so the
///     calling service can catch and surface field-level messages.
///   - Successful 2xx responses pass through untouched; the response
///     body shape is preserved so [ApiResponse.fromEnvelope] can decode
///     it at the call site.
class ResponseInterceptor extends Interceptor {
  ResponseInterceptor({required this.onUnauthenticated});

  final OnUnauthenticated onUnauthenticated;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode ?? 0;

    // Drop the cached token and notify the host on 401, even if the
    // server-side envelope is missing (defensive: any 401 means the
    // session is unusable from now on).
    if (status == 401) {
      await TokenStorage.clearToken();
      try {
        onUnauthenticated();
      } catch (_) {
        // The host callback should never break the response pipeline.
      }
    }

    handler.next(err);
  }
}
