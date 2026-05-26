import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../utils/token_storage.dart';

/// State of the auth flow consumed by the splash/login/register screens.
enum AuthState {
  /// Initial — splash hasn't decided yet.
  unknown,

  /// No valid token in storage.
  unauthenticated,

  /// We have a token AND a fresh `User` from `/auth/me`.
  authenticated,
}

/// ChangeNotifier that owns the current authentication state, the
/// authenticated user, and the loading + error flags consumed by
/// auth screens.
///
/// Validates Requirements 1.1, 2.1, 3.1, 3.4, 12.1.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  AuthState _state = AuthState.unknown;
  AuthState get state => _state;

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, List<String>> _validationErrors = {};
  Map<String, List<String>> get validationErrors => _validationErrors;

  bool get isAuthenticated => _state == AuthState.authenticated;

  // -----------------------------------------------------------
  // Bootstrap (splash)
  // -----------------------------------------------------------

  /// Decide initial state at app launch:
  ///   no token            -> AuthState.unauthenticated
  ///   token + /me success -> AuthState.authenticated (user populated)
  ///   token + /me 401     -> token cleared, AuthState.unauthenticated
  Future<void> bootstrap() async {
    final hasToken = await TokenStorage.hasToken();
    if (!hasToken) {
      _setState(AuthState.unauthenticated);
      return;
    }

    try {
      final response = await _service.me();
      if (response.success && response.data != null) {
        _user = response.data;
        _setState(AuthState.authenticated);
      } else {
        await TokenStorage.clearToken();
        _setState(AuthState.unauthenticated);
      }
    } catch (_) {
      await TokenStorage.clearToken();
      _setState(AuthState.unauthenticated);
    }
  }

  // -----------------------------------------------------------
  // Public actions
  // -----------------------------------------------------------

  Future<bool> register({
    required String name,
    required String nim,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return _runWithLoading(() async {
      final response = await _service.register(
        name: name,
        nim: nim,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      return _applyAuthResponse(response);
    });
  }

  Future<bool> login({required String nim, required String password}) async {
    return _runWithLoading(() async {
      final response = await _service.login(nim: nim, password: password);
      return _applyAuthResponse(response);
    });
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.logout();
    } finally {
      _user = null;
      _validationErrors = {};
      _errorMessage = null;
      _isLoading = false;
      _setState(AuthState.unauthenticated);
    }
  }

  /// Refresh the current user from `/auth/me`. Used after profile edits
  /// or when the screen wants to re-validate auth.
  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    try {
      final response = await _service.me();
      if (response.success && response.data != null) {
        _user = response.data;
        notifyListeners();
      } else if (response.statusCode == 401) {
        await TokenStorage.clearToken();
        _user = null;
        _setState(AuthState.unauthenticated);
      }
    } catch (_) {
      // Soft fail; keep the existing cached user.
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    return _runWithLoading(() async {
      final response = await _service.updateProfile(
        name: name,
        email: email,
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (response.success && response.data != null) {
        _user = response.data;
        return true;
      }

      _captureErrors(response);
      return false;
    });
  }

  /// Called by the host (e.g. router) when the response interceptor
  /// detects a 401 outside the splash bootstrap.
  void onTokenRevoked() {
    _user = null;
    _setState(AuthState.unauthenticated);
  }

  // -----------------------------------------------------------
  // Internals
  // -----------------------------------------------------------

  bool _applyAuthResponse(ApiResponse<AuthSession> response) {
    if (response.success && response.data != null) {
      _user = response.data!.user;
      _setState(AuthState.authenticated);
      return true;
    }

    _captureErrors(response);
    return false;
  }

  void _captureErrors<T>(ApiResponse<T> response) {
    _errorMessage = response.message.isNotEmpty
        ? response.message
        : 'Something went wrong. Please try again.';
    _validationErrors = response.errors ?? {};
  }

  Future<bool> _runWithLoading(Future<bool> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    _validationErrors = {};
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setState(AuthState next) {
    _state = next;
    notifyListeners();
  }
}
