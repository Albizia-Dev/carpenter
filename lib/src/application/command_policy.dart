import 'dart:async';

import 'package:flutter/foundation.dart';

import '../foundation/roles.dart';
import 'command.dart';

/// Classifies command feedback as a successful or failed outcome.
enum CarpenterCommandFeedbackKind {
  /// The observed command completed successfully.
  success,

  /// The observed command failed.
  failure,
}

/// User-facing outcome of the latest command execution observed by a feedback
/// controller.
///
/// The feedback state carries semantic information only. A screen may present
/// it as inline text, a notice, a toast, or not render it at all.
@immutable
final class CarpenterCommandFeedback {
  /// Creates feedback for one observed command execution.
  const CarpenterCommandFeedback({
    required this.commandId,
    required this.title,
    required this.kind,
    this.message,
    this.error,
    this.stackTrace,
    this.undo,
  });

  /// Identifier of the command that produced this execution event or feedback item.
  final String commandId;

  /// Human-readable title of the command that produced the feedback.
  final String title;

  /// Semantic outcome kind used to derive feedback presentation.
  final CarpenterCommandFeedbackKind kind;

  /// Optional user-facing success or failure message supplied by application policy.
  final String? message;

  /// Latest execution error retained after a failed invocation, otherwise `null`.
  final Object? error;

  /// Stack trace captured with the original command failure.
  final StackTrace? stackTrace;

  /// Optional asynchronous undo operation associated with a successful command result.
  final FutureOr<void> Function()? undo;

  /// Semantic feedback color role derived from the outcome kind.
  FeedbackColorRole get role => switch (kind) {
    CarpenterCommandFeedbackKind.success => FeedbackColorRole.success,
    CarpenterCommandFeedbackKind.failure => FeedbackColorRole.danger,
  };
}

/// Maps a failed command event to optional user-facing copy without exposing raw
/// technical errors by default.
typedef CarpenterCommandFailureMessageMapper = String? Function(
  CarpenterCommandFailed event,
);

/// Converts command execution events into one controlled piece of feedback
/// state suitable for business screens.
///
/// Starting any observed command clears previous feedback. Success publishes
/// feedback when the result has a message or undo action. Failure keeps the
/// original error for diagnostics while exposing only the application-provided
/// mapped message to presentation code; raw technical errors are never turned
/// into UI copy by default.
final class CarpenterCommandFeedbackController
    extends ValueNotifier<CarpenterCommandFeedback?> {
  /// Creates a feedback controller with an optional failure-to-message mapper and no
  /// initial feedback.
  CarpenterCommandFeedbackController({this.failureMessage}) : super(null);

  /// Optional mapper responsible for converting technical command failures into
  /// user-facing copy.
  final CarpenterCommandFailureMessageMapper? failureMessage;

  /// Reduces one execution lifecycle event into feedback state: starts clear prior
  /// feedback, successes publish message/undo state, and failures retain diagnostics
  /// plus mapped copy.
  void handle(CarpenterCommandExecutionEvent event) {
    switch (event) {
      case CarpenterCommandStarted():
        value = null;
      case CarpenterCommandSucceeded(:final result):
        final message = result.message;
        final undo = result.undo;
        value = message == null && undo == null
            ? null
            : CarpenterCommandFeedback(
                commandId: event.commandId,
                title: event.title,
                kind: CarpenterCommandFeedbackKind.success,
                message: message,
                undo: undo,
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

  /// Clears the currently exposed command feedback without changing command state.
  void dismiss() => value = null;
}

/// Performs caller-owned refresh work for the subset of semantic invalidation scopes
/// matched by a target.
typedef CarpenterInvalidationHandler = FutureOr<void> Function(
  Set<String> matchedScopes,
);

/// Handles an invalidation target failure together with the matched semantic scopes and
/// original stack trace.
typedef CarpenterInvalidationErrorHandler = void Function(
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
  /// Creates an invalidation registry with optional target-error handling and no
  /// registered targets.
  CarpenterInvalidationRegistry({this.onError});

  /// Optional invalidation-error callback; when absent, failures are reported through
  /// Flutter error reporting.
  final CarpenterInvalidationErrorHandler? onError;
  final Map<Object, _CarpenterInvalidationTarget> _targets = {};

  /// Number of currently registered invalidation targets.
  int get targetCount => _targets.length;

  /// Registers or replaces `target` for the normalized nonempty scope set and returns a
  /// callback that unregisters that target.
  VoidCallback register({
    required Object target,
    required Iterable<String> scopes,
    required CarpenterInvalidationHandler handler,
  }) {
    final normalized = Set<String>.unmodifiable(
      scopes.where((scope) => scope.isNotEmpty),
    );
    assert(
      normalized.isNotEmpty,
      'At least one invalidation scope is required.',
    );
    _targets[target] = _CarpenterInvalidationTarget(
      scopes: normalized,
      handler: handler,
    );
    return () => unregister(target);
  }

  /// Removes the registration associated with `target`; unknown targets are ignored.
  void unregister(Object target) => _targets.remove(target);

  /// Runs each matching target at most once for the subset of requested scopes it
  /// registered, waits for all work, and isolates target failures through the
  /// configured error policy.
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

  /// Consumes successful command events and schedules invalidation when their effective
  /// refresh-scope set is nonempty.
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
