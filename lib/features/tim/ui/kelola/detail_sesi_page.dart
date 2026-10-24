// Layar K3 (bagikan kode, status terbuka), K4/K6 (hasil acak + kelola kelompok, status dikunci), K5 (acak ulang).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../core/api_client.dart';
import '../../../../core/format.dart';
import '../../../../widgets/alert_box.dart';
import '../../../../widgets/guyub_button.dart';
import '../../../../widgets/guyub_card.dart';
import '../../../../widgets/keadaan.dart';
import '../../../../widgets/status_badge.dart';
import '../../data/kelola_repository.dart';

class DetailSesiKelolaPage extends ConsumerWidget {
  const DetailSesiKelolaPage({super.key, required this.sesiId});
  final int sesiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(detailKelolaProvider(sesiId));
    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(title: Text(detail.valueOrNull?.judul ?? 'Kelola sesi')),
      body: RefreshIndicator(
        color: GuyubColors.primary,
        onRefresh: () => ref.refresh(detailKelolaProvider(sesiId).future),
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            KeadaanGalat(pesan: e is ApiException ? e.message : 'Sesi gagal dimuat.', onCobaLagi: () => ref.invalidate(detailKelolaProvider(sesiId))),
          ]),
          data: (d) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(children: [
                Expanded(child: Text(d.matkul.label, style: GuyubText.secondary)),
                StatusBadge(d.dikunci ? 'Dikunci' : 'Terbuka'),
              ]),
              const SizedBox(height: 12),
              if (d.terlambatMenunggu > 0) ...[
                _TautanTerlambat(sesiId: d.id, jumlah: d.terlambatMenunggu),
                const SizedBox(height: 12),
              ],
              ...(d.dikunci ? _dikunci(context, ref, d) : _terbuka(context, ref, d)),
            ],
          ),
        ),
      ),
    );
  }

  /// Menjalankan aksi, menampilkan pesan server, lalu memuat ulang detail.
  static Future<void> _aksi(BuildContext context, WidgetRef ref, int sesiId, Future<String> Function() f) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final pesan = await f();
      messenger.showSnackBar(SnackBar(content: Text(pesan)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.fieldErrors.values.firstOrNull ?? e.message)));
    }
    if (context.mounted) {
      ref.invalidate(detailKelolaProvider(sesiId));
      ref.invalidate(daftarKelolaProvider);
    }
  }

  static Future<bool> _yakin(BuildContext context, String judul, String isi, String aksi, {bool bahaya = false}) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(judul),
          content: Text(isi),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(aksi, style: TextStyle(color: bahaya ? GuyubColors.danger : GuyubColors.primary, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ) ??
      false;

  // ---- K3 · status terbuka ----
  List<Widget> _terbuka(BuildContext context, WidgetRef ref, DetailKelola d) {
    final persen = d.total == 0 ? 0.0 : d.bergabung / d.total;
    void salin(String teks, String label) {
      Clipboard.setData(ClipboardData(text: teks));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label disalin.')));
    }

    return [
      GuyubCard(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          Text('Bagikan kode ini ke kelas', style: GuyubText.secondary),
          const SizedBox(height: 8),
          SelectableText(d.kode, style: GuyubText.mono(size: 38, weight: FontWeight.w600, color: GuyubColors.primary).copyWith(letterSpacing: 8)),
          const SizedBox(height: 4),
          Text(d.tautan, style: GuyubText.mono(size: 12.5, color: GuyubColors.inkMuted), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: GuyubButton(label: 'Salin kode', icon: Icons.copy_rounded, size: GuyubButtonSize.sm, variant: GuyubButtonVariant.secondary, onPressed: () => salin(d.kode, 'Kode')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GuyubButton(
                label: 'Salin pesan',
                icon: Icons.share_outlined,
                size: GuyubButtonSize.sm,
                variant: GuyubButtonVariant.secondary,
                onPressed: () => salin(
                  'Gabung sesi kelompok "${d.judul}" (${d.matkul.label}) di Guyub.\n'
                  'Kode: ${d.kode}\nTautan: ${d.tautan}\n'
                  'Batas gabung: ${tanggalPendek(d.batasJoin)}, ${jam(d.batasJoin)} WIB',
                  'Pesan untuk grup kelas',
                ),
              ),
            ),
          ]),
          TextButton(
            onPressed: () async {
              if (await _yakin(context, 'Buat kode baru?', 'Kode ${d.kode} tidak berlaku lagi dan sidik jari pengacakan ikut berganti. Mahasiswa yang sudah gabung tetap di sesi.', 'Buat kode baru') &&
                  context.mounted) {
                await _aksi(context, ref, d.id, () => ref.read(kelolaRepositoryProvider).kodeBaru(d.id));
              }
            },
            child: Text('Kode bocor? Buat kode baru', style: GuyubText.secondary.copyWith(color: GuyubColors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      GuyubCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Peserta tergabung', style: GuyubText.fieldLabel),
            const Spacer(),
            Text('${d.bergabung}', style: GuyubText.cardTitle.copyWith(fontSize: 20)),
            Text(' / ${d.total}', style: GuyubText.secondary),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: persen, minHeight: 8, color: GuyubColors.primary, backgroundColor: GuyubColors.primaryTint),
          ),
          const SizedBox(height: 8),
          Text('Aturan: ${d.aturan}.', style: GuyubText.secondary),
          if (d.pratinjau.isNotEmpty)
            Text('Jika diacak sekarang: ${d.pratinjau.length} kelompok (${d.pratinjau.join(', ')}).', style: GuyubText.secondary),
          Text('Ditutup otomatis ${tanggalPendek(d.batasJoin)}, ${jam(d.batasJoin)} WIB.', style: GuyubText.secondary),
          if (d.belumBergabung.isNotEmpty) ...[
            const Divider(height: 24, color: GuyubColors.line),
            Text('Belum gabung (${d.belumBergabung.length})', style: GuyubText.fieldLabel),
            const SizedBox(height: 6),
            Text(d.belumBergabung.map((m) => m.nama).join(', '), style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody)),
            const SizedBox(height: 10),
            GuyubButton(
              label: 'Kirim pengingat',
              icon: Icons.notifications_active_outlined,
              size: GuyubButtonSize.sm,
              variant: GuyubButtonVariant.secondary,
              onPressed: () => _aksi(context, ref, d.id, () => ref.read(kelolaRepositoryProvider).pengingat(d.id)),
            ),
            if (d.pengingatTerakhir != null) ...[
              const SizedBox(height: 4),
              Text('Pengingat terakhir ${waktuRelatif(d.pengingatTerakhir!)}.', style: GuyubText.secondary, textAlign: TextAlign.center),
            ],
          ],
        ]),
      ),
      const SizedBox(height: 12),
      GuyubCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.fingerprint_rounded, color: GuyubColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Sidik jari pengacakan', style: GuyubText.cardTitle.copyWith(fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          SelectableText(d.sidikJari, style: GuyubText.mono(size: 12, color: GuyubColors.inkBody)),
          const SizedBox(height: 6),
          Text('Kunci acak sudah ditetapkan sekarang dan dibuka setelah diacak, jadi hasilnya tidak bisa diatur.', style: GuyubText.secondary),
        ]),
      ),
      const SizedBox(height: 12),
      const AlertBox('Diacak dan dikunci otomatis saat batas gabung. Yang belum gabung nanti bisa mengirim permintaan gabung terlambat.'),
    ];
  }

  // ---- K4/K6 · status dikunci ----
  List<Widget> _dikunci(BuildContext context, WidgetRef ref, DetailKelola d) {
    final kelas = ref.watch(kelasKelolaProvider).valueOrNull;
    final dosen = kelas?.where((k) => k.id == d.courseId).firstOrNull?.dosen ?? false;
    final waktu = d.dikunciPada;
    final terlambat = d.kelompok.expand((k) => k.anggota).where((a) => a.cara == 'terlambat').length;

    return [
      Text(
        'Diacak dan dikunci otomatis oleh sistem${waktu != null ? ' ${tanggalPendek(waktu)}, ${jam(waktu)} WIB' : ''}.'
        '${d.acakUlangKe > 0 ? ' Sudah diacak ulang ${d.acakUlangKe} kali.' : ''}',
        style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _Stat('Kelompok', '${d.kelompok.length}')),
        const SizedBox(width: 10),
        Expanded(child: _Stat('Anggota', '${d.jumlahAnggota}')),
        const SizedBox(width: 10),
        Expanded(child: _Stat('Terlambat', '$terlambat')),
      ]),
      const SizedBox(height: 16),
      for (final k in d.kelompok)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GuyubCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              shape: const Border(),
              title: Text(k.nama, style: GuyubText.cardTitle),
              subtitle: Text(
                '${k.nama == 'Kelompok ${k.nomor}' ? '' : 'Kelompok ${k.nomor} · '}${k.anggota.length} anggota',
                style: GuyubText.secondary,
              ),
              children: [
                for (final a in k.anggota)
                  ListTile(
                    dense: true,
                    title: Text.rich(TextSpan(style: GuyubText.body.copyWith(fontSize: 13.5), children: [
                      TextSpan(text: a.nama),
                      if (a.cara == 'terlambat') TextSpan(text: '  terlambat', style: GuyubText.caption.copyWith(color: GuyubColors.pasarText)),
                      if (a.cara == 'pindah') TextSpan(text: '  dipindah', style: GuyubText.caption.copyWith(color: GuyubColors.ruang)),
                    ])),
                    subtitle: a.nim == null ? null : Text(a.nim!, style: GuyubText.mono(size: 12, color: GuyubColors.inkMuted)),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Aksi untuk ${a.nama}',
                      onSelected: (v) async {
                        if (v == 'keluarkan') {
                          if (await _yakin(context, 'Keluarkan ${a.nama}?', '${a.nama} dikeluarkan dari sesi dan kelompoknya. Ia dan rekan kelompoknya diberi tahu.', 'Keluarkan', bahaya: true) &&
                              context.mounted) {
                            await _aksi(context, ref, d.id, () => ref.read(kelolaRepositoryProvider).keluarkan(d.id, a.id));
                          }
                        } else if (v == 'pindah') {
                          await _pindah(context, ref, d, k, a);
                        }
                      },
                      itemBuilder: (_) => [
                        if (dosen && d.kelompok.length > 1) const PopupMenuItem(value: 'pindah', child: Text('Pindahkan ke kelompok lain')),
                        const PopupMenuItem(value: 'keluarkan', child: Text('Keluarkan dari sesi')),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 6),
      Text('BUKTI PENGACAKAN', style: GuyubText.label),
      const SizedBox(height: 8),
      GuyubCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Nilai('Sidik jari', d.sidikJari),
          _Nilai('Seed', d.seed ?? '-'),
          _Nilai('Kode', d.kode),
          const SizedBox(height: 6),
          Text('Cek sendiri: SHA-256("${d.seed ?? 'seed'}:${d.kode}") harus sama dengan sidik jari yang tampil sejak sesi dibuat.', style: GuyubText.secondary),
        ]),
      ),
      const SizedBox(height: 16),
      if (d.bisaAcakUlang)
        GuyubButton(
          label: 'Acak ulang',
          icon: Icons.shuffle_rounded,
          variant: GuyubButtonVariant.danger,
          expand: true,
          onPressed: () => _acakUlang(context, ref, d),
        )
      else if (dosen)
        Text(
          'Acak ulang hanya untuk dosen pengampu, maksimal 1 kali, dalam 24 jam setelah dikunci dan sebelum ada peserta terlambat masuk.',
          style: GuyubText.secondary,
          textAlign: TextAlign.center,
        ),
      const SizedBox(height: 8),
      Text('Unduh daftar kelompok (CSV) tersedia di panel web.', style: GuyubText.secondary, textAlign: TextAlign.center),
    ];
  }

  // ---- K5 · acak ulang, khusus dosen ----
  Future<void> _acakUlang(BuildContext context, WidgetRef ref, DetailKelola d) async {
    final alasan = await _mintaAlasan(
      context,
      judul: 'Acak ulang kelompok?',
      keterangan: 'Hanya bisa 1 kali per sesi. Sistem membuat seed baru; hasil lama tetap tersimpan di riwayat. '
          'Alasan dikirim ke ${d.jumlahAnggota} peserta.',
      aksi: 'Acak ulang',
    );
    if (alasan == null || !context.mounted) return;
    await _aksi(context, ref, d.id, () => ref.read(kelolaRepositoryProvider).acakUlang(d.id, alasan));
  }

  Future<void> _pindah(BuildContext context, WidgetRef ref, DetailKelola d, KelompokKelola asal, Mahasiswa a) async {
    final tujuan = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Pindahkan ${a.nama} ke…', style: GuyubText.cardTitle)),
          for (final k in d.kelompok.where((k) => k.id != asal.id))
            ListTile(title: Text(k.nama), subtitle: Text('${k.anggota.length} anggota'), onTap: () => Navigator.pop(c, k.nomor)),
        ]),
      ),
    );
    if (tujuan == null || !context.mounted) return;
    final alasan = await _mintaAlasan(
      context,
      judul: 'Alasan pemindahan',
      keterangan: 'Alasan terlihat oleh anggota kedua kelompok.',
      aksi: 'Pindahkan',
    );
    if (alasan == null || !context.mounted) return;
    await _aksi(context, ref, d.id, () => ref.read(kelolaRepositoryProvider).pindah(d.id, a.id, tujuan, alasan));
  }

  static Future<String?> _mintaAlasan(BuildContext context, {required String judul, required String keterangan, required String aksi}) =>
      showDialog<String>(context: context, builder: (_) => _DialogAlasan(judul: judul, keterangan: keterangan, aksi: aksi));
}

class _DialogAlasan extends StatefulWidget {
  const _DialogAlasan({required this.judul, required this.keterangan, required this.aksi});
  final String judul;
  final String keterangan;
  final String aksi;

  @override
  State<_DialogAlasan> createState() => _DialogAlasanState();
}

class _DialogAlasanState extends State<_DialogAlasan> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cukup = _c.text.trim().length >= 10;
    return AlertDialog(
      title: Text(widget.judul),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.keterangan, style: GuyubText.secondary),
        const SizedBox(height: 12),
        TextField(
          controller: _c,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Alasan (minimal 10 huruf)'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        TextButton(
          onPressed: cukup ? () => Navigator.pop(context, _c.text.trim()) : null,
          child: Text(widget.aksi, style: TextStyle(color: cukup ? GuyubColors.danger : GuyubColors.inkFaint, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _TautanTerlambat extends StatelessWidget {
  const _TautanTerlambat({required this.sesiId, required this.jumlah});
  final int sesiId;
  final int jumlah;

  @override
  Widget build(BuildContext context) => Material(
        color: GuyubColors.pasarTint,
        borderRadius: BorderRadius.circular(GuyubRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(GuyubRadius.card),
          onTap: () => context.push('/tim/kelola/$sesiId/terlambat'),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const Icon(Icons.person_add_alt_outlined, color: GuyubColors.pasarText),
              const SizedBox(width: 10),
              Expanded(
                child: Text('$jumlah permintaan gabung terlambat menunggu persetujuan.',
                    style: GuyubText.fieldLabel.copyWith(color: GuyubColors.pasarText)),
              ),
              const Icon(Icons.chevron_right_rounded, color: GuyubColors.pasarText),
            ]),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.nilai);
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) => GuyubCard(
        child: Column(children: [
          Text(nilai, style: GuyubText.cardTitle.copyWith(fontSize: 20)),
          Text(label, style: GuyubText.secondary),
        ]),
      );
}

class _Nilai extends StatelessWidget {
  const _Nilai(this.label, this.nilai);
  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 80, child: Text(label, style: GuyubText.secondary)),
          Expanded(child: SelectableText(nilai, style: GuyubText.mono(size: 12.5, weight: FontWeight.w600))),
        ]),
      );
}
