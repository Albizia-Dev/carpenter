import 'package:carpenter/src/legacy/src/page/restoration.dart';
import 'package:flutter/widgets.dart';

abstract interface class CarpenterPageCapability {
  const CarpenterPageCapability();
}

final class CarpenterRefreshCapability implements CarpenterPageCapability {
  const CarpenterRefreshCapability({required this.refresh});

  final Future<void> Function() refresh;
}

final class CarpenterRestorationCapability implements CarpenterPageCapability {
  const CarpenterRestorationCapability({required this.controller});

  final CarpenterPageRestorationController controller;
}

final class CarpenterDropCapability<T> implements CarpenterPageCapability {
  const CarpenterDropCapability({
    required this.canAccept,
    required this.execute,
    this.previewBuilder,
  });

  final bool Function(T data) canAccept;
  final Future<void> Function(T data) execute;
  final Widget Function(BuildContext context, T data)? previewBuilder;
}

enum CarpenterSelectionMode { single, multiple }

/// Selection behavior shared by collections and selection-aware page blocks.
final class CarpenterSelectionController<T> extends ChangeNotifier
    implements CarpenterPageCapability {
  CarpenterSelectionController({
    required this.identity,
    this.mode = CarpenterSelectionMode.multiple,
  });

  final Object Function(T item) identity;
  final CarpenterSelectionMode mode;
  final Set<Object> _selected = {};

  Set<Object> get selectedIds => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  int get length => _selected.length;
  bool isSelected(T item) => _selected.contains(identity(item));

  void select(T item) {
    final id = identity(item);
    if (mode == CarpenterSelectionMode.single) {
      if (_selected.length == 1 && _selected.contains(id)) return;
      _selected
        ..clear()
        ..add(id);
    } else {
      if (!_selected.add(id)) return;
    }
    notifyListeners();
  }

  void toggle(T item) {
    if (isSelected(item)) {
      deselect(item);
    } else {
      select(item);
    }
  }

  void deselect(T item) {
    if (_selected.remove(identity(item))) notifyListeners();
  }

  void selectVisible(Iterable<T> items) {
    final ids = items.map(identity);
    if (mode == CarpenterSelectionMode.single) {
      final first = ids.firstOrNull;
      if (first == null) return;
      _selected
        ..clear()
        ..add(first);
    } else {
      _selected.addAll(ids);
    }
    notifyListeners();
  }

  void clear() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
