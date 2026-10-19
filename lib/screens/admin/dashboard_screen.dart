import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
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
      final res = await Api().get('laporan.php');
      _data = res['data'] as Map<String, dynamic>;
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
              : _body(_data!),
    );
  }

  Widget _body(Map<String, dynamic> d) {
    final perStatus = (d['per_status'] as Map<String, dynamic>?) ?? {};
    final terlaris = (d['mobil_terlaris'] as List?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ringkasan Bisnis', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Pantau performa rental secara sekilas.', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    StatCard(label: 'Total Pesanan', value: '${d['total_pesanan']}', icon: Icons.receipt_long, color: AppColors.brand),
                    StatCard(label: 'Pendapatan Lunas', value: rupiahShort(d['total_pendapatan']), icon: Icons.payments, color: AppColors.success),
                    StatCard(label: 'Pesanan Aktif', value: '${d['pesanan_aktif']}', icon: Icons.pending_actions, color: AppColors.warning),
                    StatCard(label: 'Rata-rata / Order', value: rupiahShort(d['rata_rata_order']), icon: Icons.trending_up, color: AppColors.info),
                    StatCard(label: 'Jumlah Mobil', value: '${d['jumlah_mobil']}', icon: Icons.directions_car, color: AppColors.brandDark),
                    StatCard(label: 'Jumlah Pelanggan', value: '${d['jumlah_pelanggan']}', icon: Icons.people, color: AppColors.accent),
                  ],
                );
              }),
              const SizedBox(height: 20),
              const SectionTitle('Status Pesanan'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
                child: Column(children: [
                  for (final s in ['pending', 'diproses', 'selesai', 'batal', 'ditolak'])
                    _statusBar(s, (perStatus[s]?['total_order'] ?? 0) as int, (perStatus[s]?['total_pendapatan'] ?? 0)),
                ]),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Mobil Terlaris'),
              const SizedBox(height: 8),
              if (terlaris.isEmpty)
                const AppEmpty(message: 'Belum ada data pemesanan.')
              else
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
                  child: Column(
                    children: [
                      for (var i = 0; i < terlaris.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _terlaris(terlaris[i], i + 1),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBar(String status, int count, dynamic pendapatan) {
    final color = switch (status) {
      'diproses' => AppColors.info,
      'selesai' => AppColors.success,
      'batal' || 'ditolak' => AppColors.danger,
      _ => AppColors.warning,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(width: 84, child: StatusChip(label: status, color: color)),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (count / 20).clamp(0.04, 1.0).toDouble(),
              minHeight: 10,
              backgroundColor: AppColors.surface,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 40, child: Text('$count', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(rupiahShort(pendapatan as num), textAlign: TextAlign.end, style: const TextStyle(color: AppColors.muted, fontSize: 12))),
      ]),
    );
  }

  Widget _terlaris(dynamic t, int rank) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text('$rank', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800))),
        ),
        const SizedBox(width: 12),
        CarImage(foto: t['foto'] as String?, height: 46, width: 62),
        const SizedBox(width: 12),
        Expanded(child: Text('${t['kategori']} ${t['tipe']}', style: const TextStyle(fontWeight: FontWeight.w700))),
        Text('${t['jml']}x', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
