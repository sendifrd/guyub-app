import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import 'tim_repository.dart';

String? _str(Object? v) => v == null ? null : '$v';

/// Kelas yang boleh dibuatkan sesi (GET /kelola/kelas).
class KelasKelola {
  KelasKelola({required this.id, required this.matkul, required this.semester, required this.jumlahMahasiswa, required this.peranSaya});
  final int id;
  final MatkulRingkas matkul;
  final String semester;
  final int jumlahMahasiswa;
  final String peranSaya; // dosen | ketua_kelas

  bool get dosen => peranSaya == 'dosen';

  factory KelasKelola.fromJson(Map j) => KelasKelola(
        id: (j['id'] as num).toInt(),
        matkul: MatkulRingkas.fromJson(j),
        semester: '${j['semester']}',
        jumlahMahasiswa: (j['jumlah_mahasiswa'] as num?)?.toInt() ?? 0,
        peranSaya: '${j['peran_saya']}',
      );
}

/// Baris daftar sesi yang dikelola (GET /kelola/sesi).
class SesiKelola {
  SesiKelola({required this.id, required this.judul, required this.status, required this.kode, required this.matkul, required this.batasJoin, required this.jumlahBergabung, required this.jumlahMahasiswa});
  final int id;
  final String judul;
  final String status;
  final String kode;
  final MatkulRingkas matkul;
  final DateTime batasJoin;
  final int jumlahBergabung;
  final int jumlahMahasiswa;

  bool get dikunci => status == 'dikunci';

  factory SesiKelola.fromJson(Map j) => SesiKelola(
        id: (j['id'] as num).toInt(),
        judul: '${j['judul']}',
        status: '${j['status']}',
        kode: '${j['kode']}',
        matkul: MatkulRingkas.fromJson(j['mata_kuliah'] as Map),
        batasJoin: DateTime.parse('${j['batas_join']}'),
        jumlahBergabung: (j['jumlah_bergabung'] as num?)?.toInt() ?? 0,
        jumlahMahasiswa: (j['jumlah_mahasiswa'] as num?)?.toInt() ?? 0,
      );
}

class Mahasiswa {
  Mahasiswa({required this.id, required this.nama, this.nim, this.cara});
  final int id;
  final String nama;
  final String? nim;
  final String? cara; // acak | terlambat | pindah

  factory Mahasiswa.fromJson(Map j) => Mahasiswa(id: (j['id'] as num).toInt(), nama: '${j['nama']}', nim: _str(j['nim']), cara: _str(j['cara']));
}

class KelompokKelola {
  KelompokKelola({required this.id, required this.nomor, required this.nama, required this.anggota});
  final int id;
  final int nomor;
  final String nama;
  final List<Mahasiswa> anggota;

  factory KelompokKelola.fromJson(Map j) => KelompokKelola(
        id: (j['id'] as num).toInt(),
        nomor: (j['nomor'] as num).toInt(),
        nama: '${j['nama']}',
        anggota: [for (final a in (j['anggota'] as List? ?? const [])) Mahasiswa.fromJson(a as Map)],
      );
}

/// Detail sesi untuk pengelola (K3–K6).
class DetailKelola {
  DetailKelola({
    required this.id,
    required this.judul,
    required this.status,
    required this.courseId,
    required this.matkul,
    required this.mode,
    required this.nilai,
    required this.kode,
    required this.tautan,
    required this.batasJoin,
    required this.sidikJari,
    required this.bergabung,
    required this.total,
    required this.pratinjau,
    required this.terlambatMenunggu,
    this.pengingatTerakhir,
    required this.bisaAcakUlang,
    this.dikunciPada,
    this.seed,
    this.acakUlangKe = 0,
    this.kelompok = const [],
    this.belumBergabung = const [],
  });

  final int id;
  final String judul;
  final String status;
  final int courseId;
  final MatkulRingkas matkul;
  final String mode;
  final int nilai;
  final String kode;
  final String tautan;
  final DateTime batasJoin;
  final String sidikJari;
  final int bergabung;
  final int total;
  final List<int> pratinjau;
  final int terlambatMenunggu;
  final DateTime? pengingatTerakhir;
  final bool bisaAcakUlang;
  final DateTime? dikunciPada;
  final String? seed;
  final int acakUlangKe;
  final List<KelompokKelola> kelompok;
  final List<Mahasiswa> belumBergabung;

  bool get dikunci => status == 'dikunci';
  String get aturan => mode == 'jumlah' ? '$nilai kelompok' : '$nilai orang per kelompok';
  int get jumlahAnggota => kelompok.fold(0, (n, k) => n + k.anggota.length);

  factory DetailKelola.fromJson(Map<String, dynamic> j) {
    final mk = j['mata_kuliah'] as Map;
    final p = (j['progres'] as Map?) ?? const {};
    return DetailKelola(
      id: (j['id'] as num).toInt(),
      judul: '${j['judul']}',
      status: '${j['status']}',
      courseId: (mk['id'] as num).toInt(),
      matkul: MatkulRingkas.fromJson(mk),
      mode: '${j['mode']}',
      nilai: (j['nilai'] as num?)?.toInt() ?? 0,
      kode: '${j['kode']}',
      tautan: '${j['tautan']}',
      batasJoin: DateTime.parse('${j['batas_join']}'),
      sidikJari: '${j['sidik_jari']}',
      bergabung: (p['bergabung'] as num?)?.toInt() ?? 0,
      total: (p['total'] as num?)?.toInt() ?? 0,
      pratinjau: [for (final x in (j['pratinjau'] as List? ?? const [])) (x as num).toInt()],
      terlambatMenunggu: (j['terlambat_menunggu'] as num?)?.toInt() ?? 0,
      pengingatTerakhir: j['pengingat_terakhir'] == null ? null : DateTime.parse('${j['pengingat_terakhir']}'),
      bisaAcakUlang: j['bisa_acak_ulang'] == true,
      dikunciPada: j['dikunci_pada'] == null ? null : DateTime.parse('${j['dikunci_pada']}'),
      seed: _str(j['seed']),
      acakUlangKe: (j['reshuffle_count'] as num?)?.toInt() ?? 0,
      kelompok: [for (final k in (j['kelompok'] as List? ?? const [])) KelompokKelola.fromJson(k as Map)],
      belumBergabung: [for (final m in (j['belum_bergabung'] as List? ?? const [])) Mahasiswa.fromJson(m as Map)],
    );
  }
}

/// Permintaan gabung terlambat (GET /kelola/sesi/{id}/terlambat).
class PermintaanTerlambat {
  PermintaanTerlambat({required this.id, required this.status, this.catatan, required this.mahasiswa, required this.diajukanPada});
  final int id;
  final String status; // terlambat_menunggu | terlambat_disetujui | terlambat_ditolak
  final String? catatan;
  final Mahasiswa mahasiswa;
  final DateTime diajukanPada;

  bool get menunggu => status == 'terlambat_menunggu';

  factory PermintaanTerlambat.fromJson(Map j) => PermintaanTerlambat(
        id: (j['id'] as num).toInt(),
        status: '${j['status']}',
        catatan: _str(j['catatan']),
        mahasiswa: Mahasiswa.fromJson(j['mahasiswa'] as Map),
        diajukanPada: DateTime.parse('${j['diajukan_pada']}'),
      );
}

/// Endpoint kelola sesi untuk dosen pengampu dan ketua kelas (KelolaSesiController).
class KelolaRepository {
  KelolaRepository(this._api);
  final ApiClient _api;

  Future<T> _jalan<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Map<String, dynamic> _data(Object? body) => Map<String, dynamic>.from((body as Map)['data'] as Map);
  String _pesan(Object? body) => '${(body as Map)['message'] ?? 'Berhasil.'}';

  Future<List<KelasKelola>> kelas() => _jalan(() async {
        final res = await _api.dio.get('/kelola/kelas');
        return [for (final k in ((res.data as Map)['data'] as List)) KelasKelola.fromJson(k as Map)];
      });

  Future<List<SesiKelola>> daftar() => _jalan(() async {
        final res = await _api.dio.get('/kelola/sesi');
        return [for (final s in ((res.data as Map)['data'] as List)) SesiKelola.fromJson(s as Map)];
      });

  Future<String> pratinjau({required int courseId, required String mode, required int nilai}) => _jalan(() async {
        final res = await _api.dio.post('/kelola/pratinjau', data: {'course_id': courseId, 'mode': mode, 'nilai': nilai});
        return '${_data(res.data)['teks']}';
      });

  /// [batasJoin] dikirim sebagai "TTTT-BB-HH JJ:MM" waktu kampus (WIB).
  Future<DetailKelola> buat({required int courseId, required String judul, required String mode, required int nilai, required String batasJoin}) =>
      _jalan(() async {
        final res = await _api.dio.post('/kelola/sesi', data: {
          'course_id': courseId,
          'judul': judul.trim(),
          'mode': mode,
          'nilai': nilai,
          'batas_join': batasJoin,
        });
        return DetailKelola.fromJson(_data(res.data));
      });

  Future<DetailKelola> detail(int id) => _jalan(() async => DetailKelola.fromJson(_data((await _api.dio.get('/kelola/sesi/$id')).data)));

  Future<String> kodeBaru(int id) => _jalan(() async => _pesan((await _api.dio.post('/kelola/sesi/$id/kode-baru')).data));

  Future<String> pengingat(int id) => _jalan(() async => _pesan((await _api.dio.post('/kelola/sesi/$id/pengingat')).data));

  Future<String> acakUlang(int id, String alasan) =>
      _jalan(() async => _pesan((await _api.dio.post('/kelola/sesi/$id/acak-ulang', data: {'alasan': alasan.trim()})).data));

  Future<String> keluarkan(int sesiId, int userId) => _jalan(() async => _pesan((await _api.dio.delete('/kelola/sesi/$sesiId/anggota/$userId')).data));

  Future<String> pindah(int sesiId, int userId, int nomorKelompok, String alasan) => _jalan(() async => _pesan((await _api.dio.post(
        '/kelola/sesi/$sesiId/anggota/$userId/pindah',
        data: {'nomor_kelompok': nomorKelompok, 'alasan': alasan.trim()},
      ))
          .data));

  Future<List<PermintaanTerlambat>> terlambat(int sesiId) => _jalan(() async {
        final res = await _api.dio.get('/kelola/sesi/$sesiId/terlambat');
        return [for (final p in ((res.data as Map)['data'] as List)) PermintaanTerlambat.fromJson(p as Map)];
      });

  Future<String> setujui(int pesertaId) => _jalan(() async => _pesan((await _api.dio.post('/kelola/terlambat/$pesertaId/setujui')).data));

  Future<String> tolak(int pesertaId, {String? catatan}) => _jalan(() async =>
      _pesan((await _api.dio.post('/kelola/terlambat/$pesertaId/tolak', data: {if (catatan != null && catatan.trim().isNotEmpty) 'catatan': catatan.trim()})).data));
}

final kelolaRepositoryProvider = Provider<KelolaRepository>((ref) => KelolaRepository(ref.watch(apiClientProvider)));

final kelasKelolaProvider = FutureProvider.autoDispose<List<KelasKelola>>((ref) => ref.watch(kelolaRepositoryProvider).kelas());

final daftarKelolaProvider = FutureProvider.autoDispose<List<SesiKelola>>((ref) => ref.watch(kelolaRepositoryProvider).daftar());

final detailKelolaProvider = FutureProvider.autoDispose.family<DetailKelola, int>((ref, id) => ref.watch(kelolaRepositoryProvider).detail(id));

final terlambatProvider = FutureProvider.autoDispose.family<List<PermintaanTerlambat>, int>((ref, id) => ref.watch(kelolaRepositoryProvider).terlambat(id));
