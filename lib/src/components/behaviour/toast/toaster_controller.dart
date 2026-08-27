import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'toast.dart';

/// Imperatively manages transient toast presentation, not application state.
final class CarpenterToasterController extends ChangeNotifier {
  final List<CarpenterToastDescriptor> _toasts = [];

  UnmodifiableListView<CarpenterToastDescriptor> get toasts =>
      UnmodifiableListView(_toasts);

  void show(CarpenterToastDescriptor descriptor) {
    final existing = _toasts.indexWhere((toast) => toast.id == descriptor.id);
    if (existing >= 0) {
      _toasts[existing] = descriptor;
    } else {
      _toasts.add(descriptor);
    }
    notifyListeners();
  }

  void dismiss(Object id) {
    final hadMatch = _toasts.any((toast) => toast.id == id);
    _toasts.removeWhere((toast) => toast.id == id);
    if (hadMatch) notifyListeners();
  }

  void dismissAll() {
    if (_toasts.isEmpty) return;
    _toasts.clear();
    notifyListeners();
  }
}
