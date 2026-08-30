import 'package:flutter/widgets.dart';

/// Minimal framework-independent glyph ids retained for adapters and examples.
/// Applications may replace these with their own icon font or icon package.
abstract final class CarpenterIcons {
  static const accept = IconData(0x2713);
  static const search = IconData(0x2315);
  static const list = IconData(0x2637);
  static const tree = IconData(0x2442);
  static const branchFork = tree;
  static const refresh = IconData(0x21bb);
  static const clear = IconData(0x00d7);
  static const back = IconData(0x2190);
  static const next = IconData(0x2192);
  static const chevronLeft = back;
  static const chevronRight = next;
  static const add = IconData(0x002b);
  static const edit = IconData(0x270e);
  static const archive = IconData(0x25a3);
  static const restore = IconData(0x21b6);
  static const lock = IconData(0x26bf);
  static const account = IconData(0x25a4);
  static const paymentCard = account;
  static const bank = IconData(0x25b1);
  static const bankSolid = bank;
  static const file = IconData(0x25a7);
  static const openFile = file;
  static const warning = IconData(0x26a0);
  static const errorBadge = warning;
  static const info = IconData(0x24d8);
  static const download = IconData(0x21e9);
  static const upload = IconData(0x21e7);
  static const arrowDownFilled = IconData(0x2b07);
  static const arrowUpRight = IconData(0x2197);
  static const more = IconData(0x2026);
  static const save = IconData(0x25a9);
  static const copy = IconData(0x29c9);
  static const calendar = IconData(0x25a6);
  static const clock = IconData(0x25f7);
  static const code = IconData(0x2328);
  static const completedSolid = accept;
  static const removeLink = IconData(0x29c0);
  static const sortDown = IconData(0x2193);
  static const sortUp = IconData(0x2191);
}
