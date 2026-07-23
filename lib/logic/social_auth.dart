import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../network/oauth_config.dart';

/// Thin wrappers around the Google/Apple native SDKs, returning the raw
/// token for backend verification (see AuthRepository.loginWithGoogle/
/// loginWithApple) — or null if the user cancelled the system sign-in
/// sheet, which isn't an error, just a no-op for the caller.
class SocialAuth {
  SocialAuth._();

  /// `sign_in_with_apple` has no Windows support, and `google_sign_in`
  /// targets mobile/web, not desktop — so both buttons are hidden outside
  /// Android/iOS rather than shown and silently failing every tap.
  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static final _googleSignIn = GoogleSignIn(
    scopes: const ['email'],
    // Required so google_sign_in returns a verifiable idToken on Android,
    // not just iOS — empty (unset) until a real client ID is configured.
    serverClientId:
        OAuthConfig.googleServerClientId.isEmpty ? null : OAuthConfig.googleServerClientId,
  );

  static Future<String?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null; // user cancelled
    final auth = await account.authentication;
    return auth.idToken;
  }

  static Future<String?> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      return credential.identityToken;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }
}
