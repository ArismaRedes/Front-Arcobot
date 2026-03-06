import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIllustration extends StatelessWidget {
  const AppIllustration({
    required this.assetPath,
    this.height = 220,
    this.fit = BoxFit.contain,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    super.key,
  });

  final String assetPath;
  final double height;
  final BoxFit fit;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final isSvg = assetPath.toLowerCase().endsWith('.svg');

    return ClipRRect(
      borderRadius: borderRadius,
      child: isSvg
          ? SvgPicture.asset(
              assetPath,
              height: height,
              width: double.infinity,
              fit: fit,
              placeholderBuilder: (context) => _fallback(),
              errorBuilder: (context, error, stackTrace) => _fallback(),
            )
          : Image.asset(
              assetPath,
              height: height,
              width: double.infinity,
              fit: fit,
              errorBuilder: (context, _, __) => _fallback(),
            ),
    );
  }

  Widget _fallback() {
    return Container(
      height: height,
      color: const Color(0xFFE7EFE0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 42,
        color: Color(0xFF4B5563),
      ),
    );
  }
}
