import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Thrown by [AuthRepository.loginWithGoogle]/[loginWithApple] when the
/// backend has verified the token but found no existing account for that
/// email — the caller must collect a username from the user and call
/// [AuthRepository.completeGoogleSignUp]/[completeAppleSignUp] with the
/// same token to actually create the account.
class OAuthNeedsUsername implements Exception {
  OAuthNeedsUsername({required this.email, required this.token});
  final String email;

  /// The Google idToken or Apple identityToken — re-sent verbatim to the
  /// matching `complete` endpoint (tokens are short-lived but easily long
  /// enough to cover the time it takes to type a username).
  final String token;
}

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

  /// Requests a password-reset code for [email]. Always succeeds (the
  /// backend never reveals whether the email is registered) — returns the
  /// raw code only in backend dev-mode (no SMTP configured yet), so the
  /// flow is testable without an inbox; `null` once real email is wired up.
  Future<String?> forgotPassword(String email);

  /// Verifies the emailed [code] and sets [newPassword], logging the user
  /// in immediately on success (same as [login]). Throws [ApiException] on
  /// an invalid/expired/reused code or a password that fails strength rules.
  Future<UserProfile> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Verifies a Google ID token server-side and logs in an existing
  /// same-provider account. Throws [OAuthNeedsUsername] if this email has
  /// no account yet (call [completeGoogleSignUp] next). Throws
  /// [ApiException] (401 invalid token, 409 if the email belongs to a
  /// different sign-in method, 501 if the backend's Google client ID isn't
  /// configured yet).
  Future<UserProfile> loginWithGoogle(String idToken);

  /// Creates a new Google-authenticated account with [username] (already
  /// validated available) and logs in. Throws [ApiException] on a 409
  /// (email or username taken in the moment between the two calls).
  Future<UserProfile> completeGoogleSignUp(String idToken, String username);

  /// Verifies an Apple identity token server-side and logs in an existing
  /// same-provider account. Throws [OAuthNeedsUsername] if this email has
  /// no account yet (call [completeAppleSignUp] next). Throws
  /// [ApiException] (401 invalid token, 409 if the email belongs to a
  /// different sign-in method, 501 if the backend's Apple client ID isn't
  /// configured yet).
  Future<UserProfile> loginWithApple(String identityToken);

  /// Creates a new Apple-authenticated account with [username] (already
  /// validated available) and logs in. Throws [ApiException] on a 409
  /// (email or username taken in the moment between the two calls).
  Future<UserProfile> completeAppleSignUp(String identityToken, String username);

  /// Returns the restored profile if a stored session is still valid, or
  /// `null` if there's no session, the token expired/was rejected, or the
  /// server couldn't be reached. Never throws — callers always have a safe
  /// fallback to the local cache.
  Future<UserProfile?> restoreSession();

  Future<void> signOut();

  /// Permanently deletes the account and all server-side data for the
  /// signed-in user. Callers should treat this as best-effort: local data
  /// is wiped and the session ends regardless of whether this succeeds, so
  /// deletion is never blocked by an unreachable server.
  Future<void> deleteAccount();
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
  Future<String?> forgotPassword(String email) async {
    final json = await _client.post('/auth/forgot-password', {'email': email})
        as Map<String, dynamic>;
    return json['devCode'] as String?;
  }

  @override
  Future<UserProfile> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final json = await _client.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    }) as Map<String, dynamic>;
    await _tokenStorage.saveToken(json['accessToken'] as String);
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> loginWithGoogle(String idToken) async {
    final json = await _client.post('/auth/oauth/google', {'idToken': idToken})
        as Map<String, dynamic>;
    if (json['needsUsername'] == true) {
      throw OAuthNeedsUsername(email: json['email'] as String, token: idToken);
    }
    await _tokenStorage.saveToken(json['accessToken'] as String);
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> completeGoogleSignUp(String idToken, String username) async {
    final json = await _client.post('/auth/oauth/google/complete',
        {'idToken': idToken, 'username': username}) as Map<String, dynamic>;
    await _tokenStorage.saveToken(json['accessToken'] as String);
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> loginWithApple(String identityToken) async {
    final json = await _client.post('/auth/oauth/apple', {'identityToken': identityToken})
        as Map<String, dynamic>;
    if (json['needsUsername'] == true) {
      throw OAuthNeedsUsername(email: json['email'] as String, token: identityToken);
    }
    await _tokenStorage.saveToken(json['accessToken'] as String);
    return UserProfile.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> completeAppleSignUp(String identityToken, String username) async {
    final json = await _client.post('/auth/oauth/apple/complete',
        {'identityToken': identityToken, 'username': username}) as Map<String, dynamic>;
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

  @override
  Future<void> deleteAccount() async {
    await _client.delete('/users/me');
    await _tokenStorage.clearToken();
  }
}
