import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('0.6 messaging facade does not export superseded workspace symbols', () {
    final barrel = File('lib/carpenter.dart').readAsStringSync();
    for (final source in [
      'messenger_workspace.dart',
      'conversation_split_view.dart',
      'voice_controls.dart',
      'attachment_strip.dart',
    ]) {
      expect(barrel, isNot(contains(source)));
      expect(
        File(
          'lib/src/components/layout/patterns/messaging/$source',
        ).existsSync(),
        isFalse,
      );
    }
  });
}
