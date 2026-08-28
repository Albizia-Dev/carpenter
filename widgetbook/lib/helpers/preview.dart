import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

Widget preview(Widget child) => Align(
  alignment: Alignment.topLeft,
  child: SingleChildScrollView(child: child),
);

Widget previewColumn(List<Widget> children) => preview(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children
        .expand((child) => [child, const _PreviewGap()])
        .toList(growable: false),
  ),
);

final class _PreviewGap extends StatelessWidget {
  const _PreviewGap();

  @override
  Widget build(BuildContext context) => SizedBox(height: context.units(1.rem));
}
