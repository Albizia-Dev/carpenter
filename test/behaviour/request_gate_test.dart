import 'package:carpenter/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'new request cancels the previous lease and only latest stays current',
    () {
      final gate = CarpenterRequestGate<_Cancellation>(
        createCancellation: _Cancellation.new,
      );
      addTearDown(gate.dispose);

      final first = gate.begin();
      var cancellationObserved = false;
      first.cancellation.addListener(() => cancellationObserved = true);

      final second = gate.begin();

      expect(first.cancellation.isCancelled, isTrue);
      expect(first.cancellation.disposed, isFalse);
      expect(cancellationObserved, isTrue);
      expect(gate.isCurrent(first), isFalse);
      expect(gate.isCurrent(second), isTrue);
      expect(second.generation, greaterThan(first.generation));

      gate.finish(first);
      expect(first.cancellation.disposed, isTrue);
      expect(gate.isCurrent(second), isTrue);

      gate.finish(second);
      expect(second.cancellation.disposed, isTrue);
      expect(gate.active, isNull);
    },
  );

  test(
    'explicit cancellation invalidates but does not dispose active work',
    () {
      final gate = CarpenterRequestGate<_Cancellation>(
        createCancellation: _Cancellation.new,
      );
      addTearDown(gate.dispose);
      final lease = gate.begin();

      gate.cancel();

      expect(lease.cancellation.isCancelled, isTrue);
      expect(lease.cancellation.disposed, isFalse);
      expect(gate.isCurrent(lease), isFalse);
      expect(gate.active, isNull);

      gate.finish(lease);
      expect(lease.cancellation.disposed, isTrue);
    },
  );
}

final class _Cancellation extends CarpenterCancellationSignal {
  bool disposed = false;

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}
