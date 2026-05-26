/// Centralized network configuration for Labventory.
///
/// ============================================================
/// Ganti `baseUrl` sesuai kondisi jaringan saat ini.
/// Cara cek IP laptop: buka CMD -> ketik "ipconfig"
/// Cari "Wireless LAN adapter Wi-Fi" -> IPv4 Address.
///
/// Pastikan Laravel jalan di semua interface, bukan cuma 127.0.0.1:
///     php artisan serve --host=0.0.0.0 --port=8000
/// ============================================================
class AppConfig {
  AppConfig._();

  // Untuk testing di browser laptop (web) atau emulator desktop:
  // static const String baseUrl = "http://127.0.0.1:8000/api";

  // Untuk Android emulator (10.0.2.2 = host machine):
  // static const String baseUrl = "http://10.0.2.2:8000/api";

  // Untuk testing di HP fisik via USB debugging Laptop pakai IP HP,
  // static const String baseUrl = "http://10.233.70.83:8000/api";

  // laptop & HP pakai WIFI ROUTER yang sama:
  // static const String baseUrl = "http://192.168.1.4:8000/api";

  // Kalau IP laptop berubah, update string di bawah ini.
  // ============================================================
  static const String baseUrl = "http://192.168.1.4:8000/api";

  /// Optional override at build time without editing this file:
  ///     flutter run --dart-define=API_BASE_URL=http://1.2.3.4:8000/api
  ///
  /// When the env value is empty, the hardcoded `baseUrl` above wins.
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// The URL the rest of the app should actually use.
  static String get apiBaseUrl =>
      _envBaseUrl.isNotEmpty ? _envBaseUrl : baseUrl;
}
