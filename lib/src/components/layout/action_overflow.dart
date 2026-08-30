import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum ActionOverflowGroup { primary, secondary, overflow }

enum ActionOverflowStage { expanded, secondaryOverflow, iconOnly, overflowOnly }

@immutable
final class ActionOverflowEntry<T> {
  const ActionOverflowEntry({
    required this.value,
    required this.group,
    required this.expandedWidth,
    this.iconWidth,
  });

  final T value;
  final ActionOverflowGroup group;
  final double expandedWidth;
  final double? iconWidth;
}

@immutable
final class ActionOverflowResolution<T> {
  const ActionOverflowResolution({
    required this.stage,
    required this.visible,
    required this.overflow,
    required this.requiredWidth,
  });

  final ActionOverflowStage stage;
  final List<T> visible;
  final List<T> overflow;
  final double requiredWidth;

  bool get iconOnly => stage == ActionOverflowStage.iconOnly;
}

final class ActionOverflowResolver<T> {
  const ActionOverflowResolver();

  ActionOverflowResolution<T> resolve({
    required List<ActionOverflowEntry<T>> entries,
    required double availableWidth,
    required double gap,
    required double overflowWidth,
  }) {
    final expanded = _resolution(
      entries: entries,
      stage: ActionOverflowStage.expanded,
      visibleWhen: (entry) => entry.group != ActionOverflowGroup.overflow,
      gap: gap,
      overflowWidth: overflowWidth,
    );
    if (_fits(expanded, availableWidth)) return expanded;

    final secondaryOverflow = _resolution(
      entries: entries,
      stage: ActionOverflowStage.secondaryOverflow,
      visibleWhen: (entry) => entry.group == ActionOverflowGroup.primary,
      gap: gap,
      overflowWidth: overflowWidth,
    );
    if (_fits(secondaryOverflow, availableWidth)) return secondaryOverflow;

    final primary = entries
        .where((entry) => entry.group == ActionOverflowGroup.primary)
        .toList();
    if (primary.isNotEmpty &&
        primary.every((entry) => entry.iconWidth != null)) {
      final iconOnly = _resolution(
        entries: entries,
        stage: ActionOverflowStage.iconOnly,
        visibleWhen: (entry) => entry.group == ActionOverflowGroup.primary,
        gap: gap,
        overflowWidth: overflowWidth,
      );
      if (_fits(iconOnly, availableWidth)) return iconOnly;
    }

    return _resolution(
      entries: entries,
      stage: ActionOverflowStage.overflowOnly,
      visibleWhen: (_) => false,
      gap: gap,
      overflowWidth: overflowWidth,
    );
  }

  ActionOverflowResolution<T> _resolution({
    required List<ActionOverflowEntry<T>> entries,
    required ActionOverflowStage stage,
    required bool Function(ActionOverflowEntry<T>) visibleWhen,
    required double gap,
    required double overflowWidth,
  }) {
    final visibleEntries = entries.where(visibleWhen).toList();
    final overflowEntries = entries
        .where((entry) => !visibleWhen(entry))
        .toList();
    final useIcons = stage == ActionOverflowStage.iconOnly;
    var requiredWidth = 0.0;
    for (var index = 0; index < visibleEntries.length; index++) {
      if (index > 0) requiredWidth += gap;
      final entry = visibleEntries[index];
      requiredWidth += useIcons ? entry.iconWidth! : entry.expandedWidth;
    }
    if (overflowEntries.isNotEmpty) {
      if (visibleEntries.isNotEmpty) requiredWidth += gap;
      requiredWidth += overflowWidth;
    }
    return ActionOverflowResolution(
      stage: stage,
      visible: [for (final entry in visibleEntries) entry.value],
      overflow: [for (final entry in overflowEntries) entry.value],
      requiredWidth: requiredWidth,
    );
  }

  bool _fits(ActionOverflowResolution<T> resolution, double availableWidth) =>
      !availableWidth.isFinite || resolution.requiredWidth <= availableWidth;
}

final class ActionOverflowLayout extends MultiChildRenderObjectWidget {
  ActionOverflowLayout({
    super.key,
    required Widget content,
    required Widget actions,
    required this.gap,
    required this.minimumInlineActionWidth,
  }) : assert(gap >= 0),
       assert(minimumInlineActionWidth >= 0),
       super(children: [content, actions]);

  final double gap;
  final double minimumInlineActionWidth;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderActionOverflow(
        gap: gap,
        minimumInlineActionWidth: minimumInlineActionWidth,
        textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderActionOverflow renderObject,
  ) {
    renderObject
      ..gap = gap
      ..minimumInlineActionWidth = minimumInlineActionWidth
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

final class _ActionOverflowParentData
    extends ContainerBoxParentData<RenderBox> {}

final class _RenderActionOverflow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ActionOverflowParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ActionOverflowParentData> {
  _RenderActionOverflow({
    required double gap,
    required double minimumInlineActionWidth,
    required TextDirection textDirection,
  }) : _gap = gap,
       _minimumInlineActionWidth = minimumInlineActionWidth,
       _textDirection = textDirection;

  double _gap;
  double _minimumInlineActionWidth;
  TextDirection _textDirection;

  double get gap => _gap;

  set gap(double value) {
    if (_gap == value) return;
    _gap = value;
    markNeedsLayout();
  }

  double get minimumInlineActionWidth => _minimumInlineActionWidth;

  set minimumInlineActionWidth(double value) {
    if (_minimumInlineActionWidth == value) return;
    _minimumInlineActionWidth = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ActionOverflowParentData) {
      child.parentData = _ActionOverflowParentData();
    }
  }

  @override
  void performLayout() {
    final content = firstChild!;
    final actions = childAfter(content)!;
    final maxWidth = constraints.maxWidth;
    final loose = constraints.loosen();

    content.layout(loose, parentUsesSize: true);

    final inline =
        !maxWidth.isFinite ||
        maxWidth - content.size.width - gap >= minimumInlineActionWidth;
    double actionMaxWidth;
    if (!inline) {
      actionMaxWidth = maxWidth;
    } else if (!maxWidth.isFinite) {
      actionMaxWidth = double.infinity;
    } else {
      actionMaxWidth = (maxWidth - content.size.width - gap)
          .clamp(0.0, double.infinity)
          .toDouble();
    }
    actions.layout(
      BoxConstraints(
        maxWidth: actionMaxWidth,
        maxHeight: constraints.maxHeight,
      ),
      parentUsesSize: true,
    );

    final naturalWidth = inline
        ? content.size.width + gap + actions.size.width
        : _max(content.size.width, actions.size.width);
    final naturalHeight = inline
        ? _max(content.size.height, actions.size.height)
        : content.size.height + gap + actions.size.height;
    size = constraints.constrain(Size(naturalWidth, naturalHeight));

    final contentParentData = content.parentData! as _ActionOverflowParentData;
    final actionsParentData = actions.parentData! as _ActionOverflowParentData;
    if (inline) {
      contentParentData.offset = Offset(_startX(content.size.width), 0);
      actionsParentData.offset = Offset(_endX(actions.size.width), 0);
    } else {
      contentParentData.offset = Offset(_startX(content.size.width), 0);
      actionsParentData.offset = Offset(
        _endX(actions.size.width),
        content.size.height + gap,
      );
    }
  }

  double _startX(double childWidth) =>
      textDirection == TextDirection.ltr ? 0 : size.width - childWidth;

  double _endX(double childWidth) =>
      textDirection == TextDirection.ltr ? size.width - childWidth : 0;

  double _max(double first, double second) => first > second ? first : second;

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
