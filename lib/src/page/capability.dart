import 'package:flutter/widgets.dart';

import 'restoration.dart';

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
  const CarpenterDropCapability({required this.canAccept, required this.execute, this.previewBuilder});
  final bool Function(T data) canAccept;
  final Future<void> Function(T data) execute;
  final Widget Function(BuildContext context, T data)? previewBuilder;
}

enum CarpenterSelectionMode { single, multiple }

final class CarpenterSelectionController<T> extends ChangeNotifier implements CarpenterPageCapability {
  CarpenterSelectionController({required this.identity, this.mode = CarpenterSelectionMode.multiple});
  final Object Function(T item) identity;
  final CarpenterSelectionMode mode;
  final Set<Object> _selected = {};
  Set<Object> get selectedIds => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  int get length => _selected.length;
  bool isSelected(T item) => _selected.contains(identity(item));

  void select(T item) {
    final id = identity(item);
    if (mode == CarpenterSelectionMode.single) _selected.clear();
    if (_selected.add(id)) notifyListeners();
  }
  void toggle(T item) => isSelected(item) ? deselect(item) : select(item);
  void deselect(T item) { if (_selected.remove(identity(item))) notifyListeners(); }
  void selectVisible(Iterable<T> items) {
    if (mode == CarpenterSelectionMode.single) {
      final iterator = items.iterator;
      if (!iterator.moveNext()) return;
      _selected
        ..clear()
        ..add(identity(iterator.current));
    } else {
      _selected.addAll(items.map(identity));
    }
    notifyListeners();
  }
  void clear() { if (_selected.isNotEmpty) { _selected.clear(); notifyListeners(); } }
}
