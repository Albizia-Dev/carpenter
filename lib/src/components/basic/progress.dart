import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// Linear progress indicator.
///
/// A finite [value] is clamped to 0..1 and rendered as determinate progress.
/// Leave [value] null for an indeterminate activity indicator.
final class CarpenterProgress extends StatefulWidget {
  const CarpenterProgress({
    super.key,
    this.value,
    this.height = const Rem(.25),
    this.semanticLabel = 'Progress',
  });

  final double? value;
  final LengthUnit height;
  final String semanticLabel;

  @override
  State<CarpenterProgress> createState() => _CarpenterProgressState();
}

final class _CarpenterProgressState extends State<CarpenterProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  bool get _indeterminate => widget.value == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(CarpenterProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncAnimation();
  }

  void _syncAnimation() {
    final theme = CarpenterTheme.of(context);
    _controller.duration = theme.motion.loadingCycle.toDuration();
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!_indeterminate || reduced) {
      _controller
        ..stop()
        ..value = reduced ? .35 : 0;
      return;
    }
    if (!_controller.isAnimating) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final extent = context.units(widget.height);
    final accent = theme.actions
        .resolve(
          ActionColorRole.primary,
          ActionProminence.high,
          const <WidgetState>{},
        )
        .background;
    final value = widget.value;
    final normalized = value?.clamp(0.0, 1.0).toDouble();

    return Semantics(
      label: widget.semanticLabel,
      value: normalized == null ? null : '${(normalized * 100).round()}%',
      liveRegion: normalized == null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(extent / 2),
        child: SizedBox(
          height: extent,
          child: normalized == null
              ? _IndeterminateProgress(
                  animation: _controller,
                  track: theme.surface.subtle,
                  accent: accent,
                )
              : ColoredBox(
                  color: theme.surface.subtle,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: normalized),
                    duration: theme.motion.transitionDuration(context),
                    curve: theme.motion.stateCurve,
                    builder: (context, current, _) => FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: current,
                      child: ColoredBox(color: accent),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

final class _IndeterminateProgress extends StatelessWidget {
  const _IndeterminateProgress({
    required this.animation,
    required this.track,
    required this.accent,
  });

  final Animation<double> animation;
  final Color track;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: track,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final segment = width * .32;
          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final offset = (width + segment) * animation.value - segment;
              return Stack(
                fit: StackFit.expand,
                children: [
                  PositionedDirectional(
                    start: offset,
                    top: 0,
                    bottom: 0,
                    width: segment,
                    child: ColoredBox(color: accent),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
