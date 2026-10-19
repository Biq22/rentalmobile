import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../services/api.dart';
import '../../services/print.dart';
import '../../widgets/common.dart';

class InvoiceScreen extends StatefulWidget {
  final int idPesanan;
  const InvoiceScreen({super.key, required this.idPesanan});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic> _set = {};
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
      final res = await Api().get('invoice.php', query: {'id': '${widget.idPesanan}'});
      _data = res['data'] as Map<String, dynamic>;
      _set = (res['pengaturan'] as Map?)?.cast<String, dynamic>() ?? {};
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _d(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
  int _i(dynamic v) => v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

  void _cetak() {
    try {
      printPage();
    } catch (_) {
      showSnack(context, 'Cetak hanya tersedia di web', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(onPressed: _cetak, icon: const Icon(Icons.print_outlined), tooltip: 'Cetak'),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : _body(),
    );
  }

  Widget _body() {
    final d = _data!;
    final harga = _d(d['harga_sewa_per_hari']);
    final lama = _i(d['lama_sewa']);
    final subtotal = harga * lama;
    final biayaSupir = _d(d['biaya_supir']);
    final diskon = _d(d['diskon']);
    final total = _d(d['total_harga']);
    final denda = _d(d['denda']);
    final grand = total + denda;
    final statusBayar = '${d['status_pembayaran'] ?? 'Belum Bayar'}';

    return AppBody(
      maxWidth: 720,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${_set['nama_perusahaan'] ?? 'Rental Mobil'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brand)),
                        const SizedBox(height: 4),
                        Text('${_set['alamat'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        Text('${_set['telepon'] ?? ''} · ${_set['email'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('INVOICE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                      Text('INV-${_i(d['id_pesanan']).toString().padLeft(5, '0')}', style: const TextStyle(color: AppColors.muted)),
                      Text(tanggal(d['tanggal_pesanan']), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ]),
                  ],
                ),
                const Divider(height: 32),
                const Text('Ditagihkan kepada', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text('${d['nama_penyewa'] ?? d['nama_pelanggan'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${d['telpon_penyewa'] ?? d['no_telpon'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 20),
                _sectionTable(d, harga, lama, subtotal, biayaSupir, diskon, denda, total),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Text('TOTAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    const Spacer(),
                    Text(rupiah(grand), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  const Text('Status Pembayaran: ', style: TextStyle(color: AppColors.muted)),
                  StatusChip(label: statusBayar, color: statusPembayaranColor(statusBayar)),
                  const Spacer(),
                  Text('Metode: ${d['metode_pembayaran'] ?? '-'}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ]),
                if ((_set['rekening'] as String?)?.isNotEmpty == true) ...[
                  const Divider(height: 32),
                  const Text('Pembayaran ditransfer ke:', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${_set['rekening']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 24),
                const Center(child: Text('Terima kasih telah menggunakan layanan kami.', style: TextStyle(color: AppColors.muted, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(onPressed: _cetak, icon: const Icon(Icons.print_outlined), label: const Text('Cetak / Simpan PDF')),
          ),
        ],
      ),
    );
  }

  Widget _sectionTable(Map<String, dynamic> d, double harga, int lama, double subtotal, double biayaSupir, double diskon, double denda, double total) {
    Widget row(String label, String value, {bool bold = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(child: Text(label, style: TextStyle(color: bold ? null : AppColors.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.normal))),
            Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w700, color: color)),
          ]),
        );

    return Column(
      children: [
        row('Sewa ${d['kategori'] ?? ''} ${d['tipe'] ?? ''} (${d['plat_nomer'] ?? ''})', '${rupiah(harga)} × $lama hari'),
        row('Subtotal sewa', rupiah(subtotal)),
        if (biayaSupir > 0) row('Biaya supir', rupiah(biayaSupir)),
        if ((d['nama_supir'] ?? '').toString().isNotEmpty) row('Supir', '${d['nama_supir']}'),
        if (diskon > 0) row('Diskon promo ${d['kode_promo'] ?? ''}', '- ${rupiah(diskon)}', color: AppColors.success),
        const Divider(height: 20),
        row('Total sewa', rupiah(total), bold: true),
        if (denda > 0) row('Denda keterlambatan', rupiah(denda), color: AppColors.danger),
      ],
    );
  }
}
