import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../services/download.dart';
import '../../widgets/common.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  Map<String, dynamic>? _data;
  List<LaporanRow> _riwayat = [];
  List<DailySales> _harian = [];
  bool _loading = true;
  bool _exporting = false;
  String? _error;
  String _status = 'semua';
  bool _generating = false;
  DateTime? _lastUpdated;
  Timer? _poll;

  static const _pollInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _load().whenComplete(() {
      if (!mounted) return;
      _poll = Timer.periodic(_pollInterval, (_) => _load(silent: true));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final res = await Api().get('laporan.php');
      final d = res['data'] as Map<String, dynamic>;
      final riwayat = ((d['riwayat_laporan'] as List?) ?? []).map((e) => LaporanRow.fromJson(e)).toList();
      final harian = ((d['harian'] as List?) ?? []).map((e) => DailySales.fromJson(e)).toList();
      if (!mounted) return;
      setState(() {
        _data = d;
        _riwayat = riwayat;
        _harian = harian;
        _lastUpdated = DateTime.now();
        _error = null;
      });
    } on ApiException catch (e) {
      if (!silent && mounted) setState(() => _error = e.message);
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      await Api().post('laporan.php', {'status': _status});
      if (mounted) showSnack(context, 'Laporan dibuat');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _hapus(LaporanRow r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus laporan?'),
        content: Text('Laporan #${r.idLaporan} akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api().delete('laporan.php', query: {'id': '${r.idLaporan}'});
      if (mounted) showSnack(context, 'Laporan dihapus');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final res = await Api().get('booking.php');
      final rows = ((res['data'] as List?) ?? []).map((e) => Pesanan.fromJson(e)).toList();
      final sb = StringBuffer();
      sb.writeln([
        'ID', 'Tgl Pesanan', 'Tgl Sewa', 'Lama (hari)', 'Pelanggan', 'No Telp',
        'Mobil', 'Plat', 'Pakai Supir', 'Biaya Supir', 'Total', 'Status Pesanan',
        'Metode', 'Status Bayar',
      ].map(_csv).join(','));
      for (final p in rows) {
        sb.writeln([
          '${p.idPesanan}',
          p.tanggalPesanan ?? '',
          p.tanggalSewa,
          '${p.lamaSewa}',
          p.namaPelanggan ?? '',
          p.noTelpon ?? '',
          '${p.kategori ?? ''} ${p.tipe ?? ''}'.trim(),
          p.platNomer ?? '',
          p.pakaiSupir ? 'Ya' : 'Tidak',
          '${p.biayaSupir.toInt()}',
          '${p.totalHarga.toInt()}',
          statusPesananLabel(p.statusPesanan),
          p.metodePembayaran ?? '',
          p.statusPembayaran ?? 'Belum Bayar',
        ].map(_csv).join(','));
      }
      final now = DateTime.now();
      final stamp = '${now.year}${_p2(now.month)}${_p2(now.day)}-${_p2(now.hour)}${_p2(now.minute)}';
      downloadCsv('laporan-penjualan-$stamp.csv', sb.toString());
      if (mounted) showSnack(context, 'Export ${rows.length} pesanan berhasil');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _p2(int v) => v.toString().padLeft(2, '0');
  String _csv(String v) => '"${v.replaceAll('"', '""')}"';

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    final d = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    const Text('Laporan & Analitik', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      _LiveBadge(lastUpdated: _lastUpdated),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _exporting ? null : _exportCsv,
                        icon: _exporting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('Export CSV'),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 16),
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
                      StatCard(label: 'Total Pendapatan', value: rupiahShort(d['total_pendapatan']), icon: Icons.payments, color: AppColors.success),
                      StatCard(label: 'Rata-rata / Order', value: rupiahShort(d['rata_rata_order']), icon: Icons.trending_up, color: AppColors.info),
                      StatCard(label: 'Total Pelanggan', value: '${d['jumlah_pelanggan']}', icon: Icons.people, color: AppColors.muted),
                    ],
                  );
                }),
                const SizedBox(height: 16),
                _SalesChartCard(data: _harian),
                const SizedBox(height: 16),
                _GenerateCard(
                  status: _status,
                  generating: _generating,
                  onStatus: (v) => setState(() => _status = v),
                  onGenerate: _generate,
                ),
                const SizedBox(height: 16),
                _ProductSalesCard(data: d),
                const SizedBox(height: 24),
                const Text('Riwayat Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (_riwayat.isEmpty)
                  const AppEmpty(message: 'Belum ada laporan tersimpan.', icon: Icons.folder_open)
                else
                  Card(
                    child: Column(
                      children: [
                        for (final r in _riwayat)
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.brand.withValues(alpha: 0.12),
                              child: Text('${r.idLaporan}', style: const TextStyle(fontSize: 12, color: AppColors.brand, fontWeight: FontWeight.w700)),
                            ),
                            title: Text('${r.keterangan} • ${r.totalOrder} order'),
                            subtitle: Text('${tanggal(r.tanggalLaporan)} • ${rupiah(r.totalPendapatan)} • rata ${rupiah(r.rataRataOrder)}'),
                            trailing: IconButton(
                              onPressed: () => _hapus(r),
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateCard extends StatelessWidget {
  final String status;
  final bool generating;
  final ValueChanged<String> onStatus;
  final VoidCallback onGenerate;
  const _GenerateCard({
    required this.status,
    required this.generating,
    required this.onStatus,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Buat Laporan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            DropdownButton<String>(
              value: status,
              onChanged: (v) { if (v != null) onStatus(v); },
              items: const [
                DropdownMenuItem(value: 'semua', child: Text('Semua Status')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'diproses', child: Text('Diproses')),
                DropdownMenuItem(value: 'selesai', child: Text('Selesai')),
                DropdownMenuItem(value: 'batal', child: Text('Batal')),
                DropdownMenuItem(value: 'ditolak', child: Text('Ditolak')),
              ],
            ),
            FilledButton.icon(
              onPressed: generating ? null : onGenerate,
              icon: generating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.receipt_long, size: 18),
              label: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final DateTime? lastUpdated;
  const _LiveBadge({this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final t = lastUpdated == null ? '--:--:--' : DateFormat('HH:mm:ss').format(lastUpdated!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text('LIVE  •  $t', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
    );
  }
}

class _SalesChart extends StatelessWidget {
  final List<DailySales> data;
  final bool showLeftAxis;
  const _SalesChart(this.data, {this.showLeftAxis = false});

  @override
  Widget build(BuildContext context) {
    final maxJumlah = data.fold<int>(0, (m, e) => e.jumlah > m ? e.jumlah : m);
    final maxPendapatan = data.fold<double>(0, (m, e) => e.pendapatan > m ? e.pendapatan : m);
    final maxYJumlah = (maxJumlah <= 4 ? 4 : (maxJumlah * 1.25)).toDouble();
    final maxYPendapatan = maxPendapatan <= 0 ? 100000.0 : maxPendapatan * 1.25;
    final n = data.length;

    final bottomTitles = AxisTitles(
      sideTitles: SideTitles(
        showTitles: showLeftAxis,
        reservedSize: 22,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final i = value.round();
          if (i < 0 || i >= n) return const SizedBox.shrink();
          if (n > 8 && i.isOdd) return const SizedBox.shrink();
          return SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(data[i].label, style: const TextStyle(fontSize: 9, color: AppColors.muted)),
          );
        },
      ),
    );

    final leftInterval = (maxYJumlah / 4).clamp(1, double.infinity).toDouble();
    final rightInterval = maxYPendapatan / 4 <= 0 ? 1.0 : maxYPendapatan / 4;

    final titles = FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 6)),
      bottomTitles: bottomTitles,
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: showLeftAxis,
          reservedSize: 34,
          interval: leftInterval,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text('${value.toInt()}', style: const TextStyle(fontSize: 9, color: AppColors.muted)),
          ),
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: !showLeftAxis,
          reservedSize: 40,
          interval: rightInterval,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            axisSide: meta.axisSide,
            child: Text(rupiahShort(value), style: const TextStyle(fontSize: 9, color: AppColors.muted)),
          ),
        ),
      ),
    );

    final grid = FlGridData(
      show: showLeftAxis,
      drawVerticalLine: false,
      horizontalInterval: leftInterval,
      getDrawingHorizontalLine: (v) => FlLine(color: AppColors.line, strokeWidth: 1),
    );

    if (showLeftAxis) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxYJumlah,
          minY: 0,
          barGroups: [
            for (var i = 0; i < n; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data[i].jumlah.toDouble(),
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.brand.withValues(alpha: 0.75),
                  backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxYJumlah, color: AppColors.brand.withValues(alpha: 0.06)),
                ),
              ]),
          ],
          titlesData: titles,
          gridData: grid,
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem('${data[group.x].label}\n${data[group.x].jumlah} order', const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: -0.5,
        maxX: n - 0.5,
        minY: 0,
        maxY: maxYPendapatan,
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < n; i++) FlSpot(i.toDouble(), data[i].pendapatan)],
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.success,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.success.withValues(alpha: 0.25), AppColors.success.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
        titlesData: titles,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(rupiah(s.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _SalesChartCard extends StatefulWidget {
  final List<DailySales> data;
  const _SalesChartCard({required this.data});

  @override
  State<_SalesChartCard> createState() => _SalesChartCardState();
}

class _SalesChartCardState extends State<_SalesChartCard> {
  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final hasData = data.isNotEmpty && data.fold<int>(0, (m, e) => m + e.jumlah) > 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.insights, size: 18, color: AppColors.brand),
              SizedBox(width: 8),
              Text('Grafik Penjualan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
            const SizedBox(height: 4),
            const Text('Batang = jumlah order  •  Garis = pendapatan harian (14 hari terakhir)',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            if (!hasData)
              const SizedBox(height: 220, child: Center(child: Text('Belum ada data penjualan', style: TextStyle(color: AppColors.muted))))
            else
              SizedBox(
                height: 240,
                child: Stack(children: [
                  Positioned.fill(child: _SalesChart(data, showLeftAxis: true)),
                  Positioned.fill(child: _SalesChart(data, showLeftAxis: false)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductSalesCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProductSalesCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produk Terlaris', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            if ((data['mobil_terlaris'] as List?) == null || (data['mobil_terlaris'] as List).isEmpty)
              const Text('Belum ada data', style: TextStyle(color: AppColors.muted))
            else
              ...(data['mobil_terlaris'] as List).map((e) {
                final it = e as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.directions_car, color: AppColors.brand),
                  title: Text('${it['kategori'] ?? ''} ${it['tipe'] ?? ''}'.trim()),
                  trailing: Text('${it['jml']} pemesanan', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                );
              }),
          ],
        ),
      ),
    );
  }
}
