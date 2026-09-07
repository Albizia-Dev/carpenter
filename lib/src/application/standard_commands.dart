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

  final CarpenterClipboardController<T> clipboard;
  final List<T> Function() selectedItems;
  final FutureOr<CarpenterCommandResult> Function(
    CarpenterClipboardContent<T> content,
  )
  onPaste;
  final Object? Function()? sourceId;
  final String group;

  late final CarpenterCommandController<void> copy;
  late final CarpenterCommandController<void> cut;
  late final CarpenterCommandController<void> paste;

  List<CarpenterCommand<void>> get commands => [copy, cut, paste];

  void refreshAvailability() {
    final hasSelection = selectedItems().isNotEmpty;
    copy.setAvailability(enabled: hasSelection);
    cut.setAvailability(enabled: hasSelection);
    paste.setAvailability(enabled: clipboard.hasContent);
  }

  void dispose() {
    clipboard.removeListener(refreshAvailability);
    copy.dispose();
    cut.dispose();
    paste.dispose();
  }
}

/// Standard undo/redo commands bound to one [CarpenterUndoController].
final class CarpenterUndoCommandSet {
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

  final CarpenterUndoController controller;
  final String group;

  late final CarpenterCommandController<void> undo;
  late final CarpenterCommandController<void> redo;

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

  void dispose() {
    controller.removeListener(_syncAvailability);
    undo.dispose();
    redo.dispose();
  }
}
