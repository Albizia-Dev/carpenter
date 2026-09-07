import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../components/behaviour/clipboard.dart';
import '../components/behaviour/undo/undo_controller.dart';
import 'command.dart';

/// Reusable copy/cut/paste command set backed by Carpenter's typed clipboard.
///
/// The application supplies the current selection and paste implementation;
/// Carpenter supplies stable commands and familiar platform shortcuts. Call
/// [refreshAvailability] after external selection state changes.
final class CarpenterClipboardCommandSet<T> {
  /// Creates clipboard commands bound to [clipboard] and caller-owned selection.
  CarpenterClipboardCommandSet({
    required this.clipboard,
    required this.selectedItems,
    required this.onPaste,
    this.sourceId,
    this.group = 'Explorer',
  }) {
    copy = CarpenterCommandController<void>(
      id: 'clipboard.copy',
      title: 'Copy',
      group: group,
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyC, control: true),
      ],
      macOSShortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyC, meta: true),
      ],
      execute: (_) {
        clipboard.copy(selectedItems(), sourceId: sourceId?.call());
        refreshAvailability();
        return const CarpenterCommandResult();
      },
    );
    cut = CarpenterCommandController<void>(
      id: 'clipboard.cut',
      title: 'Cut',
      group: group,
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyX, control: true),
      ],
      macOSShortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyX, meta: true),
      ],
      execute: (_) {
        clipboard.cut(selectedItems(), sourceId: sourceId?.call());
        refreshAvailability();
        return const CarpenterCommandResult();
      },
    );
    paste = CarpenterCommandController<void>(
      id: 'clipboard.paste',
      title: 'Paste',
      group: group,
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyV, control: true),
      ],
      macOSShortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyV, meta: true),
      ],
      execute: (_) async {
        final content = clipboard.value;
        if (content == null || content.items.isEmpty) {
          throw StateError('Clipboard is empty.');
        }
        final result = await Future<CarpenterCommandResult>.sync(
          () => onPaste(content),
        );
        if (content.isCut && identical(clipboard.value, content)) {
          clipboard.clear();
        }
        refreshAvailability();
        return result;
      },
    );
    clipboard.addListener(refreshAvailability);
    refreshAvailability();
  }

  /// Typed clipboard that stores the current copy or cut payload.
  final CarpenterClipboardController<T> clipboard;

  /// Reads the application's current selected items when copy or cut executes.
  final List<T> Function() selectedItems;

  /// Performs application-owned paste semantics for the current payload.
  final FutureOr<CarpenterCommandResult> Function(
    CarpenterClipboardContent<T> content,
  )
  onPaste;

  /// Optionally identifies the current source location written to the clipboard.
  final Object? Function()? sourceId;

  /// Command group used by action and command-palette presentation.
  final String group;

  /// Standard copy command, including Ctrl+C and Command+C shortcuts.
  late final CarpenterCommandController<void> copy;

  /// Standard cut command, including Ctrl+X and Command+X shortcuts.
  late final CarpenterCommandController<void> cut;

  /// Standard paste command, including Ctrl+V and Command+V shortcuts.
  late final CarpenterCommandController<void> paste;

  /// Commands in conventional copy, cut, paste order.
  List<CarpenterCommand<void>> get commands => [copy, cut, paste];

  /// Synchronizes command availability with selection and clipboard state.
  void refreshAvailability() {
    final hasSelection = selectedItems().isNotEmpty;
    copy.setAvailability(enabled: hasSelection);
    cut.setAvailability(enabled: hasSelection);
    paste.setAvailability(enabled: clipboard.hasContent);
  }

  /// Detaches listeners and disposes the command controllers owned by this set.
  void dispose() {
    clipboard.removeListener(refreshAvailability);
    copy.dispose();
    cut.dispose();
    paste.dispose();
  }
}

/// Standard undo/redo commands bound to one [CarpenterUndoController].
final class CarpenterUndoCommandSet {
  /// Creates undo and redo commands that reflect [controller] history state.
  CarpenterUndoCommandSet({required this.controller, this.group = 'Edit'}) {
    undo = CarpenterCommandController<void>(
      id: 'history.undo',
      title: 'Undo',
      group: group,
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyZ, control: true),
      ],
      macOSShortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
      ],
      execute: (_) async {
        await controller.undo();
        return const CarpenterCommandResult();
      },
    );
    redo = CarpenterCommandController<void>(
      id: 'history.redo',
      title: 'Redo',
      group: group,
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true),
      ],
      macOSShortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true),
      ],
      windowsShortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true),
        SingleActivator(LogicalKeyboardKey.keyY, control: true),
      ],
      execute: (_) async {
        await controller.redo();
        return const CarpenterCommandResult();
      },
    );
    controller.addListener(_syncAvailability);
    _syncAvailability();
  }

  /// History controller that owns reversible application operations.
  final CarpenterUndoController controller;

  /// Command group used by action and command-palette presentation.
  final String group;

  /// Standard undo command with platform-native shortcuts.
  late final CarpenterCommandController<void> undo;

  /// Standard redo command with platform-native shortcuts.
  late final CarpenterCommandController<void> redo;

  /// Commands in undo, redo order.
  List<CarpenterCommand<void>> get commands => [undo, redo];

  void _syncAvailability() {
    final undoOperation = controller.value.nextUndo;
    final redoOperation = controller.value.nextRedo;
    undo.setAvailability(
      enabled: controller.canUndo,
      disabledReason: undoOperation == null ? 'Nothing to undo.' : null,
    );
    redo.setAvailability(
      enabled: controller.canRedo,
      disabledReason: redoOperation == null ? 'Nothing to redo.' : null,
    );
  }

  /// Detaches the history listener and disposes both command controllers.
  void dispose() {
    controller.removeListener(_syncAvailability);
    undo.dispose();
    redo.dispose();
  }
}
