import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Formats shortcut activators and pressed logical keys using platform-appropriate
/// modifier names and separators.
final class CarpenterHotkeyFormatter {
  /// Creates a key formatter for `platform`.
  const CarpenterHotkeyFormatter({required this.platform});

  /// Target platform used for platform-sensitive Carpenter behavior.
  final TargetPlatform platform;

  /// Formats a shortcut activator for display, using platform-specific modifier names
  /// and compact Apple glyph notation where applicable.
  String formatActivator(ShortcutActivator activator) {
    if (activator is LogicalKeySet) return formatPressedKeys(activator.keys);
    if (activator is! SingleActivator) return activator.debugDescribeKeys();
    final parts = <String>[
      if (activator.meta) _meta,
      if (activator.control) _control,
      if (activator.alt) _alt,
      if (activator.shift) _shift,
      _key(activator.trigger),
    ].where((part) => part.isNotEmpty).toList();
    return parts.join(_separator);
  }

  /// Formats pressed logical keys in iteration order using the same platform-specific
  /// key naming as shortcut activators.
  String formatPressedKeys(Iterable<LogicalKeyboardKey> keys) =>
      keys.map(_key).where((value) => value.isNotEmpty).join(_separator);

  bool get _apple =>
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  String get _separator => _apple ? '' : '+';
  String get _meta => _apple
      ? '⌘'
      : platform == TargetPlatform.linux
      ? 'Super'
      : 'Win';
  String get _control => _apple ? '⌃' : 'Ctrl';
  String get _alt => _apple ? '⌥' : 'Alt';
  String get _shift => _apple ? '⇧' : 'Shift';

  String _key(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      return _meta;
    }
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      return _control;
    }
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      return _alt;
    }
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      return _shift;
    }
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    final label = key.keyLabel;
    return label.length == 1
        ? label.toUpperCase()
        : label.isNotEmpty
        ? label
        : key.debugName ?? '';
  }
}
