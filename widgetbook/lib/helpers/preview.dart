import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

Widget preview(Widget child) => Align(
  alignment: AlignmentDirectional.topStart,
  child: SingleChildScrollView(child: child),
);

Widget previewColumn(List<Widget> children) => preview(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const _PreviewGap(),
        children[index],
      ],
    ],
  ),
);

final class _PreviewGap extends StatelessWidget {
  const _PreviewGap();

  @override
  Widget build(BuildContext context) => SizedBox(height: context.units(1.rem));
}
