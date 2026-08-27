import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'infers enabled state and semantic label without presentation state',
    () {
      void invoke() {}

      final enabled = CarpenterActionDescriptor(
        id: 'save',
        label: 'Save',
        semanticLabel: 'Save document',
        icon: const IconData(0xe001),
        colorRole: ActionColorRole.primary,
        onInvoke: invoke,
      );
      const disabled = CarpenterActionDescriptor(
        id: 'delete',
        label: 'Delete',
        onInvoke: null,
      );

      expect(enabled.isEnabled, isTrue);
      expect(enabled.effectiveSemanticLabel, 'Save document');
      expect(disabled.isEnabled, isFalse);
      expect(disabled.effectiveSemanticLabel, 'Delete');
    },
  );
}
