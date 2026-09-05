import 'package:flutter/foundation.dart';

/// Cancellation signal shared by asynchronous Carpenter behaviours.
///
/// Transport integrations may observe this signal and translate cancellation
/// into their own client-specific token without coupling Carpenter to HTTP,
/// repositories, or a state-management package.
class CarpenterCancellationSignal extends ChangeNotifier {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

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

  final int generation;
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
  CarpenterRequestGate({required C Function() createCancellation})
    : _createCancellation = createCancellation;

  final C Function() _createCancellation;
  final Set<CarpenterRequestLease<C>> _live = {};
  CarpenterRequestLease<C>? _active;
  int _generation = 0;

  CarpenterRequestLease<C>? get active => _active;

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

  bool isCurrent(CarpenterRequestLease<C> lease) =>
      identical(_active, lease) && !lease.cancellation.isCancelled;

  void finish(CarpenterRequestLease<C> lease) {
    if (identical(_active, lease)) _active = null;
    if (_live.remove(lease)) lease.cancellation.dispose();
  }

  void cancel() => _cancelActive();

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
