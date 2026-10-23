// Layar A4 · Verifikasi email. Acuan visual: png/A4-Verifikasi.png di paket UI.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/sesi.dart';
import '../../../widgets/alert_box.dart';
import '../../../widgets/guyub_button.dart';
import '../data/auth_repository.dart';

class VerifikasiPage extends ConsumerStatefulWidget {
  const VerifikasiPage({super.key});

  @override
  ConsumerState<VerifikasiPage> createState() => _VerifikasiPageState();
}

class _VerifikasiPageState extends ConsumerState<VerifikasiPage> {
  static const _jeda = 60;
  int _sisa = _jeda;
  Timer? _timer;
  bool _mengecek = false;
  bool _mengirim = false;
  (String, AlertTone)? _pesan;

  @override
  void initState() {
    super.initState();
    _mulaiHitung();
  }

  void _mulaiHitung() {
    _timer?.cancel();
    setState(() => _sisa = _jeda);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sisa <= 1) t.cancel();
      if (mounted) setState(() => _sisa--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _kirimUlang() async {
    setState(() => _mengirim = true);
    try {
      final pesan = await ref.read(authRepositoryProvider).kirimUlangVerifikasi();
      _mulaiHitung();
      setState(() => _pesan = (pesan, AlertTone.sukses));
    } on ApiException catch (e) {
      setState(() => _pesan = (e.message, AlertTone.galat));
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  Future<void> _cekLagi() async {
    setState(() => _mengecek = true);
    try {
      await ref.read(sesiProvider).segarkan();
      // Sudah terverifikasi → router pindah ke Beranda.
      if (mounted && !(ref.read(sesiProvider).pengguna?.terverifikasi ?? false)) {
        setState(() => _pesan = ('Email belum terverifikasi. Buka tautan di email kampusmu dulu.', AlertTone.peringatan));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _pesan = (e.message, AlertTone.galat));
    } finally {
      if (mounted) setState(() => _mengecek = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sesiProvider).pengguna?.email ?? '';
    final menit = '${_sisa ~/ 60}:${(_sisa % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi email'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: GuyubColors.primaryTint, borderRadius: BorderRadius.circular(20)),
                    child: const Icon(Icons.mark_email_unread_outlined, size: 34, color: GuyubColors.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Cek email kamu', textAlign: TextAlign.center, style: GuyubText.pageTitle.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(style: GuyubText.body.copyWith(color: GuyubColors.inkBody), children: [
                    const TextSpan(text: 'Tautan verifikasi sudah dikirim ke '),
                    TextSpan(text: email, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const TextSpan(text: '. Buka tautannya untuk mengaktifkan akun.'),
                  ]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text('Tidak ada di kotak masuk? Cek folder spam.', textAlign: TextAlign.center, style: GuyubText.secondary),
                const SizedBox(height: 24),
                if (_pesan != null) ...[
                  AlertBox(_pesan!.$1, tone: _pesan!.$2),
                  const SizedBox(height: 16),
                ],
                GuyubButton(label: 'Saya sudah verifikasi', expand: true, loading: _mengecek, onPressed: _cekLagi),
                const SizedBox(height: 12),
                GuyubButton(
                  label: _sisa > 0 ? 'Kirim ulang email ($menit)' : 'Kirim ulang email',
                  variant: GuyubButtonVariant.neutral,
                  expand: true,
                  loading: _mengirim,
                  onPressed: _sisa > 0 ? null : _kirimUlang,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.read(sesiProvider).keluar(),
                  child: Text('Salah email? Keluar dan daftar ulang', style: GuyubText.fieldLabel.copyWith(color: GuyubColors.primary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
