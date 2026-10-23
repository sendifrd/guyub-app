// Layar A5 · Lupa kata sandi. Acuan visual: png/A5-LupaSandi.png di paket UI.
// Tautan reset di email membuka halaman web Laravel (/reset-sandi/{token}).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/api_client.dart';
import '../../../widgets/alert_box.dart';
import '../../../widgets/guyub_button.dart';
import '../../../widgets/guyub_input.dart';
import '../data/auth_repository.dart';

class LupaSandiPage extends ConsumerStatefulWidget {
  const LupaSandiPage({super.key});

  @override
  ConsumerState<LupaSandiPage> createState() => _LupaSandiPageState();
}

class _LupaSandiPageState extends ConsumerState<LupaSandiPage> {
  final _email = TextEditingController();
  bool _loading = false;
  (String, AlertTone)? _pesan;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final email = _email.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _pesan = ('Masukkan email kampusmu dengan benar.', AlertTone.galat));
      return;
    }
    setState(() {
      _loading = true;
      _pesan = null;
    });
    try {
      final pesan = await ref.read(authRepositoryProvider).lupaSandi(email);
      setState(() => _pesan = ('$pesan Tautan berlaku 60 menit.', AlertTone.sukses));
    } on ApiException catch (e) {
      setState(() => _pesan = (e.message, AlertTone.galat));
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
          onPressed: () => context.canPop() ? context.pop() : context.go('/masuk'),
        ),
        title: const Text('Lupa kata sandi'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                Text('Masukkan email kampus kamu. Kami kirim tautan untuk membuat kata sandi baru.', style: GuyubText.body.copyWith(color: GuyubColors.inkBody)),
                const SizedBox(height: 20),
                if (_pesan != null) ...[
                  AlertBox(_pesan!.$1, tone: _pesan!.$2),
                  const SizedBox(height: 16),
                ],
                GuyubInput(
                  label: 'Email kampus',
                  controller: _email,
                  hint: 'nama@mhs.kampus.ac.id',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _kirim(),
                ),
                const SizedBox(height: 16),
                GuyubButton(label: 'Kirim tautan reset', expand: true, loading: _loading, onPressed: _kirim),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Ingat kata sandimu? ', style: GuyubText.body.copyWith(color: GuyubColors.inkMuted)),
                  TextButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/masuk'),
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
