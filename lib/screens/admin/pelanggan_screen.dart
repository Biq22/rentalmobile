import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/uploader.dart';
import '../../widgets/common.dart';

class PelangganScreen extends StatefulWidget {
  const PelangganScreen({super.key});

  @override
  State<PelangganScreen> createState() => _PelangganScreenState();
}

class _PelangganScreenState extends State<PelangganScreen> {
  List<Pelanggan> _items = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = _search.text.trim().isEmpty ? null : {'q': _search.text.trim()};
      final res = await Api().get('pelanggan.php', query: q);
      _items = (res['data'] as List).map((e) => Pelanggan.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(Pelanggan p) async {
    final nama = TextEditingController(text: p.nama);
    final email = TextEditingController(text: p.email);
    final telp = TextEditingController(text: p.noTelpon);
    final ktp = TextEditingController(text: p.noKtp);
    final alamat = TextEditingController(text: p.alamat);
    final pekerjaan = TextEditingController(text: p.pekerjaan ?? '');
    String? foto = p.foto;
    Uint8List? localBytes;
    var uploading = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Edit ${p.nama}'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  ClipOval(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: localBytes != null
                          ? Image.memory(localBytes!, fit: BoxFit.cover)
                          : Api().fotoUrl(foto).isEmpty
                              ? Container(color: AppColors.brandLight, child: const Icon(Icons.person, color: AppColors.brand))
                              : Image.network(
                                  Api().fotoUrl(foto),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: AppColors.brandLight, child: const Icon(Icons.person, color: AppColors.brand)),
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: uploading
                        ? null
                        : () async {
                            final res = await pickAndUploadImage(context, onBusy: (busy) => setLocal(() => uploading = busy));
                            if (res != null) {
                              setLocal(() {
                                foto = res.filename;
                                localBytes = res.bytes;
                              });
                            }
                          },
                    icon: uploading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload),
                    label: Text(uploading ? 'Mengunggah…' : 'Ganti Foto'),
                  ),
                ]),
                const SizedBox(height: 14),
                TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama')),
                const SizedBox(height: 12),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: telp, decoration: const InputDecoration(labelText: 'No. telepon')),
                const SizedBox(height: 12),
                TextField(controller: ktp, decoration: const InputDecoration(labelText: 'No. KTP')),
                const SizedBox(height: 12),
                TextField(controller: alamat, decoration: const InputDecoration(labelText: 'Alamat')),
                const SizedBox(height: 12),
                TextField(controller: pekerjaan, decoration: const InputDecoration(labelText: 'Pekerjaan')),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await Api().put('pelanggan.php', {
        'id_pelanggan': p.idPelanggan,
        'nama': nama.text.trim(),
        'email': email.text.trim(),
        'no_telpon': telp.text.trim(),
        'no_ktp': ktp.text.trim(),
        'alamat': alamat.text.trim(),
        'pekerjaan': pekerjaan.text.trim(),
        'foto': foto,
      });
      if (mounted) showSnack(context, 'Data pelanggan diperbarui');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _hapus(Pelanggan p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus pelanggan?'),
        content: Text('${p.nama} akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().delete('pelanggan.php', query: {'id': '${p.idPelanggan}'});
      if (mounted) showSnack(context, 'Pelanggan dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBody(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Cari nama / email / telepon…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
              ),
            ),
          ),
        ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    if (_items.isEmpty) return const AppEmpty(title: 'Belum ada pelanggan', message: 'Data pelanggan terdaftar akan muncul di sini.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final p = _items[i];
          final url = Api().fotoUrl(p.foto);
          return AppBody(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
              child: Row(children: [
                CircleAvatar(radius: 26, backgroundColor: AppColors.brandLight, backgroundImage: url.isEmpty ? null : NetworkImage(url),
                    child: url.isEmpty ? Text(p.nama.isNotEmpty ? p.nama[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800)) : null),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${p.email} · ${p.noTelpon}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${p.jumlahPesanan} pesanan', style: const TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
                IconButton(onPressed: () => _edit(p), icon: const Icon(Icons.edit_outlined, color: AppColors.brand)),
                IconButton(onPressed: () => _hapus(p), icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
              ]),
            ),
          );
        },
      ),
    );
  }
}
