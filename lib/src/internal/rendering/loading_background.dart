import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';

final class LoadingBackground extends StatefulWidget {
  const LoadingBackground({super.key, required this.color});

  final Color color;

  @override
  State<LoadingBackground> createState() => _LoadingBackgroundState();
}

final class _LoadingBackgroundState extends State<LoadingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = CarpenterTheme.of(context);
    _controller.duration = theme.motion.loadingCycle.toDuration();
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reducedMotion) {
      _controller
        ..stop()
        ..value = 0;
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
    final motion = CarpenterTheme.of(context).motion;
    final stripeWidth = context.units(motion.loadingStripe);
    final angleRadians = motion.loadingAngle.toRadians().value;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: _LoadingBackgroundPainter(
          color: widget.color,
          stripeWidth: stripeWidth,
          angleRadians: angleRadians,
          progress: _controller.value,
        ),
      ),
    );
  }
}

final class _LoadingBackgroundPainter extends CustomPainter {
  const _LoadingBackgroundPainter({
    required this.color,
    required this.stripeWidth,
    required this.angleRadians,
    required this.progress,
  });

  final Color color;
  final double stripeWidth;
  final double angleRadians;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (stripeWidth <= 0 || color.a == 0) return;

    final diagonal = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final period = stripeWidth * 2;
    final shift = progress * period;
    final center = size.center(Offset.zero);

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angleRadians)
      ..translate(-center.dx, -center.dy);

    final paint = Paint()..color = color;
    for (var x = -diagonal + shift; x < size.width + diagonal; x += period) {
      canvas.drawRect(
        Rect.fromLTWH(x, -diagonal, stripeWidth, diagonal * 2),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoadingBackgroundPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.stripeWidth != stripeWidth ||
      oldDelegate.angleRadians != angleRadians ||
      oldDelegate.progress != progress;
}
