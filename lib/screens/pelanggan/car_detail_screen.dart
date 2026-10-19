import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import 'booking_screen.dart';

class CarDetailScreen extends StatefulWidget {
  final int idMobil;
  const CarDetailScreen({super.key, required this.idMobil});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  Mobil? _mobil;
  List<Ulasan> _ulasan = [];
  double _rating = 0;
  int _jumlahUlasan = 0;
  bool _favorit = false;
  bool _favBusy = false;
  bool _loading = true;
  String? _error;
  final _pc = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api().get('mobil.php', query: {'id': '${widget.idMobil}'});
      final list = res['data'] as List;
      if (list.isEmpty) throw ApiException('Mobil tidak ditemukan');
      _mobil = Mobil.fromJson(list.first);
      _rating = _mobil!.rating;
      _jumlahUlasan = _mobil!.jumlahUlasan;
      await _loadUlasan();
      await _loadFavorit();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadUlasan() async {
    try {
      final res = await Api().get('ulasan.php', query: {'id_mobil': '${widget.idMobil}'});
      final ring = res['ringkasan'] as Map<String, dynamic>?;
      _ulasan = (res['data'] as List).map((e) => Ulasan.fromJson(e)).toList();
      if (ring != null) {
        _rating = (ring['rata'] as num?)?.toDouble() ?? _rating;
        _jumlahUlasan = (ring['jumlah'] as num?)?.toInt() ?? _jumlahUlasan;
      }
    } catch (_) {}
  }

  Future<void> _loadFavorit() async {
    try {
      final res = await Api().get('favorit.php');
      final list = res['data'] as List;
      _favorit = list.any((e) => Mobil.fromJson(e).idMobil == widget.idMobil);
    } catch (_) {}
  }

  Future<void> _toggleFavorit() async {
    setState(() => _favBusy = true);
    try {
      final res = await Api().post('favorit.php', {'id_mobil': widget.idMobil});
      if (mounted) {
        setState(() => _favorit = res['favorit'] == true);
        showSnack(context, '${res['favorit'] == true ? 'Ditambahkan ke' : 'Dihapus dari'} favorit');
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  void _pesan(Mobil m) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingScreen(mobil: m)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Mobil'),
        actions: [
          IconButton(
            tooltip: _favorit ? 'Hapus dari favorit' : 'Tambah ke favorit',
            onPressed: _favBusy ? null : _toggleFavorit,
            icon: Icon(_favorit ? Icons.favorite : Icons.favorite_border, color: _favorit ? AppColors.danger : null),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppError(message: _error!, onRetry: _load)
              : _body(_mobil!, wide),
      bottomNavigationBar: (_mobil == null || wide) ? null : _bottomBar(_mobil!),
    );
  }

  Widget _body(Mobil m, bool wide) {
    if (wide) {
      return AppBody(
        maxWidth: 1180,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _hero(m, height: 340),
                    const SizedBox(height: 22),
                    const SectionTitle('Spesifikasi'),
                    const SizedBox(height: 10),
                    _specGrid(m),
                    const SizedBox(height: 18),
                    _kondisiCard(m),
                    const SizedBox(height: 12),
                    _supirCard(m),
                    const SizedBox(height: 22),
                    _ulasanSection(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(width: 360, child: _hargaCard(m)),
            ],
          ),
        ),
      );
    }
    return AppBody(
      maxWidth: 1120,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          _hero(m, height: 220),
          const SizedBox(height: 18),
          const SectionTitle('Spesifikasi'),
          const SizedBox(height: 10),
          _specGrid(m),
          const SizedBox(height: 18),
          _kondisiCard(m),
          const SizedBox(height: 12),
          _supirCard(m),
          const SizedBox(height: 22),
          _ulasanSection(),
          const SizedBox(height: 18),
          _hargaCard(m, showButton: false),
        ],
      ),
    );
  }

  Widget _hero(Mobil m, {required double height}) {
    final fotos = m.semuaFoto;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          if (fotos.length <= 1)
            CarImage(foto: m.foto, height: height, width: double.infinity, radius: BorderRadius.circular(22))
          else
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pc,
                itemCount: fotos.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => CarImage(foto: fotos[i], height: height, width: double.infinity, radius: BorderRadius.circular(22)),
              ),
            ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 40, 18, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xB3000000)]),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${m.kategori} ${m.tipe}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                      const SizedBox(height: 4),
                      Text('${m.platNomer} · ${m.tahun} · ${m.warna}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(children: [
                        RatingStars(rating: _rating, count: _jumlahUlasan, size: 15, color: AppColors.accent),
                      ]),
                    ]),
                  ),
                  StatusChip(label: m.tersedia ? 'Tersedia' : 'Disewa', color: m.tersedia ? AppColors.success : AppColors.warning),
                ],
              ),
            ),
          ),
          if (fotos.length > 1)
            Positioned(
              bottom: 74, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < fotos.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ulasanSection() {
    return SectionCard(
      title: 'Ulasan Pelanggan',
      icon: Icons.star_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(_rating.toStringAsFixed(1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RatingStars(rating: _rating, size: 16),
              Text('$_jumlahUlasan ulasan', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ]),
          const Divider(height: 24),
          if (_ulasan.isEmpty)
            const Text('Belum ada ulasan untuk mobil ini.', style: TextStyle(color: AppColors.muted))
          else
            for (final u in _ulasan) _ulasanTile(u),
        ],
      ),
    );
  }

  Widget _ulasanTile(Ulasan u) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.brandLight,
              child: Text((u.namaPelanggan ?? '?').isNotEmpty ? u.namaPelanggan![0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.namaPelanggan ?? 'Pelanggan', style: const TextStyle(fontWeight: FontWeight.w700)),
                RatingStars(rating: u.rating.toDouble(), size: 13),
              ]),
            ),
            Text(tanggal(u.dibuatPada), style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ]),
          if (u.komentar != null && u.komentar!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(left: 42, top: 4), child: Text(u.komentar!)),
        ]),
      );

  Widget _specGrid(Mobil m) {
    final specs = <(IconData, String, String)>[
      (Icons.event_seat_outlined, 'Kapasitas', m.kapasitas != null ? '${m.kapasitas} kursi' : '-'),
      (Icons.settings_outlined, 'Transmisi', m.transmisi ?? '-'),
      (Icons.calendar_today_outlined, 'Tahun', m.tahun),
      (Icons.local_gas_station_outlined, 'Bahan bakar', 'Bensin'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: specs.map((s) {
        return Container(
          width: 200,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Icon(s.$1, color: AppColors.brand, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$2, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                Text(s.$3, style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _kondisiCard(Mobil m) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          const Icon(Icons.verified_outlined, color: AppColors.brand),
          const SizedBox(width: 10),
          const Text('Kondisi: ', style: TextStyle(color: AppColors.muted)),
          Expanded(child: Text(m.kondisi, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _supirCard(Mobil m) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.person_pin_circle_outlined, color: AppColors.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Opsi Supir', style: TextStyle(fontWeight: FontWeight.w800)),
              Text(supirLabel(m.opsiSupir), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ]),
          ),
        ]),
      );

  Widget _hargaCard(Mobil m, {bool showButton = true}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Harga Sewa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 12),
          _priceRow('Sewa per hari', rupiah(m.harga)),
          if (m.bisaDenganSupir) _priceRow('Supir per hari', rupiah(m.hargaSupir)),
          const Divider(height: 28, color: AppColors.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mulai dari', style: TextStyle(color: AppColors.muted)),
              Text('${rupiah(m.harga)} /hari', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brand)),
            ],
          ),
          if (showButton) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: m.tersedia ? () => _pesan(m) : null,
                icon: const Icon(Icons.event_available),
                label: Text(m.tersedia ? 'Pesan Sekarang' : 'Tidak Tersedia'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _bottomBar(Mobil m) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))),
      child: AppBody(
        maxWidth: 1120,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Mulai dari', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                Text('${rupiah(m.harga)} /hari', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.brand)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: m.tersedia ? () => _pesan(m) : null,
                icon: const Icon(Icons.event_available),
                label: Text(m.tersedia ? 'Pesan Sekarang' : 'Tidak Tersedia'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
