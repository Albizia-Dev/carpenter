import 'package:flutter/foundation.dart';

/// Cancellation signal shared by asynchronous Carpenter behaviours.
///
/// Transport integrations may observe this signal and translate cancellation
/// into their own client-specific token without coupling Carpenter to HTTP,
/// repositories, or a state-management package.
class CarpenterCancellationSignal extends ChangeNotifier {
  bool _isCancelled = false;

  /// Whether cancellation has been requested. Cancellation is permanent for
  /// this signal.
  bool get isCancelled => _isCancelled;

  /// Marks the signal cancelled and notifies listeners once. Repeated calls
  /// are no-ops; this does not itself abort a transport.
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    notifyListeners();
  }
}

/// One asynchronous request admitted by a [CarpenterRequestGate].
///
/// A lease remains current until a newer lease starts, the gate is cancelled,
/// or the current lease is finished. Callers should ignore results from leases
/// for which [CarpenterRequestGate.isCurrent] is false.
@immutable
final class CarpenterRequestLease<C extends CarpenterCancellationSignal> {
  const CarpenterRequestLease._({
    required this.generation,
    required this.cancellation,
  });

  /// Monotonically increasing admission number within the owning gate.
  final int generation;

  /// Gate-owned signal for this request. Observe it, but let the gate manage
  /// its disposal.
  final C cancellation;
}

/// Owns the generic "latest request wins" lifecycle used by async UI data.
///
/// Starting a new request cancels the previous one. A late completion never
/// becomes current again, even when the underlying transport cannot actually
/// abort its work. Cancelled request signals stay alive until their own request
/// finishes, so transport adapters may safely observe cancellation across their
/// asynchronous setup. The gate deliberately knows nothing about loading, page,
/// collection, or transport semantics; those remain with the owning feature.
final class CarpenterRequestGate<C extends CarpenterCancellationSignal> {
  /// Creates a request gate. [createCancellation] must return a fresh signal
  /// for each admitted request.
  CarpenterRequestGate({required C Function() createCancellation})
    : _createCancellation = createCancellation;

  final C Function() _createCancellation;
  final Set<CarpenterRequestLease<C>> _live = {};
  CarpenterRequestLease<C>? _active;
  int _generation = 0;

  /// Current admitted lease, or null after cancellation, completion, or
  /// disposal.
  CarpenterRequestLease<C>? get active => _active;

  /// Cancels the previous active lease and admits a new generation with a
  /// fresh cancellation signal. The old signal remains alive until that old
  /// request calls [finish].
  CarpenterRequestLease<C> begin() {
    _cancelActive();
    final lease = CarpenterRequestLease<C>._(
      generation: ++_generation,
      cancellation: _createCancellation(),
    );
    _live.add(lease);
    _active = lease;
    return lease;
  }

  /// Whether [lease] is the identical active lease and its signal has not
  /// been cancelled. Check before applying any asynchronous result or
  /// failure.
  bool isCurrent(CarpenterRequestLease<C> lease) =>
      identical(_active, lease) && !lease.cancellation.isCancelled;

  /// Releases a completed lease and disposes its signal once. Clears [active]
  /// only when finishing the current lease, so an old completion cannot clear
  /// a newer request.
  void finish(CarpenterRequestLease<C> lease) {
    if (identical(_active, lease)) _active = null;
    if (_live.remove(lease)) lease.cancellation.dispose();
  }

  /// Cancels the active lease and clears [active]. Its signal remains alive
  /// until [finish] or [dispose].
  void cancel() => _cancelActive();

  /// Cancels and disposes every still-live request signal, including
  /// superseded requests. The gate must no longer be used after its owner is
  /// disposed.
  void dispose() {
    _active = null;
    for (final lease in _live) {
      lease.cancellation.cancel();
      lease.cancellation.dispose();
    }
    _live.clear();
  }

  void _cancelActive() {
    final active = _active;
    if (active == null) return;
    _active = null;
    active.cancellation.cancel();
  }
}
