import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class PembayaranScreen extends StatefulWidget {
  const PembayaranScreen({super.key});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  List<Pembayaran> _items = [];
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
      final res = await Api().get('pembayaran.php');
      _items = (res['data'] as List).map((e) => Pembayaran.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ubah(Pembayaran p, String status, {String? catatan}) async {
    try {
      await Api().put('pembayaran.php', {
        'id_pembayaran': p.idPembayaran,
        'status_pembayaran': status,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      });
      if (mounted) showSnack(context, 'Status pembayaran: $status');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _verifikasi(Pembayaran p) async {
    final catatan = TextEditingController(text: p.catatan ?? '');
    final aksi = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verifikasi #${p.idPesanan}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (p.bukti != null && p.bukti!.isNotEmpty) ...[
                const Text('Bukti pembayaran', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(Api().fotoUrl(p.bukti), height: 220, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Text('Gagal memuat bukti')),
                ),
                const SizedBox(height: 14),
              ] else
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text('Pelanggan belum mengunggah bukti.', style: TextStyle(color: AppColors.muted)),
                ),
              TextField(controller: catatan, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan verifikasi (opsional)')),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'Gagal'), child: const Text('Tolak', style: TextStyle(color: AppColors.danger))),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'Lunas'), child: const Text('Setujui / Lunas')),
        ],
      ),
    );
    if (aksi == null) return;
    await _ubah(p, aksi, catatan: catatan.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    if (_items.isEmpty) return const AppEmpty(title: 'Belum ada pembayaran', message: 'Data pembayaran akan muncul di sini.');
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  void _lihatBukti(Pembayaran p) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 10),
              Flexible(child: Image.network(Api().fotoUrl(p.bukti), fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('Gagal memuat bukti'))),
              const SizedBox(height: 10),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _card(Pembayaran p) {
    final color = statusPembayaranColor(p.status);
    final lunas = p.status.toLowerCase() == 'lunas';
    return AppBody(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(p.metode == 'QRIS' ? Icons.qr_code_2 : (p.metode == 'Cash' ? Icons.payments_outlined : Icons.account_balance_outlined), color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(p.namaPelanggan ?? 'Pesanan #${p.idPesanan}', style: const TextStyle(fontWeight: FontWeight.w800))),
                StatusChip(label: p.status, color: color),
              ]),
              const SizedBox(height: 4),
              Text('#${p.idPesanan} · ${p.metode.isEmpty ? 'belum dipilih' : p.metode} · ${tanggal(p.tanggalBayar)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(rupiah(p.totalHarga ?? p.totalBayar), style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
          if (!lunas)
            Column(mainAxisSize: MainAxisSize.min, children: [
              if (p.bukti != null && p.bukti!.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => _lihatBukti(p),
                  child: CarImage(foto: p.bukti, height: 48, width: 64),
                ),
                TextButton(onPressed: () => _verifikasi(p), child: const Text('Verifikasi')),
              ] else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) => _ubah(p, v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'Lunas', child: Text('Tandai Lunas')),
                    PopupMenuItem(value: 'Gagal', child: Text('Tandai Gagal')),
                    PopupMenuItem(value: 'Kadaluarsa', child: Text('Kadaluarsa')),
                  ],
                ),
            ])
          else if (p.bukti != null && p.bukti!.isNotEmpty)
            GestureDetector(
              onTap: () => _lihatBukti(p),
              child: CarImage(foto: p.bukti, height: 48, width: 64),
            ),
        ]),
      ),
    );
  }
}
