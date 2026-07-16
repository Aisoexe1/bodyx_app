import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Owns the account lifecycle: register/login create a session (JWT stored
/// securely), [restoreSession] silently re-validates a stored session on
/// app launch, and [signOut] clears it. All network/token concerns are
/// contained here so [AppState] never touches an HTTP client or the
/// keychain directly.
abstract class AuthRepository {
  Future<UserProfile> register({
    required String email,
    required String username,
    required String password,
  });

  Future<UserProfile> login({required String email, required String password});

  /// Returns the restored profile if a stored session is still valid, or
  /// `null` if there's no session, the token expired/was rejected, or the
  /// server couldn't be reached. Never throws — callers always have a safe
  /// fallback to the local cache.
  Future<UserProfile?> restoreSession();

  Future<void> signOut();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({ApiClient? client, TokenStorage? tokenStorage})
      : _client = client ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _client;
  final TokenStorage _tokenStorage;

  @override
  Future<UserProfile> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final json = await _client.post('/auth/register', {
      'email': email,
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    await _tokenStorage.saveToken(json['accessToken'] as String);
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> login({required String email, required String password}) async {
    final json = await _client.post('/auth/login', {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    await _tokenStorage.saveToken(json['accessToken'] as String);
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null) return null;

    try {
      final json = await _client.get('/users/me') as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _tokenStorage.clearToken();
      }
      return null;
    } catch (e) {
      debugPrint('Session restore unreachable: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() => _tokenStorage.clearToken();
}
