import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../about_screen.dart';
import 'dashboard_screen.dart';
import 'mobil_screen.dart';
import 'kategori_screen.dart';
import 'supir_screen.dart';
import 'pesanan_screen.dart';
import 'pembayaran_screen.dart';
import 'pelanggan_screen.dart';
import 'pegawai_screen.dart';
import 'promo_screen.dart';
import 'laporan_screen.dart';
import 'pengaturan_screen.dart';
import 'notifikasi_admin_screen.dart';
import 'admin_profile_screen.dart';

class _Item {
  final String label;
  final IconData icon;
  final Widget page;
  final bool adminOnly;
  const _Item(this.label, this.icon, this.page, {this.adminOnly = false});
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final items = <_Item>[
      const _Item('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
      const _Item('Mobil', Icons.directions_car_outlined, MobilScreen()),
      const _Item('Kategori', Icons.category_outlined, KategoriScreen(), adminOnly: true),
      const _Item('Supir', Icons.person_pin_circle_outlined, SupirScreen()),
      const _Item('Pesanan', Icons.receipt_long_outlined, PesananScreen()),
      const _Item('Pembayaran', Icons.payments_outlined, PembayaranScreen()),
      const _Item('Promo', Icons.local_offer_outlined, PromoScreen(), adminOnly: true),
      const _Item('Pelanggan', Icons.people_outline, PelangganScreen(), adminOnly: true),
      const _Item('Pegawai', Icons.badge_outlined, PegawaiScreen(), adminOnly: true),
      const _Item('Laporan', Icons.insert_chart_outlined, LaporanScreen(), adminOnly: true),
      const _Item('Notifikasi', Icons.notifications_none, AdminNotifikasiScreen()),
      const _Item('Pengaturan', Icons.settings_outlined, PengaturanScreen(), adminOnly: true),
      const _Item('Profil', Icons.person_outline, AdminProfileScreen()),
    ].where((e) => !e.adminOnly || auth.isAdmin).toList();

    if (_index >= items.length) _index = 0;
    final wide = MediaQuery.of(context).size.width >= 1000;

    final drawer = Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _drawerHeader(auth),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  for (var i = 0; i < items.length; i++) _tile(i, items[i]),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Rental Mobil · v1.0', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ],
        ),
      ),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 250,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    _drawerHeader(auth),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        children: [for (var i = 0; i < items.length; i++) _tile(i, items[i])],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _scaffoldBody(items, drawer)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: _appBar(auth, items),
      drawer: drawer,
      body: items[_index].page,
    );
  }

  Widget _scaffoldBody(List<_Item> items, Drawer drawer) {
    return Scaffold(
      appBar: AppBar(
        title: Text(items[_index].label),
        actions: [
          IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())), icon: const Icon(Icons.info_outline)),
          const SizedBox(width: 8),
        ],
      ),
      body: items[_index].page,
    );
  }

  PreferredSizeWidget _appBar(AuthProvider auth, List<_Item> items) {
    return AppBar(
      title: Text(items[_index].label),
      actions: [
        IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())), icon: const Icon(Icons.info_outline)),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _drawerHeader(AuthProvider auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandLogo(height: 36, radius: 12, asset: 'assets/logocitra.png'),
          const SizedBox(height: 14),
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.brandLight,
              child: Text(auth.nama.isNotEmpty ? auth.nama[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(auth.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(auth.isAdmin ? 'Administrator' : 'Staff', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _tile(int i, _Item item) {
    final active = i == _index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: active ? AppColors.brandLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _index = i);
            if (Scaffold.maybeOf(context)?.hasDrawer ?? false) Navigator.of(context).maybePop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Icon(item.icon, size: 21, color: active ? AppColors.brand : AppColors.muted),
              const SizedBox(width: 14),
              Text(item.label, style: TextStyle(color: active ? AppColors.brand : AppColors.ink, fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
            ]),
          ),
        ),
      ),
    );
  }
}
