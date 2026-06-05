import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import '../utils/token_storage.dart';
import 'dio_client.dart';

/// Result returned from auth endpoints that issue a Sanctum token
/// (register / login).
class AuthSession {
  const AuthSession({required this.user, required this.token});

  final User user;
  final String token;
}

/// Wraps the `/api/auth/*` endpoints into a typed surface.
///
/// Validates Requirements 1.7, 2.1, 3.1, 3.4, 12.1 — 12.5.
///
/// All envelope handling is centralized here so screens can rely on
/// strongly-typed `ApiResponse<T>` rather than raw Dio responses.
class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// `POST /auth/register` (Requirement 1.7).
  ///
  /// IMPORTANT — registration intentionally does NOT persist the
  /// returned Sanctum token. We require students to sign in explicitly
  /// after creating an account, so the app cannot be used without
  /// proving credentials at least once. The backend keeps issuing a
  /// token for backwards compatibility, but Flutter discards it.
  Future<ApiResponse<AuthSession>> register({
    required String name,
    required String nim,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.authRegister,
      data: {
        'name': name,
        'nim': nim,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return _handleAuthResponse(response, persistToken: false);
  }

  /// `POST /auth/login` (Requirements 2.1, 19.1). The [login] value may be
  /// a student NIM or an admin/laboran email; the backend resolves either.
  Future<ApiResponse<AuthSession>> login({
    required String login,
    required String password,
  }) async {
    final response = await _dio.post<dynamic>(
      ApiConstants.authLogin,
      data: {'login': login, 'password': password},
    );

    return _handleAuthResponse(response, persistToken: true);
  }

  /// `POST /auth/logout` (Requirement 3.4). Always clears the locally
  /// stored token even if the server reports a transient failure so the
  /// app does not get stuck logged-in with an unusable token.
  Future<ApiResponse<void>> logout() async {
    try {
      final response = await _dio.post<dynamic>(ApiConstants.authLogout);
      await TokenStorage.clearToken();
      return _toApiResponse<void>(response);
    } finally {
      await TokenStorage.clearToken();
    }
  }

  /// `GET /auth/me` (Requirement 3.1).
  Future<ApiResponse<User>> me() async {
    final response = await _dio.get<dynamic>(ApiConstants.authMe);

    return ApiResponse<User>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) {
        final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
        return User.fromJson((map['user'] as Map).cast<String, dynamic>());
      },
      statusCode: response.statusCode,
    );
  }

  /// `PATCH /auth/profile` (Requirements 12.1 — 12.5).
  ///
  /// Pass `password` + `currentPassword` (+ confirmation) only when
  /// changing the password. `nim`, `role`, `status` are intentionally
  /// not exposed.
  Future<ApiResponse<User>> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (currentPassword != null) body['current_password'] = currentPassword;
    if (password != null) body['password'] = password;
    if (passwordConfirmation != null) {
      body['password_confirmation'] = passwordConfirmation;
    }

    final response = await _dio.patch<dynamic>(
      ApiConstants.authProfile,
      data: body,
    );

    return ApiResponse<User>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) {
        final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
        return User.fromJson((map['user'] as Map).cast<String, dynamic>());
      },
      statusCode: response.statusCode,
    );
  }

  // ---- internal helpers ----

  Future<ApiResponse<AuthSession>> _handleAuthResponse(
    Response<dynamic> response, {
    required bool persistToken,
  }) async {
    final result = ApiResponse<AuthSession>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) {
        final map = (data as Map?)?.cast<String, dynamic>() ?? const {};
        return AuthSession(
          user: User.fromJson((map['user'] as Map).cast<String, dynamic>()),
          token: map['token'] as String,
        );
      },
      statusCode: response.statusCode,
    );

    if (result.success && result.data != null && persistToken) {
      await TokenStorage.saveToken(result.data!.token);
    }

    return result;
  }

  ApiResponse<T> _toApiResponse<T>(Response<dynamic> response) {
    return ApiResponse<T>.fromEnvelope(
      _envelopeFrom(response),
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _envelopeFrom(Response<dynamic> response) {
    final raw = response.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return {'success': false, 'message': 'Unexpected response shape'};
  }
}
