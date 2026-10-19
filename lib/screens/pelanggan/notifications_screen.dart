import 'package:flutter/material.dart';

import '../../config.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
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
      _items = (res['data'] as List).cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  ? ListView(children: const [SizedBox(height: 120), AppEmpty(title: 'Tidak ada notifikasi', message: 'Info perubahan status pesananmu akan muncul di sini.', icon: Icons.notifications_none)])
                  : AppBody(
                      maxWidth: 1080,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _tile(_items[i]),
                      ),
                    ),
    );
  }

  Widget _tile(Map<String, dynamic> n) {
    final status = '${n['status_pesanan'] ?? ''}';
    final icon = switch (status) {
      'diproses' => Icons.check_circle_outline,
      'selesai' => Icons.task_alt,
      'batal' || 'ditolak' => Icons.cancel_outlined,
      _ => Icons.notifications_none,
    };
    final color = switch (status) {
      'diproses' => AppColors.info,
      'selesai' => AppColors.success,
      'batal' || 'ditolak' => AppColors.danger,
      _ => AppColors.brand,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${n['pesan'] ?? 'Notifikasi'}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (n['tipe'] != null)
              Text('${n['kategori'] ?? ''} ${n['tipe'] ?? ''} · ${n['plat_nomer'] ?? ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
