import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// Compact supplementary label or count. Use status indicators for business status.
final class CarpenterBadge extends StatelessWidget {
  /// Creates a supplementary label using a semantic feedback color.
  const CarpenterBadge({
    super.key,
    required this.label,
    this.role = FeedbackColorRole.neutral,
    this.semanticLabel,
  });

  /// Formats a nonnegative [count], replacing values above positive [max]
  /// with "max+". Defaults to a danger-colored count badge.
  const CarpenterBadge.count(
    int count, {
    super.key,
    int max = 99,
    this.role = FeedbackColorRole.danger,
    this.semanticLabel,
  }) : assert(count >= 0),
       assert(max > 0),
       label = count > max ? '$max+' : '$count';

  /// Compact supplementary text or count. Use a status indicator for business
  /// status instead.
  final String label;

  /// Feedback color role used for the badge background and foreground.
  final FeedbackColorRole role;

  /// Accessible badge meaning; defaults to the formatted label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final colors = theme.feedback.resolve(role);
    final horizontal = context.units(theme.spacing.statusHorizontal);
    final vertical = context.units(theme.spacing.statusVertical);
    final minimumExtent = context.units(theme.sizes.control(ControlSize.small));
    return Semantics(
      label: semanticLabel ?? label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(
            context.units(theme.shapes.radius(ShapeRole.circular)),
          ),
        ),
        child: _BadgeFrame(
          minimumExtent: minimumExtent,
          horizontalPadding: horizontal,
          verticalPadding: vertical,
          child: Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.clip,
            style: theme.typography
                .status(context, TypographyEmphasis.strong)
                .copyWith(color: colors.foreground),
          ),
        ),
      ),
    );
  }
}

final class _BadgeFrame extends SingleChildRenderObjectWidget {
  const _BadgeFrame({
    required this.minimumExtent,
    required this.horizontalPadding,
    required this.verticalPadding,
    required super.child,
  });

  final double minimumExtent;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBadgeFrame(
    minimumExtent: minimumExtent,
    horizontalPadding: horizontalPadding,
    verticalPadding: verticalPadding,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderBadgeFrame renderObject,
  ) {
    renderObject
      ..minimumExtent = minimumExtent
      ..horizontalPadding = horizontalPadding
      ..verticalPadding = verticalPadding;
  }
}

final class _RenderBadgeFrame extends RenderShiftedBox {
  _RenderBadgeFrame({
    required this._minimumExtent,
    required this._horizontalPadding,
    required this._verticalPadding,
  }) : super(null);

  double _minimumExtent;
  double get minimumExtent => _minimumExtent;
  set minimumExtent(double value) {
    if (_minimumExtent == value) return;
    _minimumExtent = value;
    markNeedsLayout();
  }

  double _horizontalPadding;
  double get horizontalPadding => _horizontalPadding;
  set horizontalPadding(double value) {
    if (_horizontalPadding == value) return;
    _horizontalPadding = value;
    markNeedsLayout();
  }

  double _verticalPadding;
  double get verticalPadding => _verticalPadding;
  set verticalPadding(double value) {
    if (_verticalPadding == value) return;
    _verticalPadding = value;
    markNeedsLayout();
  }

  Size _frameSize(Size childSize) {
    final height = math.max(
      minimumExtent,
      childSize.height + verticalPadding * 2,
    );
    final width = math.max(
      height,
      math.max(minimumExtent, childSize.width + horizontalPadding * 2),
    );
    return constraints.constrain(Size(width, height));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(Size.square(minimumExtent));
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = _frameSize(child.size);
    final parentData = child.parentData! as BoxParentData;
    parentData.offset = Offset(
      (size.width - child.size.width) / 2,
      (size.height - child.size.height) / 2,
    );
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child == null) {
      return constraints.constrain(Size.square(minimumExtent));
    }
    final childSize = child.getDryLayout(constraints.loosen());
    final height = math.max(
      minimumExtent,
      childSize.height + verticalPadding * 2,
    );
    final width = math.max(
      height,
      math.max(minimumExtent, childSize.width + horizontalPadding * 2),
    );
    return constraints.constrain(Size(width, height));
  }
}
