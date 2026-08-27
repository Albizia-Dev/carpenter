import 'package:flutter/widgets.dart';

Widget preview(Widget child) => Align(
  alignment: Alignment.topLeft,
  child: SingleChildScrollView(child: child),
);

Widget previewColumn(List<Widget> children) => preview(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children
        .expand((child) => [child, const SizedBox(height: 16)])
        .toList(growable: false),
  ),
);
