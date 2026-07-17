/// Shared client-side mirror of the backend's password rule (see
/// bodyx_backend/app/schemas/user.py's validate_password_strength):
/// at least 6 characters, containing a letter and a digit.
class PasswordStrength {
  PasswordStrength._();

  static final _hasLetter = RegExp(r'[A-Za-z]');
  static final _hasDigit = RegExp(r'\d');

  static const String hint = 'At least 6 characters, with a letter and a number';

  static bool isValid(String password) =>
      password.length >= 6 && _hasLetter.hasMatch(password) && _hasDigit.hasMatch(password);
}
