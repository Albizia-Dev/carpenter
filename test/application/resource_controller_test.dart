import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resource controller cancels and ignores stale requests', () async {
    final first = Completer<int>();
    final second = Completer<int>();
    CarpenterResourceCancellation? firstCancellation;
    var invocation = 0;
    final controller = CarpenterResourceController<int>(
      load: (request) {
        invocation += 1;
        if (invocation == 1) {
          firstCancellation = request.cancellation;
          return first.future;
        }
        return second.future;
      },
    );
    addTearDown(controller.dispose);

    final initial = controller.initialize();
    final refresh = controller.refresh();

    expect(firstCancellation?.isCancelled, isTrue);

    second.complete(2);
    await refresh;
    first.complete(1);
    await initial;

    expect(controller.data, 2);
    expect(controller.value, isA<CarpenterPageReady>());
  });
}
