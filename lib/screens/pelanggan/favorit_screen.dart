import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import 'car_detail_screen.dart';

class FavoritScreen extends StatefulWidget {
  const FavoritScreen({super.key});

  @override
  State<FavoritScreen> createState() => _FavoritScreenState();
}

class _FavoritScreenState extends State<FavoritScreen> {
  List<Mobil> _items = [];
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
      final res = await Api().get('favorit.php');
      _items = (res['data'] as List).map((e) => Mobil.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hapusFavorit(Mobil m) async {
    try {
      await Api().post('favorit.php', {'id_mobil': m.idMobil});
      if (mounted) showSnack(context, 'Dihapus dari favorit');
      _load();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return AppError(message: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return ListView(children: const [SizedBox(height: 120), AppEmpty(title: 'Belum ada favorit', message: 'Tekan ikon hati di detail mobil untuk menyimpannya.', icon: Icons.favorite_border)]);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(Mobil m) => AppBody(
        maxWidth: 900,
        child: GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CarDetailScreen(idMobil: m.idMobil)));
            _load();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
            child: Row(children: [
              CarImage(foto: m.foto, height: 76, width: 100),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${m.kategori} ${m.tipe}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(m.platNomer, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 6),
                  if (m.jumlahUlasan > 0) RatingStars(rating: m.rating, count: m.jumlahUlasan),
                  const SizedBox(height: 4),
                  Text('${rupiah(m.harga)} /hari', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800)),
                ]),
              ),
              IconButton(onPressed: () => _hapusFavorit(m), icon: const Icon(Icons.favorite, color: AppColors.danger)),
            ]),
          ),
        ),
      );
}
