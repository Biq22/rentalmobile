import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> {
  List<Promo> _items = [];
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
      final res = await Api().get('promo.php');
      _items = (res['data'] as List).map((e) => Promo.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _form([Promo? p]) async {
    final kode = TextEditingController(text: p?.kode ?? '');
    final judul = TextEditingController(text: p?.judul ?? '');
    final desk = TextEditingController(text: p?.deskripsi ?? '');
    final nilai = TextEditingController(text: p == null ? '' : p.nilai.toStringAsFixed(0));
    final min = TextEditingController(text: p == null ? '0' : p.minTransaksi.toStringAsFixed(0));
    final maks = TextEditingController(text: p?.maksDiskon?.toStringAsFixed(0) ?? '');
    final mulai = TextEditingController(text: p?.tanggalMulai ?? '');
    final selesai = TextEditingController(text: p?.tanggalSelesai ?? '');
    var tipe = p?.tipe ?? 'persen';
    var aktif = p?.aktif ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(p == null ? 'Tambah Promo' : 'Edit Promo'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: kode, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Kode promo')),
                const SizedBox(height: 12),
                TextField(controller: judul, decoration: const InputDecoration(labelText: 'Judul promo')),
                const SizedBox(height: 12),
                TextField(controller: desk, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi (opsional)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipe,
                  decoration: const InputDecoration(labelText: 'Tipe diskon'),
                  items: const [
                    DropdownMenuItem(value: 'persen', child: Text('Persen (%)')),
                    DropdownMenuItem(value: 'nominal', child: Text('Nominal (Rp)')),
                  ],
                  onChanged: (v) => setLocal(() => tipe = v ?? 'persen'),
                ),
                const SizedBox(height: 12),
                TextField(controller: nilai, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tipe == 'persen' ? 'Nilai (%)' : 'Nilai (Rp)')),
                const SizedBox(height: 12),
                TextField(controller: min, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimal transaksi (Rp)')),
                const SizedBox(height: 12),
                TextField(controller: maks, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Maks diskon (Rp, opsional)')),
                const SizedBox(height: 12),
                TextField(controller: mulai, decoration: const InputDecoration(labelText: 'Tanggal mulai (YYYY-MM-DD, opsional)')),
                const SizedBox(height: 12),
                TextField(controller: selesai, decoration: const InputDecoration(labelText: 'Tanggal selesai (YYYY-MM-DD, opsional)')),
                SwitchListTile(
                  value: aktif,
                  onChanged: (v) => setLocal(() => aktif = v),
                  title: const Text('Aktif'),
                  activeThumbColor: AppColors.brand,
                  contentPadding: EdgeInsets.zero,
                ),
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
      final body = {
        'kode': kode.text.trim(),
        'judul': judul.text.trim(),
        'deskripsi': desk.text.trim(),
        'tipe': tipe,
        'nilai': double.tryParse(nilai.text.trim()) ?? 0,
        'min_transaksi': double.tryParse(min.text.trim()) ?? 0,
        'maks_diskon': maks.text.trim(),
        'aktif': aktif,
        'tanggal_mulai': mulai.text.trim(),
        'tanggal_selesai': selesai.text.trim(),
      };
      if (p == null) {
        await Api().post('promo.php', body);
      } else {
        await Api().put('promo.php', body, query: {'id': '${p.idPromo}'});
      }
      if (mounted) showSnack(context, 'Promo disimpan');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _hapus(Promo p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus promo?'),
        content: Text('Promo "${p.kode}" akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().delete('promo.php', query: {'id': '${p.idPromo}'});
      if (mounted) showSnack(context, 'Promo dihapus');
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
          maxWidth: 900,
          child: Column(
            children: [
              Row(children: [
                const Expanded(child: Text('Kelola Promo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                FilledButton.icon(onPressed: () => _form(), icon: const Icon(Icons.add), label: const Text('Tambah')),
              ]),
              const SizedBox(height: 16),
              if (_items.isEmpty)
                const AppEmpty(message: 'Belum ada promo.')
              else
                for (final p in _items)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                    child: Row(children: [
                      Container(
                        width: 52, height: 44,
                        decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(12)),
                        child: Center(
                          child: Text(p.persen ? '${p.nilai.toInt()}%' : 'Rp${p.nilai.toInt()}', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Text(p.kode, style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            StatusChip(label: p.aktif ? 'Aktif' : 'Nonaktif', color: p.aktif ? AppColors.success : AppColors.muted),
                          ]),
                          const SizedBox(height: 2),
                          Text(p.judul, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Min ${rupiah(p.minTransaksi)}${p.maksDiskon != null ? ' · maks ${rupiah(p.maksDiskon!)}' : ''}',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
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
