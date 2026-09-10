import 'package:carpenter/carpenter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

void main() {
  testWidgets('long single-line hints fit without a clipped second line', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    const hint = 'Юрлицо, ИНН, банк, БИК, номер или название счёта';
    await tester.pumpWidget(
      carpenterHarness(
        Center(
          child: SizedBox(
            width: 220,
            child: CarpenterInput(controller: controller, placeholder: hint),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(find.text(hint));
    expect(
      paragraph.size.height,
      lessThanOrEqualTo(tester.getSize(find.byType(EditableText)).height + 1),
    );
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow pagination retains count and localized navigation', (
    tester,
  ) async {
    var selected = 2;
    await tester.pumpWidget(
      carpenterHarness(
        Center(
          child: SizedBox(
            width: 300,
            child: CarpenterPaginationBar(
              page: 2,
              totalPages: 3,
              leading: const Text('Всего: 42'),
              pageLabelBuilder: (page, total) => 'Страница $page из $total',
              previousPageLabel: 'Предыдущая страница',
              nextPageLabel: 'Следующая страница',
              onPageChanged: (page) => selected = page,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Всего: 42'), findsOneWidget);
    expect(find.text('Страница 2 из 3'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Следующая страница'));
    expect(selected, 3);
    expect(tester.takeException(), isNull);
  });
}
