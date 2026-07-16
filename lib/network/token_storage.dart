import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps the JWT access token in secure storage — never in SharedPreferences,
/// which stores plaintext.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kToken = 'bodyx.access_token';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _kToken);

  Future<void> saveToken(String token) => _storage.write(key: _kToken, value: token);

  Future<void> clearToken() => _storage.delete(key: _kToken);
}
