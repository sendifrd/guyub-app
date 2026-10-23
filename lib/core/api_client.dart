import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_storage.dart';

/// Alamat API diatur saat menjalankan aplikasi. Bawaan: Laravel Herd di Mac yang sama.
///   flutter run -d chrome                                                   → http://guyub.test/api/v1
///   flutter run --dart-define=API_URL=http://192.168.1.10:8000/api/v1       → HP di Wi-Fi yang sama
const apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://guyub.test/api/v1');

final authStorageProvider = Provider<AuthStorage>((ref) => AuthStorage());
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(authStorageProvider)));

class ApiClient {
  ApiClient(this._storage)
      : dio = Dio(BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (e, handler) async {
        // Token kedaluwarsa, dicabut, atau akun dinonaktifkan admin → keluar otomatis
        if (e.response?.statusCode == 401 && !e.requestOptions.path.startsWith('/auth/')) {
          await _storage.clear();
          _tidakSah.add(null);
        }
        handler.next(e);
      },
    ));
  }

  final Dio dio;
  final AuthStorage _storage;
  final _tidakSah = StreamController<void>.broadcast();

  /// Berbunyi setiap kali server menjawab 401 (sesi login habis).
  Stream<void> get tidakSah => _tidakSah.stream;
}

/// Error dari API dalam bentuk yang mudah ditampilkan.
/// 422 dari Laravel: {"message": "...", "errors": {"email": ["..."]}}
class ApiException implements Exception {
  ApiException(this.message, {this.fieldErrors = const {}, this.status});

  final String message;
  final Map<String, String> fieldErrors;
  final int? status;

  String? field(String name) => fieldErrors[name];

  factory ApiException.from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final res = error.response;
      final data = res?.data;
      if (res == null) {
        return ApiException('Tidak bisa terhubung ke server Guyub. Pastikan Laravel Herd berjalan dan koneksi internet aktif.');
      }
      if (data is Map && data['errors'] is Map) {
        final errs = <String, String>{};
        (data['errors'] as Map).forEach((k, v) {
          if (v is List && v.isNotEmpty) errs['$k'] = '${v.first}';
        });
        return ApiException('${data['message'] ?? 'Periksa kembali isian.'}', fieldErrors: errs, status: res.statusCode);
      }
      if (res.statusCode == 429) return ApiException('Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.', status: 429);
      if ((res.statusCode ?? 0) >= 500) return ApiException('Server sedang bermasalah. Coba lagi beberapa saat lagi.', status: res.statusCode);
      final msg = data is Map && data['message'] != null ? '${data['message']}' : 'Terjadi kesalahan (${res.statusCode}).';
      return ApiException(msg, status: res.statusCode);
    }
    return ApiException('Terjadi kesalahan. Coba lagi.');
  }

  @override
  String toString() => message;
}
