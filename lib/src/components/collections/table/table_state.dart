import 'package:flutter/foundation.dart';

@immutable
final class CarpenterTableMessages {
  /// Overrides Russian table feedback and selection labels; data state remains caller-owned.
  const CarpenterTableMessages({
    this.initialLoading = 'Загрузка данных…',
    this.refreshing = 'Обновление данных…',
    this.loadingMore = 'Загрузка…',
    this.zero = 'Пока нет данных',
    this.emptyResult = 'Ничего не найдено',
    this.initialError = 'Не удалось загрузить данные',
    this.refreshError =
        'Не удалось обновить данные. Показаны предыдущие значения.',
    this.loadMore = 'Загрузить ещё',
    this.selectAllLoaded = 'Выбрать загруженные строки',
    this.clearLoadedSelection = 'Снять выделение загруженных строк',
  });

  final String initialLoading;
  final String refreshing;
  final String loadingMore;
  final String zero;
  final String emptyResult;
  final String initialError;
  final String refreshError;
  final String loadMore;
  final String selectAllLoaded;
  final String clearLoadedSelection;
}
