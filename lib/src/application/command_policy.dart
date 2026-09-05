import 'dart:async';

import 'package:flutter/foundation.dart';

import '../foundation/roles.dart';
import 'command.dart';

enum CarpenterCommandFeedbackKind { success, failure }

/// User-facing outcome of the latest command execution observed by a feedback
/// controller.
///
/// The feedback state carries semantic information only. A screen may present
/// it as inline text, a notice, a toast, or not render it at all.
@immutable
final class CarpenterCommandFeedback {
  const CarpenterCommandFeedback({
    required this.commandId,
    required this.title,
    required this.kind,
    this.message,
    this.error,
    this.stackTrace,
    this.undo,
  });

  final String commandId;
  final String title;
  final CarpenterCommandFeedbackKind kind;
  final String? message;
  final Object? error;
  final StackTrace? stackTrace;
  final FutureOr<void> Function()? undo;

  FeedbackColorRole get role => switch (kind) {
    CarpenterCommandFeedbackKind.success => FeedbackColorRole.success,
    CarpenterCommandFeedbackKind.failure => FeedbackColorRole.danger,
  };
}

typedef CarpenterCommandFailureMessageMapper =
    String? Function(CarpenterCommandFailed event);

/// Converts command execution events into one controlled piece of feedback
/// state suitable for business screens.
///
/// Starting any observed command clears previous feedback. Success publishes
/// the command result message when one exists. Failure keeps the original error
/// for diagnostics while exposing only the application-provided mapped message
/// to presentation code; raw technical errors are never turned into UI copy by
/// default.
final class CarpenterCommandFeedbackController
    extends ValueNotifier<CarpenterCommandFeedback?> {
  CarpenterCommandFeedbackController({this.failureMessage}) : super(null);

  final CarpenterCommandFailureMessageMapper? failureMessage;

  void handle(CarpenterCommandExecutionEvent event) {
    switch (event) {
      case CarpenterCommandStarted():
        value = null;
      case CarpenterCommandSucceeded(:final result):
        final message = result.message;
        value = message == null
            ? null
            : CarpenterCommandFeedback(
                commandId: event.commandId,
                title: event.title,
                kind: CarpenterCommandFeedbackKind.success,
                message: message,
                undo: result.undo,
              );
      case CarpenterCommandFailed(:final error, :final stackTrace):
        value = CarpenterCommandFeedback(
          commandId: event.commandId,
          title: event.title,
          kind: CarpenterCommandFeedbackKind.failure,
          message: failureMessage?.call(event),
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  void dismiss() => value = null;
}

typedef CarpenterInvalidationHandler =
    FutureOr<void> Function(Set<String> matchedScopes);
typedef CarpenterInvalidationErrorHandler =
    void Function(
      Object target,
      Set<String> matchedScopes,
      Object error,
      StackTrace stackTrace,
    );

final class _CarpenterInvalidationTarget {
  const _CarpenterInvalidationTarget({
    required this.scopes,
    required this.handler,
  });

  final Set<String> scopes;
  final CarpenterInvalidationHandler handler;
}

/// Registry that turns semantic invalidation scopes into concrete refresh work.
///
/// A target may subscribe to several scopes. When one command succeeds with
/// several matching scopes, that target runs exactly once and receives the
/// subset that matched. Targets are identified by caller-owned objects so they
/// can replace or unregister themselves without Carpenter knowing anything
/// about repositories, HTTP clients, Cubits, or domain services.
final class CarpenterInvalidationRegistry {
  CarpenterInvalidationRegistry({this.onError});

  final CarpenterInvalidationErrorHandler? onError;
  final Map<Object, _CarpenterInvalidationTarget> _targets = {};

  int get targetCount => _targets.length;

  VoidCallback register({
    required Object target,
    required Iterable<String> scopes,
    required CarpenterInvalidationHandler handler,
  }) {
    final normalized = Set<String>.unmodifiable(scopes.where((scope) => scope.isNotEmpty));
    assert(normalized.isNotEmpty, 'At least one invalidation scope is required.');
    _targets[target] = _CarpenterInvalidationTarget(
      scopes: normalized,
      handler: handler,
    );
    return () => unregister(target);
  }

  void unregister(Object target) => _targets.remove(target);

  Future<void> invalidate(Iterable<String> scopes) async {
    final requested = Set<String>.unmodifiable(
      scopes.where((scope) => scope.isNotEmpty),
    );
    if (requested.isEmpty) return;

    final work = <Future<void>>[];
    for (final MapEntry(key: target, value: registration)
        in _targets.entries.toList(growable: false)) {
      final matched = registration.scopes.intersection(requested);
      if (matched.isEmpty) continue;
      work.add(
        _invoke(
          target,
          Set<String>.unmodifiable(matched),
          registration.handler,
        ),
      );
    }
    await Future.wait(work);
  }

  void handle(CarpenterCommandExecutionEvent event) {
    if (event case CarpenterCommandSucceeded(:final refreshScopes)
        when refreshScopes.isNotEmpty) {
      unawaited(invalidate(refreshScopes));
    }
  }

  Future<void> _invoke(
    Object target,
    Set<String> matchedScopes,
    CarpenterInvalidationHandler handler,
  ) async {
    try {
      await Future<void>.sync(() => handler(matchedScopes));
    } catch (error, stackTrace) {
      final errorHandler = onError;
      if (errorHandler != null) {
        errorHandler(target, matchedScopes, error, stackTrace);
        return;
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'carpenter',
          context: ErrorDescription(
            'while invalidating Carpenter data scopes ${matchedScopes.join(', ')}',
          ),
        ),
      );
    }
  }
}
