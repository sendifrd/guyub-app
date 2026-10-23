// Layar A2 · Masuk. Acuan visual: png/A2-Masuk.png di paket UI.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../core/sesi.dart';
import '../../../widgets/alert_box.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_input.dart';
import '../../../widgets/guyub_logo.dart';

class MasukPage extends ConsumerStatefulWidget {
  const MasukPage({super.key});

  @override
  ConsumerState<MasukPage> createState() => _MasukPageState();
}

class _MasukPageState extends ConsumerState<MasukPage> {
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _loading = false;
  bool _lihatSandi = false;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty || _sandi.text.isEmpty) {
      setState(() => _galat = 'Isi email kampus dan kata sandi.');
      return;
    }
    setState(() {
      _loading = true;
      _galat = null;
    });
    try {
      // Router otomatis pindah ke Beranda (atau Verifikasi email) begitu sesi berubah.
      await ref.read(sesiProvider).masuk(email, _sandi.text);
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: GuyubColors.kapur,
        shape: const Border(),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.canPop() ? context.pop() : context.go('/awal'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                const Align(alignment: Alignment.centerLeft, child: GuyubLogo(size: 48)),
                const SizedBox(height: 12),
                Text('Masuk ke Guyub', style: GuyubText.pageTitle.copyWith(fontSize: 26, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Pakai email kampus yang kamu daftarkan.', style: GuyubText.body.copyWith(color: GuyubColors.inkMuted)),
                const SizedBox(height: 24),
                if (_galat != null) ...[
                  AlertBox(_galat!, tone: AlertTone.galat),
                  const SizedBox(height: 16),
                ],
                GuyubInput(
                  label: 'Email kampus',
                  controller: _email,
                  hint: 'nama@mhs.kampus.ac.id',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                GuyubInput(
                  label: 'Kata sandi',
                  controller: _sandi,
                  obscure: !_lihatSandi,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _masuk(),
                  suffix: IconButton(
                    tooltip: _lihatSandi ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                    icon: Icon(_lihatSandi ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _lihatSandi = !_lihatSandi),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/lupa-sandi'),
                    child: Text('Lupa kata sandi?', style: GuyubText.fieldLabel.copyWith(color: GuyubColors.primary)),
                  ),
                ),
                const SizedBox(height: 8),
                GuyubButton(label: 'Masuk', expand: true, loading: _loading, onPressed: _masuk),
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Belum punya akun? ', style: GuyubText.body.copyWith(color: GuyubColors.inkMuted)),
                  TextButton(
                    onPressed: () => context.pushReplacement('/daftar'),
                    child: Text('Daftar', style: GuyubText.body.copyWith(color: GuyubColors.primary, fontWeight: FontWeight.w700)),
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
