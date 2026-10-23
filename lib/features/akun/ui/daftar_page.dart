// Layar A3 · Daftar. Acuan visual: png/A3-Daftar.png di paket UI.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/sesi.dart';
import '../../../widgets/alert_box.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_input.dart';

class DaftarPage extends ConsumerStatefulWidget {
  const DaftarPage({super.key});

  @override
  ConsumerState<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends ConsumerState<DaftarPage> {
  final _nama = TextEditingController();
  final _nim = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  final _ulang = TextEditingController();
  bool _setuju = false;
  bool _loading = false;
  String? _galatUmum;
  Map<String, String> _galat = {};

  @override
  void dispose() {
    for (final c in [_nama, _nim, _email, _sandi, _ulang]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Cek dasar di HP supaya pesan tampil cepat; aturan pastinya (domain email, NIM unik) dicek server.
  Map<String, String> _cekLokal() {
    final g = <String, String>{};
    if (_nama.text.trim().length < 3) g['name'] = 'Nama wajib diisi.';
    if (_nim.text.trim().isEmpty) g['nim'] = 'NIM wajib diisi.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim())) g['email'] = 'Format email salah.';
    if (_sandi.text.length < 8) {
      g['password'] = 'Kata sandi minimal 8 karakter.';
    } else if (_sandi.text != _ulang.text) {
      g['password_confirmation'] = 'Konfirmasi kata sandi tidak sama.';
    }
    return g;
  }

  Future<void> _daftar() async {
    final lokal = _cekLokal();
    if (!_setuju) {
      setState(() {
        _galat = lokal;
        _galatUmum = 'Centang persetujuan Syarat & Ketentuan untuk melanjutkan.';
      });
      return;
    }
    if (lokal.isNotEmpty) {
      setState(() {
        _galat = lokal;
        _galatUmum = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _galat = {};
      _galatUmum = null;
    });
    try {
      await ref.read(sesiProvider).daftar(
            nama: _nama.text.trim(),
            nim: _nim.text.trim(),
            email: _email.text.trim().toLowerCase(),
            sandi: _sandi.text,
            ulangSandi: _ulang.text,
          );
      // Router memindahkan ke layar Verifikasi email.
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _galat = e.fieldErrors;
          _galatUmum = e.fieldErrors.isEmpty ? e.message : null;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/awal'),
        ),
        title: const Text('Buat akun'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text('Satu akun untuk Cari Tim, Booking Ruang, dan Pasar.', style: GuyubText.body.copyWith(color: GuyubColors.inkMuted)),
                const SizedBox(height: 16),
                if (_galatUmum != null) ...[
                  AlertBox(_galatUmum!, tone: AlertTone.galat),
                  const SizedBox(height: 16),
                ],
                GuyubInput(label: 'Nama lengkap', controller: _nama, textInputAction: TextInputAction.next, errorText: _galat['name']),
                const SizedBox(height: 14),
                GuyubInput(label: 'NIM', controller: _nim, mono: true, keyboardType: TextInputType.number, textInputAction: TextInputAction.next, errorText: _galat['nim']),
                const SizedBox(height: 14),
                GuyubInput(
                  label: 'Email kampus',
                  controller: _email,
                  hint: 'nama@mhs.kampus.ac.id',
                  helper: 'Hanya email kampus yang bisa mendaftar.',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _galat['email'],
                ),
                const SizedBox(height: 14),
                GuyubInput(label: 'Kata sandi', controller: _sandi, obscure: true, helper: 'Minimal 8 karakter.', textInputAction: TextInputAction.next, errorText: _galat['password']),
                const SizedBox(height: 14),
                GuyubInput(
                  label: 'Ulangi kata sandi',
                  controller: _ulang,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _daftar(),
                  errorText: _galat['password_confirmation'],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setState(() => _setuju = !_setuju),
                  borderRadius: BorderRadius.circular(GuyubRadius.small),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Checkbox(value: _setuju, onChanged: (v) => setState(() => _setuju = v ?? false), activeColor: GuyubColors.primary),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Saya menyetujui Syarat & Ketentuan dan Kebijakan Privasi Guyub.', style: GuyubText.secondary.copyWith(color: GuyubColors.inkBody)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                GuyubButton(label: 'Daftar', expand: true, loading: _loading, onPressed: _daftar),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Sudah punya akun? ', style: GuyubText.body.copyWith(color: GuyubColors.inkMuted)),
                  TextButton(
                    onPressed: () => context.pushReplacement('/masuk'),
                    child: Text('Masuk', style: GuyubText.body.copyWith(color: GuyubColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
