import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../l10n/gen/app_localizations.dart';
import 'token_storage.dart';

/// Thrown for any non-2xx API response. [message] is the server's `detail`
/// field when present, otherwise a generic description. Server-provided
/// messages come from our own FastAPI backend and are always in English —
/// localizing those would require the backend to accept the client's
/// locale, which is out of scope here; only the purely client-side
/// fallbacks below (no server response reached at all) are localized.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Maps any error thrown by the network layer to a short, user-facing
/// message — used by screens that surface auth failures.
String describeApiError(BuildContext context, Object error) {
  if (error is ApiException) return error.message;
  final l10n = AppLocalizations.of(context)!;
  if (error is TimeoutException || error is SocketException) {
    return l10n.apiErrorCantReachServer;
  }
  return l10n.apiErrorGeneric;
}

/// Thin JSON/HTTP client for the BodyX backend. Every call carries an 8s
/// timeout so an unreachable backend never hangs the UI; the Android
/// emulator can't reach `localhost` directly, hence the `10.0.2.2` default.
class ApiClient {
  ApiClient({String? baseUrl, TokenStorage? tokenStorage, http.Client? httpClient})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000/api/v1',
            ),
        _tokenStorage = tokenStorage ?? TokenStorage(),
        _client = httpClient ?? http.Client();

  final String baseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;

  static const _timeout = Duration(seconds: 8);

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) =>
      _send('PATCH', path, body);
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) =>
      _send('PUT', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$baseUrl$path');
    final token = await _tokenStorage.readToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encodedBody = body != null ? jsonEncode(body) : null;

    final http.Response response = await _dispatch(method, uri, headers, encodedBody)
        .timeout(_timeout);

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(response.statusCode, _extractErrorMessage(decoded, response.statusCode));
  }

  /// FastAPI's `detail` is a plain string for our own `HTTPException`s, but a
  /// list of `{msg, loc, ...}` objects for Pydantic validation errors (422) —
  /// without this, a validation failure would surface as a raw Dart List
  /// dump instead of a readable message.
  String _extractErrorMessage(dynamic decoded, int statusCode) {
    if (decoded is! Map || decoded['detail'] == null) {
      return 'Request failed ($statusCode)';
    }
    final detail = decoded['detail'];
    if (detail is List) {
      final messages = detail
          .map((e) => e is Map && e['msg'] != null ? e['msg'].toString() : e.toString())
          // Pydantic prefixes custom validator messages with "Value error, ".
          .map((m) => m.replaceFirst(RegExp(r'^Value error,\s*'), ''))
          .toList();
      return messages.isEmpty ? 'Request failed ($statusCode)' : messages.join('; ');
    }
    return detail.toString();
  }

  Future<http.Response> _dispatch(
      String method, Uri uri, Map<String, String> headers, String? body) {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, headers: headers, body: body);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: body);
      case 'PUT':
        return _client.put(uri, headers: headers, body: body);
      case 'DELETE':
        return _client.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
}
