import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/auth_storage.dart';
import '../../../core/sesi.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider), ref.watch(authStorageProvider)),
);

/// Endpoint akun di Laravel (routes/api.php → AuthController).
class AuthRepository {
  AuthRepository(this._api, this._storage);
  final ApiClient _api;
  final AuthStorage _storage;

  Future<bool> adaToken() async => (await _storage.readToken()) != null;

  /// POST /auth/login → {"token": "...", "user": {...}}
  Future<Pengguna> masuk({required String email, required String sandi}) async {
    try {
      final res = await _api.dio.post('/auth/login', data: {
        'email': email,
        'password': sandi,
        'device_name': 'guyub-app',
      });
      return _simpan(res.data);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// POST /auth/register → 201 {"token": "...", "user": {...}}; email verifikasi dikirim server.
  Future<Pengguna> daftar({required String nama, required String nim, required String email, required String sandi, required String ulangSandi}) async {
    try {
      final res = await _api.dio.post('/auth/register', data: {
        'name': nama,
        'nim': nim,
        'email': email,
        'password': sandi,
        'password_confirmation': ulangSandi,
      });
      return _simpan(res.data);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GET /me
  Future<Pengguna> saya() async {
    try {
      final res = await _api.dio.get('/me');
      return Pengguna.fromJson(Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// POST /auth/email/resend → {"message": "..."}
  Future<String> kirimUlangVerifikasi() async {
    try {
      final res = await _api.dio.post('/auth/email/resend');
      return '${(res.data as Map)['message']}';
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// POST /auth/lupa-sandi → {"message": "..."} (jawaban sama walau email tidak terdaftar)
  Future<String> lupaSandi(String email) async {
    try {
      final res = await _api.dio.post('/auth/lupa-sandi', data: {'email': email});
      return '${(res.data as Map)['message']}';
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// POST /auth/logout mencabut token di server, lalu token lokal dihapus.
  Future<void> keluar() async {
    try {
      await _api.dio.post('/auth/logout');
    } catch (_) {
      // tetap hapus token lokal walau server tidak terjangkau
    }
    await _storage.clear();
  }

  Future<Pengguna> _simpan(Object? data) async {
    final map = Map<String, dynamic>.from(data as Map);
    await _storage.saveToken(map['token'] as String);
    return Pengguna.fromJson(Map<String, dynamic>.from(map['user'] as Map));
  }
}
