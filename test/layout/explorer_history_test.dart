import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explorer history navigates independently from router history', () {
    const initial = CarpenterExplorerHistory<String>(current: 'materials');

    final volume = initial.navigateTo('stage-p').navigateTo('volume-3');
    expect(volume.current, 'volume-3');
    expect(volume.backStack, ['materials', 'stage-p']);
    expect(volume.forwardStack, isEmpty);

    final back = volume.goBack();
    expect(back.current, 'stage-p');
    expect(back.backStack, ['materials']);
    expect(back.forwardStack, ['volume-3']);

    final forward = back.goForward();
    expect(forward.current, 'volume-3');
    expect(forward.backStack, ['materials', 'stage-p']);
    expect(forward.forwardStack, isEmpty);
  });

  test('new navigation clears forward history and duplicate is a no-op', () {
    const initial = CarpenterExplorerHistory<String>(current: 'materials');
    final back = initial.navigateTo('stage-p').goBack();

    expect(identical(back.navigateTo('materials'), back), isTrue);

    final redirected = back.navigateTo('stage-r');
    expect(redirected.current, 'stage-r');
    expect(redirected.forwardStack, isEmpty);
    expect(redirected.backStack, ['materials']);
  });
}
