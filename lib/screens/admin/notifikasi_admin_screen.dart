import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class AdminNotifikasiScreen extends StatefulWidget {
  const AdminNotifikasiScreen({super.key});

  @override
  State<AdminNotifikasiScreen> createState() => _AdminNotifikasiScreenState();
}

class _AdminNotifikasiScreenState extends State<AdminNotifikasiScreen> {
  List<NotifikasiRow> _items = [];
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
      final res = await Api().get('notifikasi.php');
      _items = (res['data'] as List).map((e) => NotifikasiRow.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bacaSemua() async {
    try {
      await Api().post('notifikasi.php', {'semua': true});
      if (mounted) showSnack(context, 'Semua notifikasi ditandai dibaca');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _baca(NotifikasiRow n) async {
    try {
      await Api().post('notifikasi.php', {'id_pesanan': n.idPesanan});
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    if (_items.isEmpty) return const AppEmpty(title: 'Tidak ada notifikasi', message: 'Pesanan baru yang masuk akan tampil di sini.', icon: Icons.notifications_none);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Text('${_items.length} pesanan baru', style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(onPressed: _bacaSemua, icon: const Icon(Icons.done_all), label: const Text('Tandai semua')),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (_, i) => _card(_items[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(NotifikasiRow n) => AppBody(
        maxWidth: 820,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.receipt_long_outlined, color: AppColors.warning),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.pesan, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${n.kategori ?? ''} ${n.tipe ?? ''} · ${n.platNomer ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                Text('${tanggal(n.tanggalSewa)} · ${n.lamaSewa ?? '-'} hari · ${rupiah(n.totalHarga)}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: () => _baca(n), child: const Text('Tandai')),
          ]),
        ),
      );
}
