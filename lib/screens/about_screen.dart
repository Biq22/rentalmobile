import 'package:flutter/material.dart';

import '../config.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../widgets/common.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  Pengaturan? _p;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Api().get('pengaturan.php');
      _p = Pengaturan.fromJson(res['data'] as Map<String, dynamic>);
    } catch (_) {
      _p = Pengaturan(const {
        'nama_perusahaan': 'Rental Mobil',
        'alamat': 'Jl. Raya Rental No. 123, Surabaya',
        'telepon': '0812-3456-7890',
        'jam_operasional': 'Senin - Sabtu, 08.00 - 20.00 WIB',
        'visi': 'Menjadi penyedia jasa sewa mobil terbaik dan tepercaya.',
        'tentang': 'Layanan sewa mobil yang mudah, cepat, dan terpercaya. Tersedia pilihan lepas kunci maupun dengan supir untuk kebutuhan perjalananmu.',
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Kami')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : AppBody(
              maxWidth: 820,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset('assets/logorentalmobile.jpg'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(p?.namaPerusahaan ?? 'Rental Mobil', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    p?.tentang ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  if ((p?.alamat ?? '').isNotEmpty) _ig(Icons.location_on_outlined, 'Alamat', p!.alamat),
                  if ((p?.telepon ?? '').isNotEmpty) _ig(Icons.call_outlined, 'Telepon', p!.telepon),
                  if ((p?.email ?? '').isNotEmpty) _ig(Icons.email_outlined, 'Email', p!.email),
                  if ((p?.jamOperasional ?? '').isNotEmpty) _ig(Icons.schedule_outlined, 'Jam Operasional', p!.jamOperasional),
                  if ((p?.visi ?? '').isNotEmpty) _ig(Icons.verified_outlined, 'Visi', p!.visi),
                  const SizedBox(height: 24),
                  const Text('© 2026 Rental Mobil. Semua hak dilindungi.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _ig(IconData icon, String label, String value) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Icon(icon, color: AppColors.brand),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      );
}
