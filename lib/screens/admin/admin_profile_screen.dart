import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../about_screen.dart';
import '../auth/login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  Map<String, dynamic>? _profil;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api().get('profil.php');
      _profil = res['data'] as Map<String, dynamic>;
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
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
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppBody(
          maxWidth: 640,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                child: Row(children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.brandLight,
                    child: Text('${_profil!['nama'] ?? '?'}'.substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${_profil!['nama'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('${_profil!['email'] ?? ''}', style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 6),
                      StatusChip(label: '${_profil!['jabatan'] ?? ''}', color: AppColors.brand),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              _row(Icons.phone_outlined, 'No. telepon', '${_profil!['no_telpon'] ?? '-'}'),
              _row(Icons.home_outlined, 'Alamat', '${_profil!['alamat'] ?? '-'}'),
              const SizedBox(height: 8),
              _action(Icons.lock_outline, 'Ganti Password', _gantiPassword),
              _action(Icons.info_outline, 'Tentang Aplikasi', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()))),
              _action(Icons.logout, 'Keluar', _logout, danger: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) => Container(
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
