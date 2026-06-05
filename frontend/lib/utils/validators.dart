/// Shared form validators used by login, register, and profile-edit screens.
///
/// Each validator returns either `null` (valid) or a human-readable
/// error string the field's [FormFieldValidator] can render directly.
class Validators {
  Validators._();

  static String? required(String? value, {String label = 'Kolom ini'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi.';
    }
    return null;
  }

  static String? nim(String? value) {
    final base = required(value, label: 'NIM');
    if (base != null) return base;
    if (value!.length < 4) {
      return 'NIM minimal 4 karakter.';
    }
    return null;
  }

  /// Validator for the unified login field that accepts either a NIM or
  /// an email (Requirement 19.1). Only checks that something plausible
  /// was entered; the backend does the authoritative resolution.
  static String? loginIdentifier(String? value) {
    final base = required(value, label: 'NIM atau Email');
    if (base != null) return base;
    if (value!.trim().length < 4) {
      return 'Masukkan NIM atau email yang valid.';
    }
    return null;
  }

  static String? email(String? value) {
    final base = required(value, label: 'Email');
    if (base != null) return base;
    final pattern = RegExp(r'^[\w.\-+]+@[\w-]+(\.[\w-]+)+$');
    if (!pattern.hasMatch(value!.trim())) {
      return 'Masukkan alamat email yang valid.';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final base = required(value, label: 'Kata sandi');
    if (base != null) return base;
    if (value!.length < minLength) {
      return 'Kata sandi minimal $minLength karakter.';
    }
    return null;
  }

  /// Returns a validator that compares the field value to whatever
  /// `originalProvider()` returns at validation time. Pass a closure
  /// (e.g. `() => passwordController.text`) instead of a snapshot
  /// string so the validator always sees the current value rather
  /// than the value as of the last `build()`.
  static String? Function(String?) confirmPassword(
    String Function() originalProvider,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Konfirmasi kata sandi Anda.';
      }
      if (value != originalProvider()) {
        return 'Kata sandi tidak cocok.';
      }
      return null;
    };
  }

  static String? minLength(
    String? value,
    int min, {
    String label = 'This field',
  }) {
    final base = required(value, label: label);
    if (base != null) return base;
    if (value!.trim().length < min) {
      return '$label must be at least $min characters.';
    }
    return null;
  }
}
