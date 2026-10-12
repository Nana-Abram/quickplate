/// Form field validators. Each returns an error message, or null when valid.
abstract final class Validators {
  static const int minPasswordLength = 8;

  // Deliberately loose: Firebase does the real check, this only catches typos.
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email address.';
    if (!_email.hasMatch(email)) return 'Enter a valid email address.';
    return null;
  }

  /// For sign-in: any non-empty password, since older accounts may predate
  /// the length rule.
  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password.';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Choose a password.';
    if (value.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() password) {
    return (value) {
      if (value == null || value.isEmpty) return 'Repeat your password.';
      if (value != password()) return 'Passwords do not match.';
      return null;
    };
  }

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name.';
    if (name.length > 50) return 'Keep your name under 50 characters.';
    return null;
  }
}
