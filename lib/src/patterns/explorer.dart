import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../components/layout/page_header.dart';
import '../components/layout/regions/region_role.dart';
import '../foundation/theme.dart';
import '../page/descriptor.dart';
import '../page/page.dart';
import '../page/state.dart';

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
