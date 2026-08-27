import 'package:flutter/foundation.dart';

@immutable
final class CarpenterTableMessages {
  const CarpenterTableMessages({
    this.initialLoading = 'Loading data',
    this.refreshing = 'Refreshing data',
    this.loadingMore = 'Loading more',
    this.zero = 'No data yet',
    this.emptyResult = 'No matching results',
    this.initialError = 'Data could not be loaded',
    this.refreshError = 'Refresh failed. Existing data may be stale.',
    this.loadMore = 'Load more',
    this.selectAllLoaded = 'Select loaded rows',
    this.clearLoadedSelection = 'Clear loaded row selection',
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
