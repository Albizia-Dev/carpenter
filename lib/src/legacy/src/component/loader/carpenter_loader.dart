import 'dart:math' as math;

import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Круговой индикатор загрузки Carpenter.
///
/// Loader использует motion, цвет и размеры из `Face`. Визуально это
/// бесконечное вращение дуги без зависимости от Material.
class CarpenterLoader extends StatefulWidget {
  /// Создает круговой loader.
  const CarpenterLoader({
    super.key,
    this.size,
    this.strokeWidth,
    this.semanticLabel,
  });

  /// Размер loader. Если не задан, используется `face.size('loader')`.
  final double? size;

  /// Толщина дуги. Если не задана, используется `face.space('0.1875')`.
  final double? strokeWidth;

  /// Accessibility-подпись loader.
  final String? semanticLabel;

  @override
  State<CarpenterLoader> createState() => _CarpenterLoaderState();
}

class _CarpenterLoaderState extends State<CarpenterLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final size = widget.size ?? face.size('loader');

    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * math.pi * 2,
              child: CustomPaint(
                painter: _CarpenterLoaderPainter(
                  color: face.color('action.primary'),
                  trackColor: face.color('surface.muted'),
                  strokeWidth: widget.strokeWidth ?? face.space('0.1875'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CarpenterLoaderPainter extends CustomPainter {
  const _CarpenterLoaderPainter({
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    final oval = rect.deflate(inset);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawOval(oval, trackPaint);
    canvas.drawArc(oval, -math.pi / 2, math.pi * 1.35, false, paint);
  }

  @override
  bool shouldRepaint(_CarpenterLoaderPainter oldDelegate) {
    return color != oldDelegate.color ||
        trackColor != oldDelegate.trackColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
