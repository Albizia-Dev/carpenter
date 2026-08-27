import 'dart:async';

import 'package:carpenter/src/components/basic/button/button.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/page/restoration.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

class CarpenterSectionLayout extends StatelessWidget {
  const CarpenterSectionLayout({
    super.key,
    required this.title,
    required this.child,
    this.navigation,
    this.header,
    this.actions,
  });

  final String title;
  final Widget child;
  final Widget? navigation;
  final Widget? header;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      header ?? CarpenterPageHeader(title: Text(title), commandBar: actions),
      if (navigation != null) ...[
        SizedBox(height: context.face.space('0.75')),
        navigation!,
      ],
      SizedBox(height: context.face.space('1')),
      Expanded(child: child),
    ],
  );
}

class CarpenterEntityLayout extends StatelessWidget {
  const CarpenterEntityLayout({
    super.key,
    required this.header,
    required this.child,
    this.navigation,
  });

  final Widget header;
  final Widget child;
  final Widget? navigation;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      header,
      if (navigation != null) ...[
        SizedBox(height: context.face.space('0.75')),
        navigation!,
      ],
      SizedBox(height: context.face.space('1')),
      Expanded(child: child),
    ],
  );
}

enum CarpenterTabsOrientation { adaptive, horizontal, vertical }

final class CarpenterLayoutTab<T> {
  const CarpenterLayoutTab({
    required this.value,
    required this.label,
    required this.builder,
    this.badge,
    this.visible = true,
    this.enabled = true,
  });

  final T value;
  final String label;
  final WidgetBuilder builder;
  final String? badge;
  final bool visible;
  final bool enabled;
}

/// Local or externally navigated tabs. It never owns a router.
class CarpenterTabsLayout<T> extends StatelessWidget {
  const CarpenterTabsLayout({
    super.key,
    required this.value,
    required this.tabs,
    required this.onChanged,
    this.orientation = CarpenterTabsOrientation.adaptive,
    this.verticalBreakpoint = 720,
  });

  final T value;
  final List<CarpenterLayoutTab<T>> tabs;
  final ValueChanged<T> onChanged;
  final CarpenterTabsOrientation orientation;
  final double verticalBreakpoint;

  @override
  Widget build(BuildContext context) {
    final visibleTabs = tabs.where((tab) => tab.visible).toList();
    final selected = visibleTabs.where((tab) => tab.value == value).firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical =
            orientation == CarpenterTabsOrientation.vertical ||
            (orientation == CarpenterTabsOrientation.adaptive &&
                constraints.maxWidth >= verticalBreakpoint);
        final navigation = vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final tab in visibleTabs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: CarpenterButton(
                        label: _label(tab),
                        prominence: .outlined,
                        onInvoke: tab.enabled
                            ? () => onChanged(tab.value)
                            : null,
                      ),
                    ),
                ],
              )
            : CarpenterTabs<T>(
                value: value,
                tabs: [
                  for (final tab in visibleTabs)
                    CarpenterTab(value: tab.value, child: Text(_label(tab))),
                ],
                onChanged: (next) {
                  final tab = visibleTabs
                      .where((candidate) => candidate.value == next)
                      .firstOrNull;
                  if (tab?.enabled ?? false) onChanged(next);
                },
              );
        final content = selected?.builder(context) ?? const SizedBox.shrink();
        if (!vertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              navigation,
              SizedBox(height: context.face.space('1')),
              Expanded(child: content),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 240, child: navigation),
            SizedBox(width: context.face.space('1')),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  String _label(CarpenterLayoutTab<T> tab) =>
      tab.badge == null ? tab.label : '${tab.label} · ${tab.badge}';
}

enum CarpenterSplitNarrowRegion { primary, secondary, inspector }

/// Adaptive two/three-region layout with optional persisted split ratio.
class CarpenterAdaptiveSplitLayout extends StatefulWidget {
  const CarpenterAdaptiveSplitLayout({
    super.key,
    required this.primary,
    required this.secondary,
    this.inspector,
    this.narrowRegion = CarpenterSplitNarrowRegion.primary,
    this.breakpoint = 840,
    this.initialRatio = 0.38,
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

class _CarpenterAdaptiveSplitLayoutState
    extends State<CarpenterAdaptiveSplitLayout> {
  late double ratio = widget.initialRatio.clamp(0.1, 0.9).toDouble();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final value = await widget.restoration?.read<double>(widget.restorationKey);
    if (mounted && value != null) {
      setState(() => ratio = value.clamp(0.1, 0.9).toDouble());
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dividerWidth = widget.resizable ? 12.0 : 1.0;
      final minimumSplitWidth =
          widget.minPrimaryWidth + widget.minSecondaryWidth + dividerWidth;
      if (constraints.maxWidth < widget.breakpoint ||
          constraints.maxWidth < minimumSplitWidth) {
        return switch (widget.narrowRegion) {
          CarpenterSplitNarrowRegion.primary => widget.primary,
          CarpenterSplitNarrowRegion.secondary => widget.secondary,
          CarpenterSplitNarrowRegion.inspector =>
            widget.inspector ?? widget.secondary,
        };
      }
      final available = constraints.maxWidth - dividerWidth;
      final primaryWidth = (available * ratio)
          .clamp(widget.minPrimaryWidth, available - widget.minSecondaryWidth)
          .toDouble();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: primaryWidth, child: widget.primary),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: widget.resizable
                  ? (details) {
                      setState(() {
                        ratio = ((primaryWidth + details.delta.dx) / available)
                            .clamp(0.1, 0.9)
                            .toDouble();
                      });
                    }
                  : null,
              onHorizontalDragEnd: widget.resizable
                  ? (_) => unawaited(
                      widget.restoration?.write<double>(
                            widget.restorationKey,
                            ratio,
                          ) ??
                          Future<void>.value(),
                    )
                  : null,
              child: SizedBox(width: dividerWidth),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: widget.secondary),
                if (widget.inspector != null) widget.inspector!,
              ],
            ),
          ),
        ],
      );
    },
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
