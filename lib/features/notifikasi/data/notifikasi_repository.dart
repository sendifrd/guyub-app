import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

class Notifikasi {
  Notifikasi({required this.id, required this.tipe, required this.kategori, required this.judul, required this.isi, required this.dibaca, required this.waktu, this.link});

  final int id;
  final String tipe;
  final String kategori; // kelompok | pesanan | booking
  final String judul;
  final String isi;
  final String? link;
  final bool dibaca;
  final DateTime waktu;

  factory Notifikasi.fromJson(Map<String, dynamic> j) => Notifikasi(
        id: (j['id'] as num).toInt(),
        tipe: '${j['tipe']}',
        kategori: '${j['kategori']}',
        judul: '${j['judul']}',
        isi: '${j['isi']}',
        link: j['link'] as String?,
        dibaca: j['dibaca'] == true,
        waktu: DateTime.parse('${j['waktu']}'),
      );
}

final notifikasiRepositoryProvider = Provider<NotifikasiRepository>((ref) => NotifikasiRepository(ref.watch(apiClientProvider)));

final notifikasiProvider = FutureProvider.autoDispose<List<Notifikasi>>((ref) => ref.watch(notifikasiRepositoryProvider).daftar());

/// Endpoint notifikasi (NotifikasiController di Laravel).
class NotifikasiRepository {
  NotifikasiRepository(this._api);
  final ApiClient _api;

  /// GET /notifikasi → 30 terbaru
  Future<List<Notifikasi>> daftar() async {
    try {
      final res = await _api.dio.get('/notifikasi');
      return [for (final n in ((res.data as Map)['data'] as List)) Notifikasi.fromJson(Map<String, dynamic>.from(n as Map))];
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> baca(int id) async {
    try {
      await _api.dio.post('/notifikasi/$id/baca');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<String> bacaSemua() async {
    try {
      final res = await _api.dio.post('/notifikasi/baca-semua');
      return '${(res.data as Map)['message']}';
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
