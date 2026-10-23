import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/akun/data/auth_repository.dart';
import 'api_client.dart';

/// Data akun dari GET /me (AuthController::dataUser di Laravel).
class Pengguna {
  Pengguna({
    required this.id,
    required this.nama,
    required this.email,
    this.nim,
    this.prodi,
    this.angkatan,
    this.noWhatsapp,
    this.fotoUrl,
    required this.terverifikasi,
    required this.peran,
    required this.punyaToko,
    required this.mengelolaKelas,
  });

  final int id;
  final String nama;
  final String email;
  final String? nim;
  final String? prodi;
  final int? angkatan;
  final String? noWhatsapp;
  final String? fotoUrl;
  final bool terverifikasi;
  final List<String> peran;
  final bool punyaToko;
  final bool mengelolaKelas;

  String get namaDepan => nama.split(' ').first;
  bool get mahasiswa => peran.contains('mahasiswa');
  bool get dosen => peran.contains('dosen');

  factory Pengguna.fromJson(Map<String, dynamic> j) => Pengguna(
        id: (j['id'] as num).toInt(),
        nama: '${j['name'] ?? ''}',
        email: '${j['email'] ?? ''}',
        nim: j['nim'] as String?,
        prodi: j['prodi'] as String?,
        angkatan: j['angkatan'] == null ? null : int.tryParse('${j['angkatan']}'),
        noWhatsapp: j['no_whatsapp'] as String?,
        fotoUrl: j['foto_url'] as String?,
        terverifikasi: j['email_verified_at'] != null,
        peran: [for (final p in (j['peran'] as List? ?? const [])) '$p'],
        punyaToko: j['punya_toko'] == true,
        mengelolaKelas: j['mengelola_kelas'] == true,
      );
}

final sesiProvider = ChangeNotifierProvider<Sesi>((ref) {
  final sesi = Sesi(ref.watch(authRepositoryProvider), ref.watch(apiClientProvider));
  sesi.muat();
  return sesi;
});

/// Status login seluruh aplikasi. Router mendengarkan objek ini untuk mengarahkan layar.
class Sesi extends ChangeNotifier {
  Sesi(this._repo, ApiClient api) {
    _langganan = api.tidakSah.listen((_) => _keluarLokal());
  }

  final AuthRepository _repo;
  late final StreamSubscription<void> _langganan;

  bool siap = false;
  Pengguna? pengguna;

  /// Dipanggil sekali saat aplikasi dibuka: ada token tersimpan → ambil profil.
  Future<void> muat() async {
    try {
      if (await _repo.adaToken()) pengguna = await _repo.saya();
    } catch (_) {
      pengguna = null; // server mati atau token tidak berlaku: mulai dari halaman awal
    }
    siap = true;
    notifyListeners();
  }

  Future<void> masuk(String email, String sandi) async {
    pengguna = await _repo.masuk(email: email, sandi: sandi);
    notifyListeners();
  }

  Future<void> daftar({required String nama, required String nim, required String email, required String sandi, required String ulangSandi}) async {
    pengguna = await _repo.daftar(nama: nama, nim: nim, email: email, sandi: sandi, ulangSandi: ulangSandi);
    notifyListeners();
  }

  /// Ambil ulang profil (misalnya setelah email diverifikasi di browser).
  Future<void> segarkan() async {
    pengguna = await _repo.saya();
    notifyListeners();
  }

  Future<void> keluar() async {
    await _repo.keluar();
    _keluarLokal();
  }

  void _keluarLokal() {
    if (pengguna == null) return;
    pengguna = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _langganan.cancel();
    super.dispose();
  }
}
