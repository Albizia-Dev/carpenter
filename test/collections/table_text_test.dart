import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('table cell text defaults to one-line ellipsis', (tester) async {
    await tester.pumpWidget(
      carpenterHarness(
        const SizedBox(
          width: 80,
          child: CarpenterTableText.cell(
            'A deliberately long table cell value that must not grow the row',
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.softWrap, isFalse);
  });
}
