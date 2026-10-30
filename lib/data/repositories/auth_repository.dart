import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/git_service_config.dart';

/// Repository for managing authentication state and credentials.
/// Uses SharedPreferences with simple obfuscation for dev.
/// For production, replace with flutter_secure_storage or Keychain.
class AuthRepository {
  late final SharedPreferencesAsync _prefs;

  AuthRepository() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = SharedPreferencesAsync();
  }

  static const _keyConfig = 'git_service_config';
  static const _keyPat = 'git_pat';

  /// Simple storage for dev purposes only.
  /// NOT secure - for production use Keychain/Keystore.
  /// For dev, we store the raw token directly.
  String _obfuscate(String input) {
    return input; // Store as-is for dev
  }

  String _deobfuscate(String input) {
    return input; // Return as-is for dev
  }

  /// Save service config and PAT
  Future<void> saveConfig(GitServiceConfig config, String pat) async {
    print('💾 Saving credentials...');
    await _prefs.setString(_keyConfig, jsonEncode(config.toJson()));
    await _prefs.setString(_keyPat, _obfuscate(pat));
    print('✅ Credentials saved');
  }

  /// Load saved service config
  Future<GitServiceConfig?> loadConfig() async {
    final jsonString = await _prefs.getString(_keyConfig);
    print('📖 loadConfig: jsonString=$jsonString');
    if (jsonString == null) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final config = GitServiceConfig.fromJson(json);
      print('✅ Config loaded: ${config.type} at ${config.baseUrl}');
      return config;
    } catch (e) {
      print('❌ Config load error: $e');
      return null;
    }
  }

  /// Load saved PAT
  Future<String?> loadPat() async {
    final obfuscated = await _prefs.getString(_keyPat);
    print('📖 loadPat: obfuscated=${obfuscated != null ? "[HIDDEN]" : "null"}');
    if (obfuscated == null) return null;
    final pat = _deobfuscate(obfuscated);
    print('✅ PAT loaded (first 10 chars: ${pat.substring(0, 10)}...)');
    return pat;
  }

  /// Check if credentials are stored
  Future<bool> hasCredentials() async {
    final pat = await loadPat();
    final config = await loadConfig();
    return pat != null && config != null;
  }

  /// Clear all stored credentials
  Future<void> clearCredentials() async {
    await _prefs.remove(_keyConfig);
    await _prefs.remove(_keyPat);
  }

  /// Validate credentials by making a test API call.
  /// Returns true if credentials are valid.
  /// Throws [AuthException] with specific error message on failure.
  Future<bool> validateCredentials(
    GitServiceConfig config,
    String pat,
  ) async {
    // Build headers for the specific service
    final headers = _buildHeaders(config, pat);

    // For GitHub, use the full URL (not just the API path)
    String endpoint;
    switch (config.type) {
      case GitServiceType.github:
        endpoint = '/user';
        break;
      case GitServiceType.gitlab:
        endpoint = '/user';
        break;
      case GitServiceType.gitea:
      case GitServiceType.custom:
        endpoint = '/api/v1/user';
        break;
    }

    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: headers,
    ));

    try {
      print('🔑 Connecting to ${config.baseUrl}$endpoint');
      print('📦 Headers: $headers');

      final response = await dio.get(endpoint);

      print('✅ Response status: ${response.statusCode}');
      print('✅ Response data: ${response.data}');

      return response.statusCode == 200;
    } on DioException catch (e) {
      // Print detailed error for debugging
      print('❌ DioException type: ${e.type}');
      print('❌ DioException message: ${e.message}');
      print('❌ DioException request: ${e.requestOptions.uri}');
      print('❌ DioException response status: ${e.response?.statusCode}');
      print('❌ DioException response data: ${e.response?.data}');

      // Provide specific error messages
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw AuthException(
            'Connection timeout to ${config.baseUrl}. Check your network.',
          );
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            throw AuthException('Invalid token. Please check your PAT.');
          } else if (e.response?.statusCode == 404) {
            throw AuthException(
              'API endpoint not found. URL: ${config.baseUrl}$endpoint',
            );
          } else {
            throw AuthException(
              'Server error ${e.response?.statusCode}: ${e.response?.data}',
            );
          }
        case DioExceptionType.connectionError:
          throw AuthException(
            'Cannot connect to ${config.baseUrl}. ' +
                'This may be a network/proxy issue or the server may be unreachable.',
          );
        case DioExceptionType.cancel:
          throw AuthException('Request was cancelled.');
        case DioExceptionType.unknown:
          throw AuthException(
            'Unknown error connecting to ${config.baseUrl}. ' +
                'Details: ${e.message}',
          );
        default:
          throw AuthException(
            'Connection failed: ${e.message}',
          );
      }
    } catch (e, stack) {
      print('❌ Unexpected error: $e');
      print('❌ Stack: $stack');
      throw AuthException('Unexpected error: $e');
    }
  }

  Map<String, String> _buildHeaders(GitServiceConfig config, String pat) {
    switch (config.type) {
      case GitServiceType.github:
        return {
          'Authorization': 'Bearer $pat',
          'Accept': 'application/vnd.github.v3+json',
        };
      case GitServiceType.gitlab:
        return {'PRIVATE-TOKEN': pat};
      case GitServiceType.gitea:
      case GitServiceType.custom:
        return {'Authorization': 'Bearer $pat'};
    }
  }
}
