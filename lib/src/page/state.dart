import '../application/command.dart';

enum CarpenterLoadingPresentation { topBar, spinner, skeleton, overlay }

enum CarpenterEmptyStateKind { collection, filtered, unavailable }

final class CarpenterEmptyStateDescriptor {
  const CarpenterEmptyStateDescriptor({
    required this.title,
    this.message,
    this.kind = CarpenterEmptyStateKind.collection,
    this.action,
  });
  final String title;
  final String? message;
  final CarpenterEmptyStateKind kind;
  final CarpenterCommand<void>? action;
}

sealed class CarpenterPageState {
  const CarpenterPageState();
}

final class CarpenterPageReady extends CarpenterPageState {
  const CarpenterPageReady();
}

final class CarpenterPageInitialLoading extends CarpenterPageState {
  const CarpenterPageInitialLoading({
    this.presentation = CarpenterLoadingPresentation.spinner,
  });
  final CarpenterLoadingPresentation presentation;
}

final class CarpenterPageRefreshing extends CarpenterPageState {
  const CarpenterPageRefreshing();
}

final class CarpenterPageBlocking extends CarpenterPageState {
  const CarpenterPageBlocking({this.message});
  final String? message;
}

final class CarpenterPageEmpty extends CarpenterPageState {
  const CarpenterPageEmpty(this.descriptor);
  final CarpenterEmptyStateDescriptor descriptor;
}

final class CarpenterPageFailure extends CarpenterPageState {
  const CarpenterPageFailure({
    required this.error,
    this.message,
    this.retryCommand,
  });
  final Object error;
  final String? message;
  final CarpenterCommand<void>? retryCommand;
}

final class CarpenterPageForbidden extends CarpenterPageState {
  const CarpenterPageForbidden({this.reason});
  final String? reason;
}

final class CarpenterPageUnavailable extends CarpenterPageState {
  const CarpenterPageUnavailable({required this.message, this.retryCommand});
  final String message;
  final CarpenterCommand<void>? retryCommand;
}
