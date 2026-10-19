import 'dart:async';

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class WaitingScreen extends StatefulWidget {
  final int idPesanan;
  const WaitingScreen({super.key, required this.idPesanan});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  Pesanan? _pesanan;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final res = await Api().get('booking.php');
      final list = (res['data'] as List).map((e) => Pesanan.fromJson(e)).toList();
      final found = list.firstWhere((p) => p.idPesanan == widget.idPesanan);
      if (mounted) setState(() { _pesanan = found; _error = null; _loading = false; });
    } on StateError {
      if (mounted) setState(() { _error = 'Pesanan tidak ditemukan'; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Status Pesanan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : _body(),
    );
  }

  Widget _body() {
    final p = _pesanan!;
    final diproses = p.statusPesanan == 'diproses' || p.statusPesanan == 'selesai';
    final dibatalkan = p.statusPesanan == 'batal' || p.statusPesanan == 'ditolak';
    final lunas = (p.statusPembayaran ?? '').toLowerCase() == 'lunas';
    final done = diproses || lunas;

    return AppBody(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: (dibatalkan ? AppColors.danger : done ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                dibatalkan ? Icons.cancel_outlined : done ? Icons.verified_outlined : Icons.hourglass_top,
                size: 46,
                color: dibatalkan ? AppColors.danger : done ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            dibatalkan ? 'Pesanan ${p.statusPesanan}' : done ? 'Pesanan Disetujui!' : 'Menunggu Verifikasi Admin',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            dibatalkan
                ? 'Pesanan ini tidak dapat dilanjutkan. Silakan buat pesanan baru.'
                : done
                    ? 'Pembayaranmu sudah dikonfirmasi admin. Selamat menikmati perjalanan!'
                    : 'Pembayaranmu sudah kami terima dan sedang diverifikasi oleh admin. Halaman ini akan otomatis diperbarui.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 24),
          _card(p),
          const SizedBox(height: 20),
          if (!done && !dibatalkan)
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Memeriksa status…', style: TextStyle(color: AppColors.muted)),
            ]),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Lihat Daftar Pesanan'),
          ),
        ],
      ),
    );
  }

  Widget _card(Pesanan p) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
        child: Column(
          children: [
            _row('No. Pesanan', '#${p.idPesanan}'),
            _row('Mobil', '${p.kategori ?? ''} ${p.tipe ?? ''}'.trim()),
            _row('Masa sewa', '${tanggal(p.tanggalSewa)}${p.tanggalSelesai != null ? ' - ${tanggal(p.tanggalSelesai!)}' : ''}'),
            _row('Lama sewa', '${p.lamaSewa} hari'),
            if (p.pakaiSupir) _row('Supir', 'Ya · ${rupiah(p.biayaSupir)}'),
            if (p.diskon > 0) _row('Diskon', '- ${rupiah(p.diskon)}'),
            _row('Metode bayar', p.metodePembayaran?.isNotEmpty == true ? p.metodePembayaran! : '-'),
            _row('Status bayar', p.statusPembayaran ?? 'Pending'),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
              Text(rupiah(p.totalHarga), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brand)),
            ]),
          ],
        ),
      );

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: const TextStyle(color: AppColors.muted)),
          Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
}
