import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../about_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'favorit_screen.dart';
import 'notifications_screen.dart';
import 'customer_profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    try {
      final res = await Api().get('notifikasi.php');
      if (mounted) setState(() => _unread = (res['data'] as List).length);
    } catch (_) {}
  }

  final _pages = const [HomeScreen(), OrdersScreen(), FavoritScreen(), NotificationsScreen(), CustomerProfileScreen()];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final wide = MediaQuery.of(context).size.width >= 900;
    final nav = <NavigationDestination>[
      const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
      const NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
      const NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorit'),
      NavigationDestination(
        icon: _badge(const Icon(Icons.notifications_none)),
        selectedIcon: _badge(const Icon(Icons.notifications)),
        label: 'Notifikasi',
      ),
      const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
    ];

    void go(int i) {
      setState(() => _index = i);
      if (i == 3) _loadUnread();
    }

    final body = IndexedStack(
      index: _index,
      children: _pages.map((p) => p is HomeScreen ? HomeScreen(onOpenAbout: () => _openAbout()) : p).toList(),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset('assets/logocitra.png', height: 24),
          ),
        ]),
        actions: [
          IconButton(onPressed: _openAbout, icon: const Icon(Icons.info_outline), tooltip: 'Tentang Kami'),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text('Halo, ${auth.nama.split(' ').first}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: go,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.brandLight,
                destinations: [
                  const NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Beranda')),
                  const NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Pesanan')),
                  const NavigationRailDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: Text('Favorit')),
                  NavigationRailDestination(
                    icon: _badge(const Icon(Icons.notifications_none)),
                    selectedIcon: _badge(const Icon(Icons.notifications)),
                    label: const Text('Notifikasi'),
                  ),
                  const NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profil')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ])
          : body,
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: _index, onDestinationSelected: go, destinations: nav),
    );
  }

  Widget _badge(Widget icon) {
    if (_unread == 0) return icon;
    return Stack(clipBehavior: Clip.none, children: [
      icon,
      Positioned(
        right: -6, top: -4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(999)),
          child: Text('$_unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }

  void _openAbout() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
}
