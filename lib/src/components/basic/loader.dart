import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// Indeterminate circular activity indicator without Material dependency.
final class CarpenterLoader extends StatefulWidget {
  const CarpenterLoader({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.semanticLabel = 'Loading',
  });

  final double size;
  final double strokeWidth;
  final String semanticLabel;

  @override
  State<CarpenterLoader> createState() => _CarpenterLoaderState();
}

final class _CarpenterLoaderState extends State<CarpenterLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = CarpenterTheme.of(context);
    _controller.duration = theme.motion.loadingCycle.toDuration();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      _controller
        ..stop()
        ..value = .25;
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
    final theme = CarpenterTheme.of(context);
    final accent = theme.actions
        .resolve(
          ActionColorRole.primary,
          ActionProminence.high,
          const <WidgetState>{},
        )
        .background;
    return Semantics(
      label: widget.semanticLabel,
      liveRegion: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Transform.rotate(
            angle: _controller.value * math.pi * 2,
            child: CustomPaint(
              painter: _LoaderPainter(
                color: accent,
                track: theme.surface.subtle,
                strokeWidth: widget.strokeWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _LoaderPainter extends CustomPainter {
  const _LoaderPainter({
    required this.color,
    required this.track,
    required this.strokeWidth,
  });

  final Color color;
  final Color track;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final oval = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawOval(
      oval,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      oval,
      -math.pi / 2,
      math.pi * 1.35,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_LoaderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.track != track ||
      oldDelegate.strokeWidth != strokeWidth;
}
