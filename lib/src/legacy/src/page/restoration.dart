import 'package:carpenter/src/legacy/src/page/descriptor.dart';

/// A typed key within a page restoration namespace.
final class CarpenterRestorationKey<T> {
  const CarpenterRestorationKey({required this.pageId, required this.name});

  final CarpenterPageId pageId;
  final String name;

  String get storageKey => '${pageId.restorationNamespace}.$name';

  @override
  bool operator ==(Object other) =>
      other is CarpenterRestorationKey<T> && other.storageKey == storageKey;

  @override
  int get hashCode => Object.hash(T, storageKey);
}

abstract interface class CarpenterRestorationStore {
  Future<T?> read<T>(CarpenterRestorationKey<T> key);
  Future<void> write<T>(CarpenterRestorationKey<T> key, T value);
  Future<void> remove(CarpenterRestorationKey<Object?> key);
}

/// Useful for tests, session restoration and storage adapters.
final class CarpenterMemoryRestorationStore
    implements CarpenterRestorationStore {
  CarpenterMemoryRestorationStore([Map<String, Object?>? values])
    : _values = {...?values};

  final Map<String, Object?> _values;

  @override
  Future<T?> read<T>(CarpenterRestorationKey<T> key) async =>
      _values[key.storageKey] as T?;

  @override
  Future<void> write<T>(CarpenterRestorationKey<T> key, T value) async {
    _values[key.storageKey] = value;
  }

  @override
  Future<void> remove(CarpenterRestorationKey<Object?> key) async {
    _values.remove(key.storageKey);
  }
}

/// Namespaced access to a replaceable restoration store.
final class CarpenterPageRestorationController {
  const CarpenterPageRestorationController({
    required this.pageId,
    required this.store,
  });

  final CarpenterPageId pageId;
  final CarpenterRestorationStore store;

  CarpenterRestorationKey<T> key<T>(String name) =>
      CarpenterRestorationKey<T>(pageId: pageId, name: name);

  Future<T?> read<T>(String name) => store.read(key<T>(name));
  Future<void> write<T>(String name, T value) =>
      store.write(key<T>(name), value);
  Future<void> remove(String name) => store.remove(key<Object?>(name));
}
