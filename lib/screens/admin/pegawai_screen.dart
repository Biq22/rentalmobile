import 'package:flutter/material.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class PegawaiScreen extends StatefulWidget {
  const PegawaiScreen({super.key});

  @override
  State<PegawaiScreen> createState() => _PegawaiScreenState();
}

class _PegawaiScreenState extends State<PegawaiScreen> {
  List<Pegawai> _items = [];
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
      final res = await Api().get('pegawai.php');
      _items = (res['data'] as List).map((e) => Pegawai.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _form([Pegawai? p]) async {
    final nama = TextEditingController(text: p?.nama ?? '');
    final username = TextEditingController(text: p?.username ?? '');
    final email = TextEditingController(text: p?.email ?? '');
    final telp = TextEditingController(text: p?.noTelepon ?? '');
    final jabatan = TextEditingController(text: p?.jabatan ?? 'Staff');
    final alamat = TextEditingController(text: p?.alamat ?? '');
    final pass = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p == null ? 'Tambah Pegawai' : 'Edit Pegawai'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _f(nama, 'Nama'),
              _f(username, 'Username'),
              _f(email, 'Email'),
              _f(telp, 'No. telepon'),
              _f(jabatan, 'Jabatan (isi "admin" untuk hak penuh)'),
              _f(alamat, 'Alamat'),
              _f(pass, p == null ? 'Password' : 'Password baru (opsional)', obscure: true),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    final body = {
      'nama': nama.text.trim(),
      'username': username.text.trim(),
      'email': email.text.trim(),
      'no_telepon': telp.text.trim(),
      'jabatan': jabatan.text.trim(),
      'alamat': alamat.text.trim(),
      'password': pass.text,
    };
    try {
      if (p == null) {
        await Api().post('pegawai.php', body);
      } else {
        await Api().put('pegawai.php', body, query: {'id': '${p.id}'});
      }
      if (mounted) showSnack(context, 'Data pegawai disimpan');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Widget _f(TextEditingController c, String label, {bool obscure = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(controller: c, obscureText: obscure, decoration: InputDecoration(labelText: label)),
      );

  Future<void> _hapus(Pegawai p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus pegawai?'),
        content: Text('${p.nama} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().delete('pegawai.php', query: {'id': '${p.id}'});
      if (mounted) showSnack(context, 'Pegawai dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppBody(
          maxWidth: 820,
          child: Column(
            children: [
              Row(children: [
                const Expanded(child: Text('Kelola Pegawai', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Tambah')),
              ]),
              const SizedBox(height: 12),
              for (final p in _items)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: p.isAdmin ? AppColors.brandLight : AppColors.surface,
                      child: Icon(p.isAdmin ? Icons.admin_panel_settings : Icons.badge_outlined, color: p.isAdmin ? AppColors.brand : AppColors.muted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          StatusChip(label: p.jabatan, color: p.isAdmin ? AppColors.brand : AppColors.info),
                        ]),
                        const SizedBox(height: 4),
                        Text('${p.email} · ${p.noTelepon}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ]),
                    ),
                    IconButton(onPressed: () => _form(p), icon: const Icon(Icons.edit_outlined, color: AppColors.brand)),
                    IconButton(onPressed: () => _hapus(p), icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
