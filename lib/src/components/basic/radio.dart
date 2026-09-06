import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/radio_group_scope.dart';
import '../../internal/rendering/selection_control.dart';

/// One mutually exclusive choice inside a matching [CarpenterRadioGroup].
///
/// The group owns selection, enabled state, and arrow-key navigation.
/// Mounting a radio outside a matching Carpenter group throws a FlutterError.
/// Values must be unique within the group.
final class CarpenterRadio<T> extends StatefulWidget {
  /// Creates a group-owned choice identified by [value]; its selection
  /// callback belongs to the enclosing [CarpenterRadioGroup].
  const CarpenterRadio({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.semanticLabel,
    this.size = ControlSize.medium,
    this.colorRole = SelectionColorRole.primary,
    this.focusNode,
    this.autofocus = false,
  });

  /// Stable value identifying this choice within the enclosing group.
  final T value;

  /// Visible text naming the control or choice; keep it meaningful without
  /// relying on an icon.
  final String label;

  /// Optional supporting text explaining the choice without replacing its
  /// accessible name.
  final String? description;

  /// Accessible name supplied to assistive technology. When omitted, the
  /// visible label is used.
  final String? semanticLabel;

  /// Semantic control size, resolving coordinated height, spacing, icon, and
  /// typography metrics.
  final ControlSize size;

  /// Semantic action or selection color resolved from the current Carpenter
  /// theme.
  final SelectionColorRole colorRole;

  /// Optional caller-owned focus node. Dispose a supplied node in its owner,
  /// not in the widget.
  final FocusNode? focusNode;

  /// Whether the control requests focus when first attached. Defaults to
  /// false.
  final bool autofocus;

  @override
  State<CarpenterRadio<T>> createState() => _CarpenterRadioState<T>();
}

final class _CarpenterRadioState<T> extends State<CarpenterRadio<T>>
    with RadioClient<T> {
  FocusNode? _ownedFocusNode;
  CarpenterRadioGroupScope<T>? _carpenterGroup;
  CarpenterRadioGroupScope<T>? _registeredGroup;

  @override
  bool get tristate => false;

  @override
  T get radioValue => widget.value;

  @override
  bool get enabled => _carpenterGroup?.onChanged != null;

  @override
  FocusNode get focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carpenterGroup = CarpenterRadioGroupScope.maybeOf<T>(context);
    registry = RadioGroup.maybeOf<T>(context);
    if (registry == null || _carpenterGroup == null) {
      throw FlutterError(
        'CarpenterRadio<$T> must be a child of CarpenterRadioGroup<$T>.',
      );
    }
    if (!identical(_registeredGroup, _carpenterGroup)) {
      _registeredGroup?.unregister(widget.value, focusNode);
      _carpenterGroup!.register(widget.value, focusNode);
      _registeredGroup = _carpenterGroup;
    }
  }

  @override
  void didUpdateWidget(CarpenterRadio<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.value != widget.value) {
      final oldFocusNode = oldWidget.focusNode ?? _ownedFocusNode!;
      _registeredGroup?.unregister(oldWidget.value, oldFocusNode);
      _ownedFocusNode?.dispose();
      _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
      _registeredGroup?.register(widget.value, focusNode);
    }
  }

  @override
  void dispose() {
    _registeredGroup?.unregister(widget.value, focusNode);
    registry = null;
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = registry!.groupValue == widget.value;
    return SelectionControl(
      kind: SelectionControlKind.radio,
      selected: selected,
      label: widget.label,
      description: widget.description,
      semanticLabel: widget.semanticLabel,
      size: widget.size,
      colorRole: widget.colorRole,
      onActivate: enabled ? () => registry!.onChanged(widget.value) : null,
      focusNode: focusNode,
      autofocus: widget.autofocus,
      shortcutCallbacks: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _carpenterGroup!.move(widget.value, true),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _carpenterGroup!.move(widget.value, true),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _carpenterGroup!.move(widget.value, false),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _carpenterGroup!.move(widget.value, false),
      },
      indicatorBuilder: (context, style, indicatorSize) => _RadioIndicator(
        selected: selected,
        style: style,
        size: indicatorSize,
        sizeRole: widget.size,
      ),
    );
  }
}

final class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({
    required this.selected,
    required this.style,
    required this.size,
    required this.sizeRole,
  });

  final bool selected;
  final CarpenterSelectionStyle style;
  final Size size;
  final ControlSize sizeRole;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final inset = context.units(theme.spacing.radioMarkInset(sizeRole));
    return AnimatedContainer(
      duration: theme.motion.transitionDuration(context),
      curve: theme.motion.stateCurve,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: style.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: style.border,
          width: context.units(theme.shapes.radioBorderWidth),
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? SizedBox.square(
              dimension: (size.shortestSide - inset * 2).clamp(
                context.units(theme.sizes.zero),
                size.shortestSide,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.mark,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
