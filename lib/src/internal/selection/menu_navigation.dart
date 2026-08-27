final class MenuNavigationItem<K> {
  const MenuNavigationItem({required this.key, required this.enabled});

  final K key;
  final bool enabled;
}

final class MenuNavigation<K> {
  MenuNavigation([Iterable<MenuNavigationItem<K>> items = const []]) {
    update(items);
  }

  List<MenuNavigationItem<K>> _items = const [];
  K? highlightedKey;

  Iterable<MenuNavigationItem<K>> get enabledItems =>
      _items.where((item) => item.enabled);

  void update(Iterable<MenuNavigationItem<K>> items, {K? preferredKey}) {
    _items = List.unmodifiable(items);
    final retained = highlightedKey;
    if (retained != null &&
        _items.any((item) => item.enabled && item.key == retained)) {
      return;
    }
    highlightedKey =
        preferredKey != null &&
            _items.any((item) => item.enabled && item.key == preferredKey)
        ? preferredKey
        : null;
  }

  K? move(int delta) {
    final enabled = enabledItems.toList(growable: false);
    if (enabled.isEmpty) return highlightedKey = null;
    final current = enabled.indexWhere((item) => item.key == highlightedKey);
    final next = current < 0
        ? (delta > 0 ? 0 : enabled.length - 1)
        : (current + delta) % enabled.length;
    return highlightedKey = enabled[next].key;
  }

  K? first() {
    final enabled = enabledItems;
    return highlightedKey = enabled.isEmpty ? null : enabled.first.key;
  }

  K? last() {
    final enabled = enabledItems;
    return highlightedKey = enabled.isEmpty ? null : enabled.last.key;
  }

  K? highlight(K key) {
    if (_items.any((item) => item.enabled && item.key == key)) {
      highlightedKey = key;
    }
    return highlightedKey;
  }
}
