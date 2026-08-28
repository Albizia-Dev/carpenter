import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';
import 'page_header.dart';

/// Simple page section layout retained for navigation-driven pages.
final class CarpenterSectionLayout extends StatelessWidget {
  const CarpenterSectionLayout({super.key, required this.title, required this.child, this.navigation, this.header, this.actions});
  final String title;
  final Widget child;
  final Widget? navigation;
  final Widget? header;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.layoutSection);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      header ?? CarpenterPageHeader(title: title, actions: actions),
      if (navigation != null) ...[SizedBox(height: gap), navigation!],
      SizedBox(height: gap),
      Expanded(child: child),
    ]);
  }
}

final class CarpenterEntityLayout extends StatelessWidget {
  const CarpenterEntityLayout({super.key, required this.header, required this.child, this.navigation});
  final Widget header;
  final Widget child;
  final Widget? navigation;
  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.layoutSection);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [header, if (navigation != null) ...[SizedBox(height: gap), navigation!], SizedBox(height: gap), Expanded(child: child)]);
  }
}
