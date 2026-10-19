import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/uploader.dart';
import '../../widgets/common.dart';

class SupirScreen extends StatefulWidget {
  const SupirScreen({super.key});

  @override
  State<SupirScreen> createState() => _SupirScreenState();
}

class _SupirScreenState extends State<SupirScreen> {
  List<Supir> _items = [];
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
      final res = await Api().get('supir.php');
      _items = (res['data'] as List).map((e) => Supir.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _form([Supir? s]) async {
    final nama = TextEditingController(text: s?.nama ?? '');
    final telp = TextEditingController(text: s?.noTelpon ?? '');
    final sim = TextEditingController(text: s?.noSim ?? '');
    final harga = TextEditingController(text: s == null ? '' : s.hargaPerHari.toStringAsFixed(0));
    String? foto = s?.foto;
    String status = s?.status ?? 'aktif';
    bool busy = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(s == null ? 'Tambah Supir' : 'Edit Supir'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama supir')),
                const SizedBox(height: 12),
                TextField(controller: telp, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'No. telepon / WA')),
                const SizedBox(height: 12),
                TextField(controller: sim, decoration: const InputDecoration(labelText: 'No. SIM')),
                const SizedBox(height: 12),
                TextField(controller: harga, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga per hari (Rp)')),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                        DropdownMenuItem(value: 'nonaktif', child: Text('Nonaktif')),
                      ],
                      onChanged: (v) => setD(() => status = v ?? 'aktif'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.brandLight,
                      backgroundImage: (foto != null && foto!.isNotEmpty) ? NetworkImage(Api().fotoUrl(foto)) : null,
                      child: (foto == null || foto!.isEmpty) ? const Icon(Icons.person, color: AppColors.brand) : null,
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () async {
                              final r = await pickAndUploadImage(ctx, onBusy: (b) => setD(() => busy = b));
                              if (r != null) setD(() => foto = r.filename);
                            },
                      child: const Text('Foto'),
                    ),
                  ]),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      try {
                        final body = <String, dynamic>{
                          'nama': nama.text.trim(),
                          'no_telpon': telp.text.trim(),
                          'no_sim': sim.text.trim(),
                          'harga_per_hari': double.tryParse(harga.text.trim()) ?? 0,
                          'status': status,
                          if (foto != null && foto!.isNotEmpty) 'foto': foto,
                        };
                        if (s == null) {
                          await Api().post('supir.php', body);
                        } else {
                          await Api().put('supir.php', body, query: {'id': '${s.idSupir}'});
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) showSnack(context, 'Supir disimpan');
                        _load();
                      } on ApiException catch (e) {
                        if (mounted) showSnack(context, e.message, error: true);
                      }
                    },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapus(Supir s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus supir?'),
        content: Text('Supir "${s.nama}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().delete('supir.php', query: {'id': '${s.idSupir}'});
      if (mounted) showSnack(context, 'Supir dihapus');
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
                const Expanded(child: Text('Kelola Supir', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Tambah')),
              ]),
              const SizedBox(height: 16),
              if (_items.isEmpty)
                const AppEmpty(message: 'Belum ada data supir.', icon: Icons.person_pin_circle_outlined)
              else
                for (final s in _items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.brandLight,
                        backgroundImage: (s.foto != null && s.foto!.isNotEmpty) ? NetworkImage(Api().fotoUrl(s.foto)) : null,
                        child: (s.foto == null || s.foto!.isEmpty) ? const Icon(Icons.person, color: AppColors.brand) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(s.nama, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            StatusChip(label: s.aktif ? 'Aktif' : 'Nonaktif', color: s.aktif ? AppColors.success : AppColors.muted),
                          ]),
                          const SizedBox(height: 2),
                          Text('${s.noTelpon} · SIM ${s.noSim}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          Text('${rupiah(s.hargaPerHari)} /hari', style: const TextStyle(color: AppColors.brand, fontSize: 12, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      IconButton(onPressed: () => _form(s), icon: const Icon(Icons.edit_outlined, color: AppColors.brand)),
                      IconButton(onPressed: () => _hapus(s), icon: const Icon(Icons.delete_outline, color: AppColors.danger)),
                    ]),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
