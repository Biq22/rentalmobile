import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';
import '../pelanggan/customer_shell.dart';
import '../admin/admin_shell.dart';
import 'register_screen.dart';

/// Palet khusus halaman auth (navy gelap, gold, biru primer).
class _AuthColors {
  static const navyTop = Color(0xFF081B33);
  static const navyBottom = Color(0xFF0F325E);
  static const gold = Color(0xFFFFC700);
  static const primary = Color(0xFF0052CC);
  static const canvas = Color(0xFFFAFAFA);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      showSnack(context, 'Selamat datang, ${auth.nama}');
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, __, ___) => auth.isPelanggan ? const CustomerShell() : const AdminShell(),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 350),
      ));
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  void _toRegister() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _AuthColors.canvas,
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 800;
        final form = _LoginForm(
          formKey: _formKey,
          email: _email,
          password: _password,
          obscure: _obscure,
          loading: auth.loading,
          onSubmit: _submit,
          onToggle: () => setState(() => _obscure = !_obscure),
          onRegister: _toRegister,
        );

        if (!wide) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Image.asset('assets/logocitra.png'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  form,
                ],
              ),
            ),
          );
        }

        return Row(
          children: [
            const Expanded(child: _BrandPanel()),
            Expanded(
              child: Container(
                color: _AuthColors.canvas,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: form,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onToggle;
  final VoidCallback onRegister;

  const _LoginForm({
    required this.formKey,
    required this.email,
    required this.password,
    required this.obscure,
    required this.loading,
    required this.onSubmit,
    required this.onToggle,
    required this.onRegister,
  });

  OutlineInputBorder _border(Color c, {double width = 1}) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: width));

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Masuk', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('Masuk untuk mulai menyewa mobil favoritmu.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 28),
          const _Label('Email'),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Email wajib diisi';
              if (!s.contains('@') || !s.contains('.')) return 'Format email tidak valid';
              return null;
            },
            decoration: InputDecoration(
              hintText: 'nama@email.com',
              prefixIcon: const Icon(Icons.alternate_email),
              border: _border(AppColors.line),
              enabledBorder: _border(AppColors.line),
              focusedBorder: _border(_AuthColors.primary, width: 1.6),
              errorBorder: _border(AppColors.danger),
              focusedErrorBorder: _border(AppColors.danger, width: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          const _Label('Kata Sandi'),
          TextFormField(
            controller: password,
            obscureText: obscure,
            onFieldSubmitted: (_) => onSubmit(),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) => (v ?? '').isEmpty ? 'Kata sandi wajib diisi' : null,
            decoration: InputDecoration(
              hintText: 'Kata sandi',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              border: _border(AppColors.line),
              enabledBorder: _border(AppColors.line),
              focusedBorder: _border(_AuthColors.primary, width: 1.6),
              errorBorder: _border(AppColors.danger),
              focusedErrorBorder: _border(AppColors.danger, width: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _AuthColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _AuthColors.primary.withValues(alpha: 0.5),
              minimumSize: const Size.fromHeight(52),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            child: loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Masuk'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Belum punya akun? ', style: TextStyle(color: AppColors.muted)),
              GestureDetector(
                onTap: onRegister,
                child: const Text('Daftar sekarang', style: TextStyle(color: _AuthColors.primary, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

/// Panel kiri desktop: banner branding + promo.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_AuthColors.navyTop, _AuthColors.navyBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Positioned.fill(child: CustomPaint(painter: _FleetPainter())),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 130,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, _AuthColors.navyBottom],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SOLUSI TRANSPORTASI',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      const Text('MURAH DAN CEPAT',
                          style: TextStyle(color: _AuthColors.gold, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: 1)),
                      const SizedBox(height: 10),
                      Text('Praktis, Nyaman, Dan Langsung Jalan!',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 14)),
                      const SizedBox(height: 20),
                      _car(),
                      const SizedBox(height: 20),
                      const Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Badge(icon: Icons.verified, text: 'Armada terawat'),
                          _Badge(icon: Icons.price_check, text: 'Harga transparan'),
                          _Badge(icon: Icons.support_agent, text: 'Layanan ramah'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _car() {
    return Center(
      child: SizedBox(
        height: 230,
        width: 230,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF0E2E52), Color(0xFF081B33)],
                  radius: 0.9,
                ),
                border: Border.all(color: const Color(0xFF8FD3FF).withValues(alpha: 0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2),
                  BoxShadow(color: const Color(0xFF8FD3FF).withValues(alpha: 0.35), blurRadius: 44, spreadRadius: 2),
                ],
              ),
              child: CustomPaint(painter: _LightningRingPainter()),
            ),
            Transform.scale(
              scale: 1.2,
              child: Image.asset('assets/mobilsport.png', height: 176, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Badge({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF1D4E89).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      );
}

/// Grid / peta digital samar di latar panel kiri.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final node = Paint()..color = Colors.white.withValues(alpha: 0.08);
    for (double x = step; x < size.width; x += step * 2) {
      for (double y = step; y < size.height; y += step * 2) {
        canvas.drawCircle(Offset(x, y), 1.6, node);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Siluet deretan armada mobil di bagian bawah panel.
class _FleetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final baseY = size.height - 26;
    final carW = 120.0;
    final gap = 26.0;
    final total = (carW + gap) * 10;
    double x = (size.width - total) / 2;
    while (x < size.width + carW) {
      _car(canvas, paint, x, baseY, carW, 34);
      x += carW + gap;
    }
  }

  void _car(Canvas canvas, Paint paint, double x, double y, double w, double h) {
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(x, y - h * 0.45, w, h * 0.45),
      topLeft: Radius.circular(h * 0.22),
      topRight: Radius.circular(h * 0.22),
    );
    canvas.drawRRect(body, paint);
    final cabin = RRect.fromRectAndCorners(
      Rect.fromLTWH(x + w * 0.22, y - h * 0.85, w * 0.56, h * 0.45),
      topLeft: Radius.circular(h * 0.25),
      topRight: Radius.circular(h * 0.25),
    );
    canvas.drawRRect(cabin, paint);
    canvas.drawCircle(Offset(x + w * 0.22, y), h * 0.14, paint);
    canvas.drawCircle(Offset(x + w * 0.78, y), h * 0.14, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Efek ring petir bercahaya di belakang mobil.
class _LightningRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF8FD3FF).withValues(alpha: 0.45);
    canvas.drawCircle(center, radius, ring);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFCFEFFF).withValues(alpha: 0.7);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -0.9, 1.0, false, arc);
    canvas.drawArc(rect, 1.4, 0.8, false, arc);
    canvas.drawArc(rect, 3.4, 1.1, false, arc);

    final bolt = Paint()..color = const Color(0xFFFFC700).withValues(alpha: 0.85);
    final path = Path()
      ..moveTo(center.dx - 6, center.dy - radius - 2)
      ..lineTo(center.dx + 2, center.dy - radius + 12)
      ..lineTo(center.dx - 3, center.dy - radius + 12)
      ..lineTo(center.dx + 6, center.dy - radius + 28)
      ..lineTo(center.dx - 8, center.dy - radius + 10)
      ..lineTo(center.dx - 3, center.dy - radius + 10)
      ..close();
    canvas.drawPath(path, bolt);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
