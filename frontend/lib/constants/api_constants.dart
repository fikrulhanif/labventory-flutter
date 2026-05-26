/// Centralized API endpoint catalog so screens never hardcode URL paths.
///
/// The base URL is read from a `--dart-define=API_BASE_URL=...` build-time
/// flag and falls back to the Android emulator host (`10.0.2.2`) which is
/// the only reliable way for the emulator to reach the host machine's
/// `php artisan serve`. iOS simulator and desktop targets need to override
/// this via `--dart-define`.
class ApiConstants {
  ApiConstants._();

  /// Reach Laravel's `php artisan serve` on http://127.0.0.1:8000 from an
  /// Android emulator via the loopback alias 10.0.2.2.
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api';

  /// Override at build time: `flutter run --dart-define=API_BASE_URL=...`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

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
