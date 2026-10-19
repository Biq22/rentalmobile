import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import '../about_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  Map<String, dynamic>? _profil;
  bool _loading = true;
  String? _error;

  final _nama = TextEditingController();
  final _telp = TextEditingController();
  final _alamat = TextEditingController();
  final _pekerjaan = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nama.dispose();
    _telp.dispose();
    _alamat.dispose();
    _pekerjaan.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api().get('profil.php');
      _profil = res['data'] as Map<String, dynamic>;
      _nama.text = '${_profil!['nama'] ?? ''}';
      _telp.text = '${_profil!['no_telpon'] ?? ''}';
      _alamat.text = '${_profil!['alamat'] ?? ''}';
      _pekerjaan.text = '${_profil!['pekerjaan'] ?? ''}';
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfil() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama')),
              const SizedBox(height: 12),
              TextField(controller: _telp, decoration: const InputDecoration(labelText: 'No. telepon')),
              const SizedBox(height: 12),
              TextField(controller: _alamat, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat')),
              const SizedBox(height: 12),
              TextField(controller: _pekerjaan, decoration: const InputDecoration(labelText: 'Pekerjaan')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().put('profil.php', {
        'action': 'profil',
        'nama': _nama.text.trim(),
        'no_telpon': _telp.text.trim(),
        'alamat': _alamat.text.trim(),
        'pekerjaan': _pekerjaan.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, 'Profil diperbarui');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _gantiPassword() async {
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: oldC, obscureText: true, decoration: const InputDecoration(labelText: 'Password lama')),
          const SizedBox(height: 12),
          TextField(controller: newC, obscureText: true, decoration: const InputDecoration(labelText: 'Password baru (min 6)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ganti')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().put('profil.php', {'action': 'password', 'password_lama': oldC.text, 'password_baru': newC.text});
      if (mounted) showSnack(context, 'Password berhasil diganti');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);

    final foto = _profil!['foto'] as String?;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppBody(
            maxWidth: 900,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: AppColors.brandLight,
                      backgroundImage: (foto != null && foto.isNotEmpty) ? NetworkImage(Api().fotoUrl(foto)) : null,
                      child: (foto == null || foto.isEmpty) ? const Icon(Icons.person, size: 34, color: AppColors.brand) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${_profil!['nama'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${_profil!['email'] ?? ''}', style: const TextStyle(color: AppColors.muted)),
                        Text('${_profil!['no_telpon'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      ]),
                    ),
                    OutlinedButton(onPressed: _editProfil, child: const Text('Edit')),
                  ]),
                ),
                const SizedBox(height: 16),
                _menu(Icons.location_on_outlined, 'Alamat', '${_profil!['alamat'] ?? '-'}'),
                _menu(Icons.work_outline, 'Pekerjaan', '${_profil!['pekerjaan'] ?? '-'}'),
                _menu(Icons.badge_outlined, 'No. KTP', '${_profil!['no_ktp'] ?? '-'}'),
                const SizedBox(height: 8),
                _action(Icons.lock_outline, 'Ganti Password', _gantiPassword),
                _action(Icons.info_outline, 'Tentang Aplikasi', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()))),
                const SizedBox(height: 8),
                _action(Icons.logout, 'Keluar', _logout, danger: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Icon(icon, color: AppColors.brand),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ]),
      );

  Widget _action(IconData icon, String label, VoidCallback onTap, {bool danger = false}) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
              child: Row(children: [
                Icon(icon, color: danger ? AppColors.danger : AppColors.brand),
                const SizedBox(width: 14),
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: danger ? AppColors.danger : AppColors.ink)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
            ),
          ),
        ),
      );
}
