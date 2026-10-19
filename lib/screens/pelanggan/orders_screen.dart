import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import 'invoice_screen.dart';
import 'payment_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Pesanan> _items = [];
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
      final res = await Api().get('booking.php');
      _items = (res['data'] as List).map((e) => Pesanan.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _invoice(Pesanan p) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceScreen(idPesanan: p.idPesanan)));
  }

  Future<void> _ulasan(Pesanan p) async {
    int rating = 5;
    final komentar = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Ulas ${p.kategori ?? ''} ${p.tipe ?? ''}'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              RatingInput(value: rating, onChanged: (v) => setD(() => rating = v)),
              const SizedBox(height: 12),
              TextField(controller: komentar, maxLines: 3, decoration: const InputDecoration(labelText: 'Komentar (opsional)', border: OutlineInputBorder())),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await Api().post('ulasan.php', {'id_pesanan': p.idPesanan, 'rating': rating, 'komentar': komentar.text.trim()});
      if (mounted) showSnack(context, 'Terima kasih atas ulasanmu!');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? ListView(children: const [SizedBox(height: 120), AppEmpty(title: 'Belum ada pesanan', message: 'Yuk pesan mobil pertamamu dari Beranda.', icon: Icons.receipt_long_outlined)])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _card(_items[i]),
                    ),
    );
  }

  Widget _card(Pesanan p) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentScreen(idPesanan: p.idPesanan)));
        _load();
      },
      child: AppBody(
        maxWidth: 1080,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
          child: Row(
            children: [
              CarImage(foto: p.foto, height: 76, width: 100),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text('${p.kategori ?? ''} ${p.tipe ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800))),
                      StatusChip(label: p.statusPesanan, color: statusPembayaranColor(p.statusPesanan)),
                    ]),
                    const SizedBox(height: 4),
                    Text('${p.platNomer ?? ''} · ${tanggal(p.tanggalSewa)} · ${p.lamaSewa} hari', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(rupiah(p.totalHarga), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand)),
                      if (p.pakaiSupir) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.person_pin_circle, size: 15, color: AppColors.accent),
                        const Text('Supir', style: TextStyle(fontSize: 11, color: AppColors.accent)),
                      ],
                      const Spacer(),
                      Text('Pembayaran: ${p.statusPembayaran ?? '-'}', style: TextStyle(fontSize: 11, color: statusPembayaranColor(p.statusPembayaran))),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      OutlinedButton.icon(
                        onPressed: () => _invoice(p),
                        icon: const Icon(Icons.receipt_outlined, size: 16),
                        label: const Text('Invoice'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
                      ),
                      const SizedBox(width: 8),
                      if (p.statusPesanan == 'selesai')
                        FilledButton.icon(
                          onPressed: () => _ulasan(p),
                          icon: const Icon(Icons.star_outline, size: 16),
                          label: const Text('Beri Ulasan'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.accent, minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 12)),
                        ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
