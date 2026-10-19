import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'pelanggan/customer_shell.dart';
import 'admin/admin_shell.dart';
import 'auth/login_screen.dart';

/// Palet khusus splash (navy gelap + aksen biru metallic/gold).
class _SplashColors {
  static const navyTop = Color(0xFF061325);
  static const navyBottom = Color(0xFF0B2240);
  static const metallicA = Color(0xFF8FD3FF);
  static const metallicB = Color(0xFFCFEFFF);
  static const metallicC = Color(0xFF5AA9E6);
  static const gold = Color(0xFFFFC700);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _timer = Timer(const Duration(seconds: 3), _afterSplash);
  }

  Future<void> _afterSplash() async {
    final auth = context.read<AuthProvider>();
    if (!auth.initialized) await auth.load();
    if (!mounted) return;
    _go(auth);
  }

  void _go(AuthProvider auth) {
    Widget page = const LoginScreen();
    if (auth.loggedIn) {
      page = auth.isPelanggan ? const CustomerShell() : const AdminShell();
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_SplashColors.navyTop, _SplashColors.navyBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: -90, right: -70, child: _GlowCircle(size: 260, opacity: 0.10)),
            const Positioned(bottom: -110, left: -90, child: _GlowCircle(size: 300, opacity: 0.07)),
            const Positioned(top: 120, left: -60, child: _GlowCircle(size: 150, opacity: 0.05)),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  _logo(),
                  const SizedBox(height: 30),
                  _brand(),
                  const SizedBox(height: 22),
                  const Text(
                    'Sewa Mobil Jadi Lebih Mudah',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aplikasi Rental Mobil Terpercaya',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 13.5),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 4),
                  _DotsLoader(animation: _dots),
                  const SizedBox(height: 26),
                  Text(
                    'Copyright © 2026 Citra Rent Car',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo() {
    return SizedBox(
      width: 340,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF0E2E52), Color(0xFF081B33)],
                radius: 0.9,
              ),
              border: Border.all(color: _SplashColors.metallicA.withValues(alpha: 0.55), width: 2),
              boxShadow: [
                BoxShadow(color: _SplashColors.metallicA.withValues(alpha: 0.32), blurRadius: 40, spreadRadius: 2),
                BoxShadow(color: _SplashColors.metallicC.withValues(alpha: 0.18), blurRadius: 70, spreadRadius: 8),
              ],
            ),
          ),
          Image.asset('assets/mobilsport.png', width: 300, fit: BoxFit.contain),
        ],
      ),
    );
  }

  Widget _brand() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_SplashColors.metallicA, _SplashColors.metallicB, _SplashColors.metallicC],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.45, 1.0],
          ).createShader(r),
          child: const Text(
            'CITRA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'RENT CAR',
          style: TextStyle(
            color: _SplashColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 12,
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}

/// Loader titik-titik samar dengan animasi opacity bergilir.
class _DotsLoader extends StatelessWidget {
  final Animation<double> animation;
  const _DotsLoader({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final t = (animation.value + i * 0.22) % 1.0;
            final opacity = 0.25 + 0.6 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
