import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config.dart';
import '../services/api.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: error ? AppColors.danger : AppColors.ink,
    ));
}

/// Kontainer responsif untuk web supaya konten tidak melebar penuh.
class AppBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const AppBody({super.key, required this.child, this.maxWidth = 1200});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SectionCard({super.key, required this.title, this.icon, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) ...[Icon(icon, size: 18, color: AppColors.brand), const SizedBox(width: 8)],
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ]),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class BrandLogo extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final double radius;
  final String asset;
  const BrandLogo({super.key, this.height = 28, this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6), this.radius = 12, this.asset = 'assets/logorentalmobile.jpg'});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Image.asset(asset, height: height),
      );
}

class AppEmpty extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? title;
  const AppEmpty({super.key, required this.message, this.icon = Icons.inbox_outlined, this.title});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84, height: 84,
                decoration: const BoxDecoration(color: AppColors.brandLight, shape: BoxShape.circle),
                child: Icon(icon, size: 38, color: AppColors.brand),
              ),
              const SizedBox(height: 16),
              if (title != null) ...[
                Text(title!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), textAlign: TextAlign.center),
                const SizedBox(height: 6),
              ],
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
}

class AppError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 54, color: AppColors.danger),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
              ],
            ],
          ),
        ),
      );
}

class CarImage extends StatelessWidget {
  final String? foto;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? radius;
  const CarImage({super.key, required this.foto, this.height, this.width, this.fit = BoxFit.cover, this.radius});

  @override
  Widget build(BuildContext context) {
    final url = Api().fotoUrl(foto);
    final r = radius ?? BorderRadius.circular(16);
    Widget child;
    if (url.isEmpty) {
      child = Container(color: AppColors.brandLight, child: const Icon(Icons.directions_car, size: 40, color: AppColors.brand));
    } else if (kIsWeb) {
      // Di web, CanvasKit memuat gambar lewat elemen <img> yang diupload ke WebGL
      // (makeTexture). Jalur ini rawan gagal / tampil hitam (lihat flutter#160127).
      // Image.network memakai jalur XHR -> bytes -> decode, jadi bebas masalah itu.
      child = Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return Shimmer.fromColors(
            baseColor: const Color(0xFFE6EAF0),
            highlightColor: const Color(0xFFF5F8FC),
            child: Container(color: Colors.white, height: height, width: width),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.brandLight,
          child: const Icon(Icons.broken_image_outlined, size: 34, color: AppColors.muted),
        ),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: width,
        fit: fit,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: const Color(0xFFE6EAF0),
          highlightColor: const Color(0xFFF5F8FC),
          child: Container(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.brandLight,
          child: const Icon(Icons.broken_image_outlined, size: 34, color: AppColors.muted),
        ),
      );
    }
    return ClipRRect(borderRadius: r, child: SizedBox(height: height, width: width, child: child));
  }
}

class AppBackdrop extends StatelessWidget {
  final Widget child;
  final String asset;
  const AppBackdrop({super.key, required this.child, this.asset = 'assets/pemandangan.jpg'});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white.withValues(alpha: 0.78), AppColors.surface.withValues(alpha: 0.92)],
            ),
          ),
          child: child,
        ),
      );
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const StatCard({super.key, required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
        ),
      );
}

class Skeleton extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? radius;
  const Skeleton({super.key, this.height = 16, this.width, this.radius});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: const Color(0xFFE6EAF0),
        highlightColor: const Color(0xFFF5F8FC),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(color: Colors.white, borderRadius: radius ?? BorderRadius.circular(8)),
        ),
      );
}

/// Bintang rating read-only (mendukung setengah bintang).
class RatingStars extends StatelessWidget {
  final double rating;
  final int? count;
  final double size;
  final Color color;
  const RatingStars({super.key, required this.rating, this.count, this.size = 16, this.color = AppColors.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i ? Icons.star_rounded : (rating >= i - 0.5 ? Icons.star_half_rounded : Icons.star_outline_rounded),
            size: size,
            color: color,
          ),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.w700, fontSize: size - 4)),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text('($count)', style: TextStyle(color: AppColors.muted, fontSize: size - 4)),
        ],
      ],
    );
  }
}

/// Baris bintang interaktif untuk memilih rating 1-5.
class RatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  const RatingInput({super.key, required this.value, required this.onChanged, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(i <= value ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.accent),
          ),
      ],
    );
  }
}

