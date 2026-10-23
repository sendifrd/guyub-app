import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

/// Ringkasan produk (ProdukResource di Laravel), dipakai Beranda dan nanti katalog Pasar.
class ProdukRingkas {
  ProdukRingkas({required this.slug, required this.nama, required this.harga, required this.tipe, required this.habis, required this.tokoNama, this.fotoUrl});

  final String slug;
  final String nama;
  final int harga;
  final String tipe; // fisik | digital | jasa
  final bool habis;
  final String tokoNama;
  final String? fotoUrl;

  factory ProdukRingkas.fromJson(Map<String, dynamic> j) {
    final foto = (j['foto'] as List?) ?? const [];
    return ProdukRingkas(
      slug: '${j['slug']}',
      nama: '${j['nama']}',
      harga: (j['harga'] as num).toInt(),
      tipe: '${j['tipe']}',
      habis: j['habis'] == true,
      tokoNama: '${(j['toko'] as Map?)?['nama'] ?? ''}',
      fotoUrl: foto.isNotEmpty ? '${foto.first}' : null,
    );
  }
}

class BookingRingkas {
  BookingRingkas({required this.id, required this.kode, required this.status, required this.ruang, required this.gedung, required this.mulai, required this.selesai});

  final int id;
  final String kode;
  final String status;
  final String ruang;
  final String gedung;
  final DateTime mulai;
  final DateTime selesai;
}

class SesiTerbuka {
  SesiTerbuka({required this.id, required this.judul, required this.mataKuliah, required this.batasJoin, required this.sudahBergabung});

  final int id;
  final String judul;
  final String mataKuliah;
  final DateTime batasJoin;
  final bool sudahBergabung;
}

class KelompokTerbaru {
  KelompokTerbaru({required this.sesiId, required this.judul, required this.mataKuliah, required this.kelompok, required this.jumlahAnggota});

  final int sesiId;
  final String judul;
  final String mataKuliah;
  final String kelompok;
  final int jumlahAnggota;
}

class TokoRingkas {
  TokoRingkas({required this.nama, required this.saldo, required this.perluDiproses});

  final String nama;
  final int saldo;
  final int perluDiproses;
}

/// Isi GET /beranda (BerandaController di Laravel).
class BerandaData {
  BerandaData({
    required this.sapaan,
    required this.belumDibaca,
    required this.booking,
    required this.sesiTerbuka,
    required this.kelompok,
    required this.pesananAktif,
    required this.toko,
    required this.produkBaru,
  });

  final String sapaan;
  final int belumDibaca;
  final BookingRingkas? booking;
  final List<SesiTerbuka> sesiTerbuka;
  final KelompokTerbaru? kelompok;
  final int pesananAktif;
  final TokoRingkas? toko;
  final List<ProdukRingkas> produkBaru;

  factory BerandaData.fromJson(Map<String, dynamic> j) {
    final b = j['booking_berikutnya'] as Map?;
    final tim = (j['tim'] as Map?) ?? const {};
    final k = tim['kelompok_terbaru'] as Map?;
    final pasar = (j['pasar'] as Map?) ?? const {};
    final t = pasar['toko'] as Map?;
    return BerandaData(
      sapaan: '${j['sapaan'] ?? 'Halo'}',
      belumDibaca: (j['notifikasi_belum_dibaca'] as num?)?.toInt() ?? 0,
      booking: b == null
          ? null
          : BookingRingkas(
              id: (b['id'] as num).toInt(),
              kode: '${b['kode']}',
              status: '${b['status']}',
              ruang: '${b['ruang']}',
              gedung: '${b['gedung']}',
              mulai: DateTime.parse('${b['mulai']}'),
              selesai: DateTime.parse('${b['selesai']}'),
            ),
      sesiTerbuka: [
        for (final s in (tim['sesi_terbuka'] as List? ?? const []))
          SesiTerbuka(
            id: (s['id'] as num).toInt(),
            judul: '${s['judul']}',
            mataKuliah: '${s['mata_kuliah']}',
            batasJoin: DateTime.parse('${s['batas_join']}'),
            sudahBergabung: s['sudah_bergabung'] == true,
          ),
      ],
      kelompok: k == null
          ? null
          : KelompokTerbaru(
              sesiId: (k['sesi_id'] as num).toInt(),
              judul: '${k['judul']}',
              mataKuliah: '${k['mata_kuliah']}',
              kelompok: '${k['kelompok']}',
              jumlahAnggota: (k['jumlah_anggota'] as num).toInt(),
            ),
      pesananAktif: (pasar['pesanan_aktif'] as num?)?.toInt() ?? 0,
      toko: t == null
          ? null
          : TokoRingkas(nama: '${t['nama']}', saldo: (t['saldo'] as num).toInt(), perluDiproses: (t['perlu_diproses'] as num).toInt()),
      produkBaru: [for (final p in (pasar['produk_baru'] as List? ?? const [])) ProdukRingkas.fromJson(Map<String, dynamic>.from(p as Map))],
    );
  }
}

final berandaProvider = FutureProvider.autoDispose<BerandaData>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/beranda');
    return BerandaData.fromJson(Map<String, dynamic>.from((res.data as Map)['data'] as Map));
  } catch (e) {
    throw ApiException.from(e);
  }
});
