import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import 'car_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenAbout;
  const HomeScreen({super.key, this.onOpenAbout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  List<Mobil> _mobil = [];
  List<Kategori> _kategori = [];
  List<Promo> _promoList = [];
  int? _filterKategori;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final q = <String, String>{};
      if (_search.text.trim().isNotEmpty) q['q'] = _search.text.trim();
      if (_filterKategori != null) q['kategori'] = '$_filterKategori';
      final results = await Future.wait([
        Api().get('mobil.php', query: q),
        Api().get('kategori.php'),
        Api().get('promo.php'),
      ]);
      _mobil = (results[0]['data'] as List).map((e) => Mobil.fromJson(e)).toList();
      _kategori = (results[1]['data'] as List).map((e) => Kategori.fromJson(e)).toList();
      _promoList = (results[2]['data'] as List).map((e) => Promo.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackdrop(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            AppBody(
              maxWidth: 1320,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _hero(),
                const SizedBox(height: 20),
                const SectionTitle('Kategori Pilihan'),
                const SizedBox(height: 4),
                _kategoriRow(),
                if (_promoList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionTitle('Promo Spesial'),
                  const SizedBox(height: 8),
                  _promoRow(),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mobil Tersedia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    Text('${_mobil.length} unit', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                _content(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _promoRow() {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _promoList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final p = _promoList[i];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.local_offer, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(p.persen ? '${p.nilai.toInt()}% OFF' : 'HEMAT ${rupiah(p.nilai)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 8),
                Text(p.judul, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(p.deskripsi ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text('Kode: ${p.kode}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Mau ke mana hari ini?', style: TextStyle(color: AppColors.ink, fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 6),
                    Text('Pesan mobil lepas kunci atau dengan supir, kapan pun.', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              if (MediaQuery.of(context).size.width >= 600)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Image.asset('assets/citrarentcar.png'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Cari tipe mobil, e.g. Avanza',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.tune), onPressed: _load),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kategoriRow() {
    if (_kategori.isEmpty) {
      return SizedBox(height: 44, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => const Skeleton(height: 44, width: 110),
      ));
    }
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Semua', _filterKategori == null, () {
            setState(() => _filterKategori = null);
            _load();
          }),
          for (final k in _kategori)
            _chip('${k.nama} (${k.jumlahMobil})', _filterKategori == k.idKategori, () {
              setState(() => _filterKategori = k.idKategori);
              _load();
            }),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.brand : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: active ? AppColors.brand : AppColors.line),
            ),
            child: Center(
              child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ),
      );

  Widget _content() {
    if (_loading) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: _cols(context),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.74,
        children: List.generate(4, (_) => const _CardSkeleton()),
      );
    }
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    if (_mobil.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: AppEmpty(message: 'Belum ada mobil yang cocok dengan pencarian.'));
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _cols(context),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 0.74,
      children: _mobil.map((m) => _CarCard(mobil: m)).toList(),
    );
  }

  int _cols(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1200) return 4;
    if (w >= 900) return 3;
    if (w >= 560) return 2;
    return 1;
  }
}

class _CarCard extends StatelessWidget {
  final Mobil mobil;
  const _CarCard({required this.mobil});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarDetailScreen(idMobil: mobil.idMobil))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CarImage(foto: mobil.foto, height: 150, width: double.infinity, radius: const BorderRadius.vertical(top: Radius.circular(18))),
                Positioned(
                  top: 10, right: 10,
                  child: StatusChip(
                    label: mobil.tersedia ? 'Tersedia' : 'Disewa',
                    color: mobil.tersedia ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${mobil.kategori} ${mobil.tipe}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(mobil.platNomer, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    const Spacer(),
                    if (mobil.jumlahUlasan > 0) RatingStars(rating: mobil.rating, size: 12),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.event_seat_outlined, size: 15, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text('${mobil.kapasitas ?? '-'}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(width: 10),
                      const Icon(Icons.settings_outlined, size: 15, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(mobil.transmisi ?? '-', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(rupiah(mobil.harga), style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800, fontSize: 16)),
                      const Text(' /hari', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      const Spacer(),
                      if (mobil.hargaSupir > 0 && mobil.bisaDenganSupir)
                        const Icon(Icons.person_pin_circle_outlined, size: 18, color: AppColors.accent),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Skeleton(height: 120, width: double.infinity, radius: _r12),
            SizedBox(height: 14),
            Skeleton(height: 14, width: 120),
            SizedBox(height: 8),
            Skeleton(height: 12, width: 80),
            SizedBox(height: 14),
            Skeleton(height: 16, width: 100),
          ],
        ),
      );
}

const _r12 = BorderRadius.all(Radius.circular(12));
