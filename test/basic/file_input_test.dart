import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('linked intake forwards accepted files into controlled input', (
    tester,
  ) async {
    final intake = CarpenterFileIntakeController<String>();
    addTearDown(intake.dispose);
    List<CarpenterFileCandidate<String>>? emitted;

    await tester.pumpWidget(
      carpenterHarness(
        CarpenterFileInput<String>(
          value: const [],
          intakeController: intake,
          onChanged: (files) => emitted = files,
        ),
      ),
    );

    intake.accept(const [
      CarpenterFileCandidate<String>(
        id: 'invoice',
        value: 'invoice.pdf',
        name: 'invoice.pdf',
      ),
    ]);
    await tester.pump();

    expect(emitted, isNotNull);
    expect(emitted!.single.name, 'invoice.pdf');
  });

  testWidgets('file input keeps browse action separate from controlled value', (
    tester,
  ) async {
    var browsed = false;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterFileInput<String>(
          value: const [],
          onChanged: (_) {},
          onBrowseRequested: () => browsed = true,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Choose files'));
    expect(browsed, isTrue);
  });

  testWidgets('attachment list delegates retry and remove actions', (
    tester,
  ) async {
    CarpenterAttachment<String>? retried;
    CarpenterAttachment<String>? removed;
    const item = CarpenterAttachment<String>(
      id: 'broken',
      value: 'broken.csv',
      name: 'broken.csv',
      phase: CarpenterAttachmentPhase.failed,
      errorText: 'Network error',
    );

    await tester.pumpWidget(
      carpenterHarness(
        CarpenterAttachmentList<String>(
          items: const [item],
          onRetry: (item) => retried = item,
          onRemove: (item) => removed = item,
        ),
      ),
    );

    expect(find.text('Network error'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Retry broken.csv'));
    await tester.tap(find.bySemanticsLabel('Remove broken.csv'));

    expect(retried?.id, 'broken');
    expect(removed?.id, 'broken');
  });
}
