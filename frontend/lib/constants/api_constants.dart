import 'app_config.dart';

/// Centralized API endpoint catalog so screens never hardcode URL paths.
///
/// The base URL is read from [AppConfig] (which encodes the laptop / WiFi
/// IP shorthand) and is also overridable at build time via
/// `--dart-define=API_BASE_URL=...` for ad-hoc testing.
class ApiConstants {
  ApiConstants._();

  /// The active base URL — pulls from `AppConfig.apiBaseUrl`.
  static String get baseUrl => AppConfig.apiBaseUrl;

  // ---- Auth (Requirement 17.5) ----
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authProfile = '/auth/profile';

  // ---- Catalog ----
  static const String categories = '/categories';
  static const String inventories = '/inventories';

  /// `GET /inventories/{id}` (Requirement 7.5).
  static String inventoryDetail(int id) => '/inventories/$id';

  // ---- Loans ----
  static const String loans = '/loans';

  /// `GET /loans/{id}` (Requirement 11.3).
  static String loanDetail(int id) => '/loans/$id';

  /// `GET /loans/{id}/document` — gated KTM stream (Requirement 18.6).
  static String loanDocument(int id) => '/loans/$id/document';
}
