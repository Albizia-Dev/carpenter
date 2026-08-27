import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/adaptive.dart';
import '../../../foundation/theme.dart';
import '../split_view.dart';
import 'adaptive_region_policy.dart';
import 'region_presentation.dart';
import 'region_role.dart';

final class CarpenterAdaptiveRegion extends StatefulWidget {
  const CarpenterAdaptiveRegion({
    super.key,
    required this.primary,
    required this.region,
    required this.role,
    required this.policy,
    required this.regionVisible,
    this.onRegionVisibilityChanged,
    this.splitPosition = 0.65,
    this.onSplitPositionChanged,
    this.viewportPolicy = const CarpenterViewportPolicy(),
    this.primaryFocusNode,
    this.regionFocusNode,
    this.overlaySemanticLabel,
  });

  final Widget primary;
  final Widget region;
  final CarpenterRegionRole role;
  final CarpenterAdaptiveRegionPolicy policy;
  final bool regionVisible;
  final ValueChanged<bool>? onRegionVisibilityChanged;
  final double splitPosition;
  final ValueChanged<double>? onSplitPositionChanged;
  final CarpenterViewportPolicy viewportPolicy;
  final FocusNode? primaryFocusNode;
  final FocusNode? regionFocusNode;
  final String? overlaySemanticLabel;

  @override
  State<CarpenterAdaptiveRegion> createState() =>
      _CarpenterAdaptiveRegionState();
}

final class _CarpenterAdaptiveRegionState
    extends State<CarpenterAdaptiveRegion> {
  late final FocusNode _ownedPrimaryFocus = FocusNode();
  late final FocusNode _ownedRegionFocus = FocusNode();

  FocusNode get _primaryFocus => widget.primaryFocusNode ?? _ownedPrimaryFocus;
  FocusNode get _regionFocus => widget.regionFocusNode ?? _ownedRegionFocus;

  @override
  void initState() {
    super.initState();
    if (widget.regionVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _regionFocus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(CarpenterAdaptiveRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.regionVisible != oldWidget.regionVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        (widget.regionVisible ? _regionFocus : _primaryFocus).requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _ownedPrimaryFocus.dispose();
    _ownedRegionFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final adaptiveContext = widget.viewportPolicy.contextFor(
        context,
        constraints.maxWidth,
      );
      final presentation = widget.policy.resolve(adaptiveContext, widget.role);
      final primary = Focus(focusNode: _primaryFocus, child: widget.primary);
      final region = Focus(focusNode: _regionFocus, child: widget.region);
      return switch (presentation) {
        CarpenterRegionPresentation.hidden => primary,
        CarpenterRegionPresentation.pushed =>
          widget.regionVisible ? _escapeRegion(region) : primary,
        CarpenterRegionPresentation.inline =>
          widget.regionVisible
              ? CarpenterSplitView(
                  primary: primary,
                  secondary: region,
                  position: widget.splitPosition,
                  onPositionChanged: widget.onSplitPositionChanged,
                )
              : primary,
        CarpenterRegionPresentation.overlay =>
          widget.regionVisible
              ? _overlay(context, primary, region, constraints.maxWidth)
              : primary,
      };
    },
  );

  Widget _escapeRegion(Widget child) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          widget.onRegionVisibilityChanged?.call(false),
    },
    child: child,
  );

  Widget _overlay(
    BuildContext context,
    Widget primary,
    Widget region,
    double availableWidth,
  ) {
    final theme = CarpenterTheme.of(context);
    final preferredWidth = context.units(theme.sizes.layoutAdaptiveOverlay);
    final width = availableWidth < preferredWidth
        ? availableWidth
        : preferredWidth;
    final borderWidth = context.units(theme.shapes.adaptiveRegionBorderWidth);
    final atStart = widget.role == CarpenterRegionRole.navigation;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            widget.onRegionVisibilityChanged?.call(false),
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          primary,
          PositionedDirectional(
            top: 0,
            bottom: 0,
            start: atStart ? 0 : null,
            end: atStart ? null : 0,
            width: width,
            child: Semantics(
              container: true,
              explicitChildNodes: true,
              label:
                  widget.overlaySemanticLabel ?? '${widget.role.name} overlay',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.overlay.background,
                  border: BorderDirectional(
                    start: atStart
                        ? BorderSide.none
                        : BorderSide(
                            color: theme.overlay.border,
                            width: borderWidth,
                          ),
                    end: atStart
                        ? BorderSide(
                            color: theme.overlay.border,
                            width: borderWidth,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: region,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
