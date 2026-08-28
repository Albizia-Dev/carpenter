import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../page/restoration.dart';
import 'split_view.dart';

enum CarpenterSplitNarrowRegion { primary, secondary, inspector }

/// Adaptive two/three-region split with optional persisted split position.
final class CarpenterAdaptiveSplitLayout extends StatefulWidget {
  const CarpenterAdaptiveSplitLayout({
    super.key,
    required this.primary,
    required this.secondary,
    this.inspector,
    this.narrowRegion = CarpenterSplitNarrowRegion.primary,
    this.breakpoint = 840,
    this.initialRatio = .38,
    this.minPrimaryWidth = 260,
    this.minSecondaryWidth = 320,
    this.resizable = true,
    this.restoration,
    this.restorationKey = 'split-ratio',
  });

  final Widget primary;
  final Widget secondary;
  final Widget? inspector;
  final CarpenterSplitNarrowRegion narrowRegion;
  final double breakpoint;
  final double initialRatio;
  final double minPrimaryWidth;
  final double minSecondaryWidth;
  final bool resizable;
  final CarpenterPageRestorationController? restoration;
  final String restorationKey;

  @override
  State<CarpenterAdaptiveSplitLayout> createState() =>
      _CarpenterAdaptiveSplitLayoutState();
}

final class _CarpenterAdaptiveSplitLayoutState
    extends State<CarpenterAdaptiveSplitLayout> {
  late double _ratio = widget.initialRatio.clamp(.1, .9).toDouble();

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final value = await widget.restoration?.read<double>(widget.restorationKey);
    if (mounted && value != null)
      setState(() => _ratio = value.clamp(.1, .9).toDouble());
  }

  void _changed(double value) {
    setState(() => _ratio = value);
    unawaited(
      widget.restoration?.write<double>(widget.restorationKey, value) ??
          Future<void>.value(),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final minimum = widget.minPrimaryWidth + widget.minSecondaryWidth;
      if (constraints.maxWidth < widget.breakpoint ||
          constraints.maxWidth < minimum) {
        return switch (widget.narrowRegion) {
          CarpenterSplitNarrowRegion.primary => widget.primary,
          CarpenterSplitNarrowRegion.secondary => widget.secondary,
          CarpenterSplitNarrowRegion.inspector =>
            widget.inspector ?? widget.secondary,
        };
      }
      final secondary = widget.inspector == null
          ? widget.secondary
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: widget.secondary),
                widget.inspector!,
              ],
            );
      return CarpenterSplitView(
        primary: widget.primary,
        secondary: secondary,
        position: _ratio,
        minimumPosition: widget.minPrimaryWidth / constraints.maxWidth,
        maximumPosition: 1 - widget.minSecondaryWidth / constraints.maxWidth,
        onPositionChanged: widget.resizable ? _changed : null,
      );
    },
  );
}
