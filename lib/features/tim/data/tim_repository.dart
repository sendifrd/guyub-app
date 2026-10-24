import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// Mata kuliah ringkas: {kode, nama, kelas}.
class MatkulRingkas {
  MatkulRingkas({required this.kode, required this.nama, required this.kelas});
  final String kode;
  final String nama;
  final String kelas;

  factory MatkulRingkas.fromJson(Map j) => MatkulRingkas(kode: '${j['kode']}', nama: '${j['nama']}', kelas: '${j['kelas']}');

  /// "IF2103 Basis Data · Kelas B"
  String get label => '$kode $nama · Kelas $kelas';
}

String? _str(Object? v) => v == null ? null : '$v';

/// Satu baris di daftar "Sesi saya" (GET /tim/sesi).
class SesiSaya {
  SesiSaya({required this.id, required this.judul, required this.matkul, required this.status, required this.batasJoin, this.statusSaya, this.kelompokNomor, this.kelompokNama});

  final int id;
  final String judul;
  final MatkulRingkas matkul;
  final String status; // terbuka | dikunci
  final DateTime batasJoin;
  final String? statusSaya; // tepat_waktu | terlambat_menunggu | terlambat_disetujui | terlambat_ditolak
  final int? kelompokNomor;
  final String? kelompokNama;

  bool get dikunci => status == 'dikunci';

  factory SesiSaya.fromJson(Map<String, dynamic> j) {
    final k = j['kelompok_saya'] as Map?;
    return SesiSaya(
      id: (j['id'] as num).toInt(),
      judul: '${j['judul']}',
      matkul: MatkulRingkas.fromJson(j['mata_kuliah'] as Map),
      status: '${j['status']}',
      batasJoin: DateTime.parse('${j['batas_join']}'),
      statusSaya: _str(j['status_saya']),
      kelompokNomor: (k?['nomor'] as num?)?.toInt(),
      kelompokNama: _str(k?['nama']),
    );
  }
}

/// Pratinjau sebelum bergabung (GET /tim/kode/{kode}).
class PratinjauKode {
  PratinjauKode({required this.id, required this.kode, required this.judul, required this.matkul, required this.batasJoin, required this.jumlahPeserta, required this.akanTerlambat, this.statusSaya});

  final int id;
  final String kode;
  final String judul;
  final MatkulRingkas matkul;
  final DateTime batasJoin;
  final int jumlahPeserta;
  final bool akanTerlambat;
  final String? statusSaya;

  bool get sudahGabung => statusSaya != null;

  factory PratinjauKode.fromJson(String kode, Map<String, dynamic> j) => PratinjauKode(
        id: (j['id'] as num).toInt(),
        kode: kode,
        judul: '${j['judul']}',
        matkul: MatkulRingkas.fromJson(j['mata_kuliah'] as Map),
        batasJoin: DateTime.parse('${j['batas_join']}'),
        jumlahPeserta: (j['jumlah_peserta'] as num).toInt(),
        akanTerlambat: j['akan_terlambat'] == true,
        statusSaya: _str(j['status_saya']),
      );
}

class Anggota {
  Anggota({required this.nama, this.nim, this.prodi, this.noWhatsapp});
  final String nama;
  final String? nim;
  final String? prodi;
  final String? noWhatsapp;

  factory Anggota.fromJson(Map j) =>
      Anggota(nama: '${j['nama']}', nim: _str(j['nim']), prodi: _str(j['prodi']), noWhatsapp: _str(j['no_whatsapp']));
}

class Kelompok {
  Kelompok({required this.id, required this.nomor, required this.nama, required this.anggota});
  final int id;
  final int nomor;
  final String nama;
  final List<Anggota> anggota;

  factory Kelompok.fromJson(Map j) => Kelompok(
        id: (j['id'] as num).toInt(),
        nomor: (j['nomor'] as num).toInt(),
        nama: '${j['nama']}',
        anggota: [for (final a in (j['anggota'] as List? ?? const [])) Anggota.fromJson(a as Map)],
      );
}

class RiwayatAcak {
  RiwayatAcak({required this.putaran, required this.jenis, required this.seed, this.alasan, required this.jumlahPeserta, required this.waktu});
  final int putaran;
  final String jenis;
  final String seed;
  final String? alasan;
  final int jumlahPeserta;
  final DateTime waktu;

  factory RiwayatAcak.fromJson(Map j) => RiwayatAcak(
        putaran: (j['putaran'] as num).toInt(),
        jenis: '${j['jenis']}',
        seed: '${j['seed']}',
        alasan: _str(j['alasan']),
        jumlahPeserta: (j['jumlah_peserta'] as num).toInt(),
        waktu: DateTime.parse('${j['waktu']}'),
      );
}

/// Bukti commit–reveal: seed baru dibuka setelah kelompok dikunci.
class BuktiAcak {
  BuktiAcak({this.seed, required this.kode, required this.sidikJari, required this.cocok, required this.rumus, required this.algoritma, required this.riwayat});
  final String? seed;
  final String kode;
  final String sidikJari;
  final bool cocok;
  final String rumus;
  final String algoritma;
  final List<RiwayatAcak> riwayat;

  factory BuktiAcak.fromJson(Map j) => BuktiAcak(
        seed: _str(j['seed']),
        kode: '${j['kode']}',
        sidikJari: '${j['sidik_jari']}',
        cocok: j['cocok'] == true,
        rumus: '${j['rumus']}',
        algoritma: '${j['algoritma']}',
        riwayat: [for (final r in (j['riwayat'] as List? ?? const [])) RiwayatAcak.fromJson(r as Map)],
      );
}

/// Detail sesi (GET /tim/sesi/{id}): T3 saat terbuka, T4 saat dikunci.
class DetailSesi {
  DetailSesi({
    required this.id,
    required this.judul,
    required this.matkul,
    required this.status,
    required this.mode,
    required this.nilai,
    required this.batasJoin,
    required this.sidikJari,
    required this.jumlahPeserta,
    this.statusSaya,
    this.dikunciPada,
    this.kelompokSayaId,
    this.kelompok = const [],
    this.bukti,
  });

  final int id;
  final String judul;
  final MatkulRingkas matkul;
  final String status;
  final String mode; // ukuran | jumlah
  final int nilai;
  final DateTime batasJoin;
  final String sidikJari;
  final int jumlahPeserta;
  final String? statusSaya;
  final DateTime? dikunciPada;
  final int? kelompokSayaId;
  final List<Kelompok> kelompok;
  final BuktiAcak? bukti;

  bool get dikunci => status == 'dikunci';
  Kelompok? get kelompokSaya => kelompok.where((k) => k.id == kelompokSayaId).firstOrNull;

  /// "Kelompok 5 orang" atau "6 kelompok"
  String get aturan => mode == 'jumlah' ? '$nilai kelompok' : 'Kelompok $nilai orang';

  factory DetailSesi.fromJson(Map<String, dynamic> j) => DetailSesi(
        id: (j['id'] as num).toInt(),
        judul: '${j['judul']}',
        matkul: MatkulRingkas.fromJson(j['mata_kuliah'] as Map),
        status: '${j['status']}',
        mode: '${j['mode']}',
        nilai: (j['nilai'] as num?)?.toInt() ?? 0,
        batasJoin: DateTime.parse('${j['batas_join']}'),
        sidikJari: '${j['sidik_jari']}',
        jumlahPeserta: (j['jumlah_peserta'] as num?)?.toInt() ?? 0,
        statusSaya: _str(j['status_saya']),
        dikunciPada: j['dikunci_pada'] == null ? null : DateTime.parse('${j['dikunci_pada']}'),
        kelompokSayaId: (j['kelompok_saya_id'] as num?)?.toInt(),
        kelompok: [for (final k in (j['kelompok'] as List? ?? const [])) Kelompok.fromJson(k as Map)],
        bukti: j['bukti'] == null ? null : BuktiAcak.fromJson(j['bukti'] as Map),
      );
}

/// Endpoint Cari Tim sisi mahasiswa (GabungSesiController di Laravel).
class TimRepository {
  TimRepository(this._api);
  final ApiClient _api;

  Future<T> _jalan<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<SesiSaya>> sesiSaya() => _jalan(() async {
        final res = await _api.dio.get('/tim/sesi');
        return [for (final s in ((res.data as Map)['data'] as List)) SesiSaya.fromJson(Map<String, dynamic>.from(s as Map))];
      });

  Future<PratinjauKode> cariKode(String kode) => _jalan(() async {
        final k = kode.trim().toUpperCase();
        final res = await _api.dio.get('/tim/kode/$k');
        return PratinjauKode.fromJson(k, Map<String, dynamic>.from((res.data as Map)['data'] as Map));
      });

  /// Mengembalikan (sesiId, status, pesan).
  Future<({int sesiId, String status, String pesan})> gabung(String kode) => _jalan(() async {
        final res = await _api.dio.post('/tim/gabung', data: {'kode': kode.trim().toUpperCase()});
        final m = res.data as Map;
        final d = m['data'] as Map;
        return (sesiId: (d['sesi_id'] as num).toInt(), status: '${d['status']}', pesan: '${m['message']}');
      });

  Future<DetailSesi> detail(int id) => _jalan(() async {
        final res = await _api.dio.get('/tim/sesi/$id');
        return DetailSesi.fromJson(Map<String, dynamic>.from((res.data as Map)['data'] as Map));
      });

  Future<void> ubahNama(int groupId, String nama) => _jalan(() async {
        await _api.dio.patch('/tim/kelompok/$groupId', data: {'nama': nama.trim()});
      });
}

final timRepositoryProvider = Provider<TimRepository>((ref) => TimRepository(ref.watch(apiClientProvider)));

final sesiSayaProvider = FutureProvider.autoDispose<List<SesiSaya>>((ref) => ref.watch(timRepositoryProvider).sesiSaya());

final detailSesiProvider = FutureProvider.autoDispose.family<DetailSesi, int>((ref, id) => ref.watch(timRepositoryProvider).detail(id));
