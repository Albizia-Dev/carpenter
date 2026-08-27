import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';
import '../../foundation/tokens/carpenter.mordant.g.dart' as tokens;

final class BusyGlyph extends StatefulWidget {
  const BusyGlyph({super.key, required this.color, required this.dimension});

  final Color color;
  final double dimension;

  @override
  State<BusyGlyph> createState() => _BusyGlyphState();
}

final class _BusyGlyphState extends State<BusyGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = CarpenterTheme.of(context);
    _controller.duration = theme.motion.busyCycle.toDuration();
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strokeWidth = context.units(
      CarpenterTheme.of(context).shapes.borderWidth,
    );
    return SizedBox.square(
      dimension: widget.dimension,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _BusyGlyphPainter(
            color: widget.color,
            strokeWidth: strokeWidth,
            progress: _controller.value,
          ),
        ),
      ),
    );
  }
}

final class _BusyGlyphPainter extends CustomPainter {
  const _BusyGlyphPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  final Color color;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = strokeWidth / 2;
    canvas.drawArc(
      rect.deflate(inset),
      progress * math.pi * 2,
      tokens.motion.busyArc.toDouble() * math.pi * 2,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BusyGlyphPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.progress != progress;
}
