// Layar K2 · Buat sesi kelompok.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../core/api_client.dart';
import '../../../../widgets/alert_box.dart';
import '../../../../widgets/guyub_button.dart';
import '../../../../widgets/guyub_card.dart';
import '../../../../widgets/guyub_input.dart';
import '../../../../widgets/keadaan.dart';
import '../../data/kelola_repository.dart';

class BuatSesiPage extends ConsumerStatefulWidget {
  const BuatSesiPage({super.key});

  @override
  ConsumerState<BuatSesiPage> createState() => _BuatSesiPageState();
}

class _BuatSesiPageState extends ConsumerState<BuatSesiPage> {
  final _judul = TextEditingController();
  int? _kelasId;
  String _mode = 'ukuran';
  int _nilai = 5;
  late DateTime _tanggal;
  TimeOfDay _jam = const TimeOfDay(hour: 21, minute: 0);

  String? _pratinjau;
  Timer? _tunda;
  bool _kirim = false;
  ApiException? _galat;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now().add(const Duration(days: 3));
    _tanggal = DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _judul.dispose();
    _tunda?.cancel();
    super.dispose();
  }

  DateTime get _batas => DateTime(_tanggal.year, _tanggal.month, _tanggal.day, _jam.hour, _jam.minute);

  /// Pratinjau "23 mahasiswa → 4 kelompok (6, 6, 6, 5)" diminta ke server setelah isian berhenti berubah.
  void _muatPratinjau() {
    _tunda?.cancel();
    final id = _kelasId;
    if (id == null) return;
    _tunda = Timer(const Duration(milliseconds: 350), () async {
      try {
        final t = await ref.read(kelolaRepositoryProvider).pratinjau(courseId: id, mode: _mode, nilai: _nilai);
        if (mounted) setState(() => _pratinjau = t);
      } on ApiException catch (e) {
        if (mounted) setState(() => _pratinjau = e.message);
      }
    });
  }

  void _ubah(VoidCallback f) {
    setState(f);
    _muatPratinjau();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 120)),
    );
    if (t != null) setState(() => _tanggal = t);
  }

  Future<void> _pilihJam() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _jam,
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t != null) setState(() => _jam = t);
  }

  Future<void> _simpan() async {
    final id = _kelasId;
    if (id == null) {
      setState(() => _galat = ApiException('Pilih mata kuliah dan kelas.'));
      return;
    }
    if (!_batas.isAfter(DateTime.now().add(const Duration(minutes: 10)))) {
      setState(() => _galat = ApiException('Batas gabung minimal 10 menit dari sekarang.'));
      return;
    }
    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      final d = await ref.read(kelolaRepositoryProvider).buat(
            courseId: id,
            judul: _judul.text,
            mode: _mode,
            nilai: _nilai,
            batasJoin: DateFormat('yyyy-MM-dd HH:mm').format(_batas),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sesi dibuat. Kode: ${d.kode}')));
      context.pushReplacement('/tim/kelola/${d.id}');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _kirim = false;
          _galat = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kelas = ref.watch(kelasKelolaProvider);

    return Scaffold(
      backgroundColor: GuyubColors.kapur,
      appBar: AppBar(title: const Text('Buat sesi kelompok')),
      body: kelas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => KeadaanGalat(pesan: e is ApiException ? e.message : 'Kelas gagal dimuat.', onCobaLagi: () => ref.invalidate(kelasKelolaProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const KeadaanKosong(ikon: Icons.school_outlined, pesan: 'Kamu belum menjadi dosen pengampu atau ketua kelas di kelas mana pun.');
          }
          if (_kelasId == null && list.length == 1) {
            _kelasId = list.first.id;
            WidgetsBinding.instance.addPostFrameCallback((_) => _muatPratinjau());
          }
          final g = _galat;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Text('Mata kuliah dan kelas', style: GuyubText.fieldLabel),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: _kelasId,
              isExpanded: true,
              hint: const Text('Pilih kelas'),
              items: [
                for (final k in list)
                  DropdownMenuItem(value: k.id, child: Text('${k.matkul.label} (${k.jumlahMahasiswa} mhs)', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => _ubah(() => _kelasId = v),
              decoration: InputDecoration(errorText: g?.field('course_id')),
            ),
            const SizedBox(height: 6),
            Text('Hanya kelas tempat kamu ketua kelas atau dosen pengampu.', style: GuyubText.secondary),
            const SizedBox(height: 16),
            GuyubInput(label: 'Judul tugas', controller: _judul, hint: 'Contoh: Tugas Besar ERD', errorText: g?.field('judul')),
            const SizedBox(height: 16),
            Text('Cara membagi', style: GuyubText.fieldLabel),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ukuran', label: Text('Per jumlah anggota')),
                ButtonSegment(value: 'jumlah', label: Text('Per jumlah kelompok')),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (v) => _ubah(() {
                _mode = v.first;
                _nilai = _mode == 'ukuran' ? 5 : 4;
              }),
            ),
            const SizedBox(height: 14),
            GuyubCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text(_mode == 'ukuran' ? 'Anggota per kelompok' : 'Jumlah kelompok', style: GuyubText.fieldLabel)),
                  IconButton.outlined(
                    tooltip: 'Kurangi',
                    onPressed: _nilai > (_mode == 'ukuran' ? 2 : 1) ? () => _ubah(() => _nilai--) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  SizedBox(width: 44, child: Text('$_nilai', textAlign: TextAlign.center, style: GuyubText.mono(size: 20, weight: FontWeight.w600))),
                  IconButton.outlined(
                    tooltip: 'Tambah',
                    onPressed: _nilai < 50 ? () => _ubah(() => _nilai++) : null,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ]),
                if (g?.field('nilai') != null) Text(g!.field('nilai')!, style: GuyubText.secondary.copyWith(color: GuyubColors.danger)),
                if (_pratinjau != null) ...[
                  const SizedBox(height: 8),
                  Text('Perkiraan: $_pratinjau. Sisa peserta disebar rata.', style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody)),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Text('Batas gabung', style: GuyubText.fieldLabel),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _pilihTanggal,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(DateFormat('EEE, d MMM yyyy', 'id_ID').format(_tanggal)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _pilihJam,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text('${_jam.hour.toString().padLeft(2, '0')}.${_jam.minute.toString().padLeft(2, '0')} WIB'),
                ),
              ),
            ]),
            if (g?.field('batas_join') != null) ...[
              const SizedBox(height: 6),
              Text(g!.field('batas_join')!, style: GuyubText.secondary.copyWith(color: GuyubColors.danger)),
            ],
            const SizedBox(height: 16),
            const AlertBox(
              'Hanya mahasiswa yang terdaftar di kelas ini yang boleh gabung. Saat batas gabung tiba, sistem mengacak dan langsung mengunci kelompok.',
            ),
            if (g != null && g.fieldErrors.isEmpty) ...[
              const SizedBox(height: 10),
              AlertBox(g.message, tone: AlertTone.galat),
            ],
            const SizedBox(height: 18),
            GuyubButton(label: 'Buat dan dapatkan kode', expand: true, loading: _kirim, onPressed: _simpan),
          ]);
        },
      ),
    );
  }
}
