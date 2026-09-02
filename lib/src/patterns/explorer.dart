import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../components/layout/page_header.dart';
import '../components/layout/regions/region_role.dart';
import '../foundation/theme.dart';
import '../page/descriptor.dart';
import '../page/page.dart';
import '../page/state.dart';

/// Explorer pattern with navigation, content and optional inspector regions.
final class CarpenterExplorerPage extends StatelessWidget {
  const CarpenterExplorerPage({
    super.key,
    required this.descriptor,
    required this.navigation,
    required this.content,
    this.search,
    this.inspector,
    this.header,
    this.compactNavigation,
    this.state = const CarpenterPageReady(),
    this.breakpoint = 760,
  });
  final CarpenterPageDescriptor descriptor;
  final Widget navigation;
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
                compactNavigation ?? navigation,
                SizedBox(height: gap),
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
                    SizedBox(
                      width: context.units(15.625.rem),
                      child: navigation,
                    ),
                    SizedBox(width: gap),
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
