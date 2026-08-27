import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

final class CuratedIcon {
  const CuratedIcon(this.label, this.data);

  final String label;
  final IconData data;
}

const curatedIcons = [
  CuratedIcon('Add', Icons.add),
  CuratedIcon('Delete', Icons.delete),
  CuratedIcon('Edit', Icons.edit),
  CuratedIcon('Search', Icons.search),
  CuratedIcon('Settings', Icons.settings),
  CuratedIcon('Check', Icons.check),
  CuratedIcon('Warning', Icons.warning),
  CuratedIcon('Info', Icons.info),
  CuratedIcon('Arrow forward', Icons.arrow_forward),
  CuratedIcon('More', Icons.more_horiz),
];
