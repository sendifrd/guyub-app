import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Menyimpan token login Sanctum di penyimpanan aman HP.
class AuthStorage {
  AuthStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;
  static const _key = 'guyub_token';

  Future<String?> readToken() => _s.read(key: _key);
  Future<void> saveToken(String token) => _s.write(key: _key, value: token);
  Future<void> clear() => _s.delete(key: _key);
}
