import 'package:flutter/widgets.dart';
import 'package:carpenter_units/carpenter_units.dart';

Widget preview(Widget child) => Align(
  alignment: Alignment.topLeft,
  child: SingleChildScrollView(child: child),
);

Widget previewColumn(List<Widget> children) => preview(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children
        .expand((child) => [child, SizedBox(height: context.units(1.rem))])
        .toList(growable: false),
  ),
);
