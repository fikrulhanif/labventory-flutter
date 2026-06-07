import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed the onboarding flow.
///
/// Uses a version key — if the onboarding version changes, the flag
/// resets automatically so users see the updated onboarding. Also
/// resets on logout so the next person using the device sees it.
class OnboardingStorage {
  OnboardingStorage._();

  static const String _key = 'labventory.onboarding_done';
  // Bump this when onboarding slides change meaningfully.
  static const String _versionKey = 'labventory.onboarding_version';
  static const int _currentVersion = 1;

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    // If the version stored doesn't match, treat as not done.
    final storedVersion = prefs.getInt(_versionKey) ?? 0;
    if (storedVersion < _currentVersion) return false;
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    await prefs.setInt(_versionKey, _currentVersion);
  }

  /// Called on logout so the next fresh session sees onboarding again.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_versionKey);
  }
}
