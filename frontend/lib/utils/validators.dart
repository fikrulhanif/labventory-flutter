/// Shared form validators used by login, register, and profile-edit screens.
///
/// Each validator returns either `null` (valid) or a human-readable
/// error string the field's [FormFieldValidator] can render directly.
class Validators {
  Validators._();

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  static String? nim(String? value) {
    final base = required(value, label: 'NIM');
    if (base != null) return base;
    if (value!.length < 4) {
      return 'NIM must be at least 4 characters.';
    }
    return null;
  }

  static String? email(String? value) {
    final base = required(value, label: 'Email');
    if (base != null) return base;
    final pattern = RegExp(r'^[\w.\-+]+@[\w-]+(\.[\w-]+)+$');
    if (!pattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    final base = required(value, label: 'Password');
    if (base != null) return base;
    if (value!.length < minLength) {
      return 'Password must be at least $minLength characters.';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Confirm your password.';
      }
      if (value != original) {
        return 'Passwords do not match.';
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
