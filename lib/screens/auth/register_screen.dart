import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../pelanggan/customer_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _telp = TextEditingController();
  final _ktp = TextEditingController();
  final _alamat = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _telp.dispose();
    _ktp.dispose();
    _alamat.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if ([_nama, _email, _telp, _ktp, _alamat, _pass].any((c) => c.text.trim().isEmpty)) {
      showSnack(context, 'Semua field wajib diisi', error: true);
      return;
    }
    if (_pass.text.length < 6) {
      showSnack(context, 'Password minimal 6 karakter', error: true);
      return;
    }
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    try {
      await Api().post('register.php', {
        'nama': _nama.text.trim(),
        'email': _email.text.trim(),
        'no_telpon': _telp.text.trim(),
        'no_ktp': _ktp.text.trim(),
        'alamat': _alamat.text.trim(),
        'password': _pass.text,
      });
      await auth.login(_email.text.trim(), _pass.text);
      if (!mounted) return;
      showSnack(context, 'Registrasi berhasil. Selamat datang!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Buat akun baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Isi data diri kamu dengan benar untuk mulai menyewa.', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 24),
                  _field('Nama lengkap', _nama, Icons.person_outline, hint: 'Nama sesuai KTP'),
                  _field('Email', _email, Icons.alternate_email, hint: 'nama@email.com', type: TextInputType.emailAddress),
                  _field('No. telepon', _telp, Icons.phone_outlined, hint: '08xxxxxxxxxx', type: TextInputType.phone),
                  _field('No. KTP', _ktp, Icons.badge_outlined, hint: '16 digit NIK', type: TextInputType.number),
                  _field('Alamat', _alamat, Icons.home_outlined, hint: 'Alamat domisili'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: _pass,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Minimal 6 karakter',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Text('Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon, {String? hint, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon)),
      ),
    );
  }
}
