import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/uploader.dart';
import '../../widgets/common.dart';
import 'waiting_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int idPesanan;
  const PaymentScreen({super.key, required this.idPesanan});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Pesanan? _pesanan;
  bool _loading = true;
  String? _error;
  String _metode = 'Transfer';
  bool _saving = false;
  String? _bukti;
  Uint8List? _buktiBytes;
  bool _uploading = false;

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
      final list = (res['data'] as List).map((e) => Pesanan.fromJson(e)).toList();
      _pesanan = list.firstWhere((p) => p.idPesanan == widget.idPesanan);
      _metode = _pesanan!.metodePembayaran?.isNotEmpty == true ? _pesanan!.metodePembayaran! : 'Transfer';
    } on StateError {
      _error = 'Pesanan tidak ditemukan';
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickBukti() async {
    final res = await pickAndUploadImage(context, onBusy: (busy) {
      if (mounted) setState(() => _uploading = busy);
    });
    if (!mounted || res == null) return;
    setState(() {
      _bukti = res.filename;
      _buktiBytes = res.bytes;
    });
  }

  Future<void> _save() async {
    if (_metode != 'Cash' && (_bukti == null || _bukti!.isEmpty)) {
      showSnack(context, 'Unggah bukti pembayaran dulu, ya', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await Api().post('pembayaran.php', {
        'id_pesanan': widget.idPesanan,
        'metode_pembayaran': _metode,
        if (_bukti != null && _bukti!.isNotEmpty) 'bukti': _bukti,
      });
      if (!mounted) return;
      showSnack(context, 'Pembayaran dikonfirmasi');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => WaitingScreen(idPesanan: widget.idPesanan)));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _batalkan() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan pesanan?'),
        content: const Text('Pesanan yang dibatalkan tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, batalkan')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().put('booking.php', {'id_pesanan': widget.idPesanan, 'status_pesanan': 'batal'});
      if (!mounted) return;
      showSnack(context, 'Pesanan dibatalkan');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pembayaran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : _body(),
    );
  }

  Widget _body() {
    final p = _pesanan!;
    final lunas = (p.statusPembayaran ?? '').toLowerCase() == 'lunas';

    return AppBody(
      maxWidth: 900,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('Total Pembayaran', style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  StatusChip(label: p.statusPesanan, color: Colors.white),
                ]),
                const SizedBox(height: 8),
                Text(rupiah(p.totalHarga), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Pesanan #${p.idPesanan} · ${p.tipe ?? ''} (${p.platNomer ?? ''})', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _detailCard(p),
          const SizedBox(height: 20),
          if (p.diskon > 0)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.local_offer_outlined, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(child: Text('Promo ${p.kodePromo ?? ''} diterapkan · hemat ${rupiah(p.diskon)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))),
              ]),
            ),
          if (p.statusPesanan == 'batal' || p.statusPesanan == 'ditolak')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.cancel_outlined, color: AppColors.danger),
                const SizedBox(width: 10),
                Expanded(child: Text('Pesanan ${p.statusPesanan}. Silakan buat pesanan baru.', style: const TextStyle(color: AppColors.danger))),
              ]),
            )
          else if (lunas)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Row(children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 10),
                Expanded(child: Text('Pembayaran sudah Lunas. Terima kasih!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700))),
              ]),
            )
          else ...[
            const Text('Pilih Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            _methodTile('Transfer'),
            _methodTile('QRIS'),
            _methodTile('Cash'),
            const SizedBox(height: 8),
            if (_metode != 'Cash') _instruksi(p),
            const SizedBox(height: 8),
            if (_metode != 'Cash') _buktiWidget(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.payment),
              label: Text(_saving ? 'Memproses…' : 'Konfirmasi Pembayaran'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _batalkan,
              icon: const Icon(Icons.close),
              label: const Text('Batalkan Pesanan'),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buktiWidget() {
    final b = _buktiBytes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        if (b != null)
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(b, height: 64, width: 84, fit: BoxFit.cover))
        else if (_bukti != null && _bukti!.isNotEmpty)
          CarImage(foto: _bukti, height: 64, width: 84)
        else
          Container(
            height: 64, width: 84,
            decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.receipt_long_outlined, color: AppColors.brand),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(_bukti == null ? 'Belum diunggah · wajib untuk Transfer/QRIS' : 'Bukti terunggah',
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 6),
            Row(children: [
              OutlinedButton.icon(
                onPressed: _uploading ? null : _pickBukti,
                icon: _uploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.upload, size: 18),
                label: Text(_uploading ? 'Mengunggah…' : (_bukti == null ? 'Unggah' : 'Ganti')),
              ),
              if (_bukti != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _uploading ? null : () => setState(() { _bukti = null; _buktiBytes = null; }),
                  child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _methodTile(String m) {
    final selected = _metode == m;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? AppColors.brand : AppColors.line, width: selected ? 1.6 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _metode = m),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.brand : AppColors.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_metodeLabel(m), style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(_metodeSub(m), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailCard(Pesanan p) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
        child: Column(
          children: [
            _row('Mobil', '${p.kategori ?? ''} ${p.tipe ?? ''}'),
            _row('Tanggal mulai', tanggal(p.tanggalSewa)),
            if (p.tanggalSelesai != null && p.tanggalSelesai!.isNotEmpty) _row('Tanggal selesai', tanggal(p.tanggalSelesai!)),
            _row('Lama sewa', '${p.lamaSewa} hari'),
            if (p.waktuPengambilan != null && p.waktuPengambilan!.isNotEmpty)
              _row(p.pakaiSupir ? 'Waktu diantarkan' : 'Waktu ambil', p.waktuPengambilan!.split(' ').last.substring(0, 5)),
            _row('Supir', p.pakaiSupir ? 'Ya · ${rupiah(p.biayaSupir)}' : 'Tidak (lepas kunci)'),
            if (p.diskon > 0) _row('Diskon', '- ${rupiah(p.diskon)}'),
            const Divider(height: 24),
            _row('Penyewa', p.namaPenyewa ?? p.namaPelanggan ?? '-'),
            _row('Email', p.emailPenyewa ?? '-'),
            _row('No. Telpon/WA', p.telponPenyewa ?? p.noTelpon ?? '-'),
            _row('NIK', p.ktpPenyewa ?? '-'),
            _row('Pekerjaan', p.pekerjaanPenyewa ?? '-'),
            _row('Alamat', p.alamatPenyewa ?? '-'),
            _row('Status', p.statusPesanan),
            _row('Pembayaran', p.statusPembayaran ?? 'Belum Bayar'),
          ],
        ),
      );

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(width: 12),
            Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      );

  Widget _instruksi(Pesanan p) {
    final va = (p.nomorVa?.isNotEmpty == true) ? p.nomorVa! : '8808${p.idPesanan.toString().padLeft(8, '0')}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(_metode == 'QRIS' ? Icons.qr_code_2 : Icons.account_balance, color: AppColors.brand),
            const SizedBox(width: 10),
            Text(_metode == 'QRIS' ? 'Kode QRIS' : 'Virtual Account', style: const TextStyle(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 12),
          SelectableText(_metode == 'QRIS' ? 'RM-${p.idPesanan}' : va,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('Selesaikan pembayaran lalu tekan "Konfirmasi Pembayaran". Pembayaran akan diverifikasi admin.',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  String _metodeLabel(String m) => switch (m) {
        'Transfer' => 'Transfer Bank / Virtual Account',
        'QRIS' => 'QRIS (semua e-wallet)',
        _ => 'Bayar Tunai (Cash)',
      };

  String _metodeSub(String m) => switch (m) {
        'Transfer' => 'BCA, Mandiri, BNI, BRI',
        'QRIS' => 'Scan pakai aplikasi apapun',
        _ => 'Bayar langsung di kantor',
      };
}
