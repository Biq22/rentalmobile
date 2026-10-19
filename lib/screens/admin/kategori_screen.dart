import 'package:flutter/material.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class KategoriScreen extends StatefulWidget {
  const KategoriScreen({super.key});

  @override
  State<KategoriScreen> createState() => _KategoriScreenState();
}

class _KategoriScreenState extends State<KategoriScreen> {
  List<Kategori> _items = [];
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
      final res = await Api().get('kategori.php');
      _items = (res['data'] as List).map((e) => Kategori.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _form([Kategori? k]) async {
    final nama = TextEditingController(text: k?.nama ?? '');
    final ikon = TextEditingController(text: k?.ikon ?? '');
    final desk = TextEditingController(text: k?.deskripsi ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(k == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama kategori')),
            const SizedBox(height: 12),
            TextField(controller: ikon, decoration: const InputDecoration(labelText: 'Ikon (emoji, opsional)')),
            const SizedBox(height: 12),
            TextField(controller: desk, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final body = {'nama': nama.text.trim(), 'ikon': ikon.text.trim(), 'deskripsi': desk.text.trim()};
      if (k == null) {
        await Api().post('kategori.php', body);
      } else {
        await Api().put('kategori.php', body, query: {'id': '${k.idKategori}'});
      }
      if (mounted) showSnack(context, 'Kategori disimpan');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _hapus(Kategori k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus kategori?'),
        content: Text('Kategori "${k.nama}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().delete('kategori.php', query: {'id': '${k.idKategori}'});
      if (mounted) showSnack(context, 'Kategori dihapus');
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
                const Expanded(child: Text('Kelola Kategori', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Tambah')),
              ]),
              const SizedBox(height: 16),
              if (_items.isEmpty)
                const AppEmpty(message: 'Belum ada kategori.')
              else
                for (final k in _items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(k.ikon?.isNotEmpty == true ? k.ikon! : '🚗', style: const TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(k.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text('${k.jumlahMobil} mobil${k.deskripsi != null && k.deskripsi!.isNotEmpty ? ' · ${k.deskripsi}' : ''}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ]),
                      ),
                      IconButton(onPressed: () => _form(k), icon: const Icon(Icons.edit_outlined, color: AppColors.brand)),
                      IconButton(onPressed: () => _hapus(k), icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
                    ]),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
