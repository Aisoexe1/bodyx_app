/// OAuth client IDs, supplied at build time via --dart-define (same pattern
/// as API_BASE_URL) so no code change is needed once real values exist:
///   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...apps.googleusercontent.com
///
/// Empty until then — Google/Apple sign-in are hidden on any platform where
/// their package has no support, and will fail server-side (501) even where
/// shown until the backend's matching GOOGLE_CLIENT_ID/APPLE_CLIENT_ID env
/// vars are set to the same values.
class OAuthConfig {
  OAuthConfig._();

  /// The Google Cloud "Web application" OAuth client ID — required so
  /// google_sign_in returns a verifiable idToken on Android, not just iOS.
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
}
