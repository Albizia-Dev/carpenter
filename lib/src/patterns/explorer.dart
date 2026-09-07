import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../components/basic/select/selection_button_group.dart';
import '../components/layout/page_header.dart';
import '../components/layout/regions/region_role.dart';
import '../foundation/icon_data.dart';
import '../foundation/roles.dart';
import '../foundation/theme.dart';
import '../page/descriptor.dart';
import '../page/page.dart';
import '../page/state.dart';

/// One stable destination shown by [CarpenterExplorerLocationStrip].
@immutable
final class CarpenterExplorerDestination<L> {
  /// Creates one caller-owned explorer destination.
  const CarpenterExplorerDestination({
    required this.location,
    required this.label,
    this.icon,
    this.enabled = true,
    this.semanticLabel,
  });

  /// Stable location value emitted when this destination is selected.
  final L location;

  /// Visible destination label.
  final String label;

  /// Optional leading semantic icon.
  final CarpenterIconSource? icon;

  /// Whether this destination may currently be selected.
  final bool enabled;

  /// Optional accessible label overriding [label].
  final String? semanticLabel;
}

/// Controlled explorer destination strip with an optional remembered location.
///
/// Primary destinations remain visible while navigation enters nested content.
/// A caller-owned remembered destination is appended as one more peer and stays
/// present when a primary destination is selected. Carpenter deliberately does
/// not decide when remembered state changes; applications normally replace it
/// only after explicit activation such as a directory double-click.
final class CarpenterExplorerLocationStrip<L> extends StatelessWidget {
  /// Creates a controlled strip of primary and optional remembered locations.
  const CarpenterExplorerLocationStrip({
    super.key,
    required this.primaryDestinations,
    required this.current,
    required this.onChanged,
    this.rememberedDestination,
    this.size = ControlSize.medium,
    this.semanticLabel = 'Explorer locations',
  }) : assert(primaryDestinations.length > 0);

  /// Stable root/scope destinations that always remain visible.
  final List<CarpenterExplorerDestination<L>> primaryDestinations;

  /// Optional caller-owned nested destination appended after primary locations.
  final CarpenterExplorerDestination<L>? rememberedDestination;

  /// Currently selected location value.
  final L current;

  /// Reports requested location changes without mutating caller state.
  final ValueChanged<L>? onChanged;

  /// Semantic size of the joined destination controls.
  final ControlSize size;

  /// Accessible label for the location-selection group.
  final String semanticLabel;

  /// Builds the joined location controls from caller-owned destinations.
  @override
  Widget build(BuildContext context) {
    final remembered = rememberedDestination;
    final destinations = <CarpenterExplorerDestination<L>>[
      ...primaryDestinations,
      if (remembered != null &&
          !primaryDestinations.any(
            (destination) => destination.location == remembered.location,
          ))
        remembered,
    ];
    return CarpenterSelectionButtonGroup<L>(
      options: [
        for (final destination in destinations)
          CarpenterSelectionButtonOption<L>(
            value: destination.location,
            label: destination.label,
            icon: destination.icon,
            enabled: destination.enabled,
            semanticLabel: destination.semanticLabel,
          ),
      ],
      value: current,
      onChanged: onChanged,
      size: size,
      semanticLabel: semanticLabel,
      fillAvailableWidth: true,
    );
  }
}

/// Controlled navigation history for an explorer location.
///
/// The application owns this value and may serialize or persist it alongside
/// its per-location view state. Navigating to a new location clears the
/// forward stack; moving backward or forward never touches router history.
@immutable
final class CarpenterExplorerHistory<L> {
  const CarpenterExplorerHistory({
    required this.current,
    this.backStack = const [],
    this.forwardStack = const [],
  });

  final L current;
  final List<L> backStack;
  final List<L> forwardStack;

  bool get canGoBack => backStack.isNotEmpty;
  bool get canGoForward => forwardStack.isNotEmpty;

  CarpenterExplorerHistory<L> navigateTo(L location) {
    if (location == current) return this;
    return CarpenterExplorerHistory<L>(
      current: location,
      backStack: List<L>.unmodifiable([...backStack, current]),
    );
  }

  CarpenterExplorerHistory<L> goBack() {
    if (!canGoBack) return this;
    return CarpenterExplorerHistory<L>(
      current: backStack.last,
      backStack: List<L>.unmodifiable(backStack.take(backStack.length - 1)),
      forwardStack: List<L>.unmodifiable([current, ...forwardStack]),
    );
  }

  CarpenterExplorerHistory<L> goForward() {
    if (!canGoForward) return this;
    return CarpenterExplorerHistory<L>(
      current: forwardStack.first,
      backStack: List<L>.unmodifiable([...backStack, current]),
      forwardStack: List<L>.unmodifiable(forwardStack.skip(1)),
    );
  }
}

/// Explorer pattern with navigation, content and optional inspector regions.
final class CarpenterExplorerPage extends StatelessWidget {
  const CarpenterExplorerPage({
    super.key,
    required this.descriptor,
    this.navigation,
    required this.content,
    this.search,
    this.inspector,
    this.header,
    this.compactNavigation,
    this.state = const CarpenterPageReady(),
    this.breakpoint = 760,
  });
  final CarpenterPageDescriptor descriptor;
  final Widget? navigation;
  final Widget content;
  final Widget? search;
  final Widget? inspector;
  final Widget? header;
  final Widget? compactNavigation;
  final CarpenterPageState state;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    assert(descriptor.kind == CarpenterPageKind.explorer);
    final gap = context.units(CarpenterTheme.of(context).spacing.layoutSection);
    return CarpenterPage(
      descriptor: descriptor,
      state: state,
      scrollOwnership: CarpenterRegionScrollOwnership.child,
      header:
          header ??
          CarpenterPageHeader(title: descriptor.title, actions: search),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < breakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (search != null) ...[search!, SizedBox(height: gap)],
                if (compactNavigation ?? navigation
                    case final Widget value) ...[
                  value,
                  SizedBox(height: gap),
                ],
                Expanded(child: content),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (search != null) ...[search!, SizedBox(height: gap)],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (navigation case final Widget value) ...[
                      SizedBox(width: context.units(15.625.rem), child: value),
                      SizedBox(width: gap),
                    ],
                    Expanded(child: content),
                    if (inspector != null) ...[
                      SizedBox(width: gap),
                      inspector!,
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
