import 'package:carpenter/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new request cancels the previous lease and only latest stays current', () {
    final gate = CarpenterRequestGate<_Cancellation>(
      createCancellation: _Cancellation.new,
    );

    final first = gate.begin();
    var cancellationObserved = false;
    first.cancellation.addListener(() => cancellationObserved = true);

    final second = gate.begin();

    expect(first.cancellation.isCancelled, isTrue);
    expect(cancellationObserved, isTrue);
    expect(gate.isCurrent(first), isFalse);
    expect(gate.isCurrent(second), isTrue);
    expect(second.generation, greaterThan(first.generation));

    gate.finish(first);
    expect(gate.isCurrent(second), isTrue);

    gate.finish(second);
    expect(gate.active, isNull);
  });

  test('explicit cancellation invalidates the active lease', () {
    final gate = CarpenterRequestGate<_Cancellation>(
      createCancellation: _Cancellation.new,
    );
    final lease = gate.begin();

    gate.cancel();

    expect(lease.cancellation.isCancelled, isTrue);
    expect(gate.isCurrent(lease), isFalse);
    expect(gate.active, isNull);
  });
}

final class _Cancellation extends CarpenterCancellationSignal {}
