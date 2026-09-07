import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('inline text edit swaps pencil for check and commits once', (
    tester,
  ) async {
    var value = 'Original';
    var draft = value;
    var editing = false;
    var commitCount = 0;

    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) => CarpenterInlineTextEdit(
            value: value,
            draft: draft,
            editing: editing,
            onDraftChanged: (next) => setState(() => draft = next),
            onEditRequested: () => setState(() {
              draft = value;
              editing = true;
            }),
            onCommitRequested: () => setState(() {
              commitCount += 1;
              value = draft;
              editing = false;
            }),
            onCancelRequested: () => setState(() {
              draft = value;
              editing = false;
            }),
          ),
        ),
      ),
    );

    expect(_icon(GravityIcons.pencil), findsOneWidget);
    expect(_icon(GravityIcons.check), findsNothing);

    await tester.tap(_icon(GravityIcons.pencil));
    await tester.pump();
    expect(_icon(GravityIcons.pencil), findsNothing);
    expect(_icon(GravityIcons.check), findsOneWidget);

    await tester.enterText(find.byType(EditableText), 'Renamed');
    await tester.pump();
    await tester.tap(_icon(GravityIcons.check));
    await tester.pump();

    expect(commitCount, 1);
    expect(value, 'Renamed');
    expect(find.text('Renamed'), findsOneWidget);
    expect(_icon(GravityIcons.pencil), findsOneWidget);
  });

  testWidgets('Escape cancels inline edit without replacing caller draft', (
    tester,
  ) async {
    var value = 'Original';
    var draft = value;
    var editing = false;
    var cancelCount = 0;

    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) => CarpenterInlineTextEdit(
            value: value,
            draft: draft,
            editing: editing,
            onDraftChanged: (next) => setState(() => draft = next),
            onEditRequested: () => setState(() {
              draft = value;
              editing = true;
            }),
            onCommitRequested: () {},
            onCancelRequested: () => setState(() {
              cancelCount += 1;
              editing = false;
            }),
          ),
        ),
      ),
    );

    await tester.tap(_icon(GravityIcons.pencil));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'Uncommitted');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(cancelCount, 1);
    expect(editing, isFalse);
    expect(value, 'Original');
    expect(draft, 'Uncommitted');
    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets('Enter commits an inline text edit once', (tester) async {
    var value = 'Original';
    var draft = value;
    var editing = false;
    var commitCount = 0;

    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) => CarpenterInlineTextEdit(
            value: value,
            draft: draft,
            editing: editing,
            onDraftChanged: (next) => setState(() => draft = next),
            onEditRequested: () => setState(() => editing = true),
            onCommitRequested: () => setState(() {
              commitCount += 1;
              value = draft;
              editing = false;
            }),
            onCancelRequested: () => setState(() => editing = false),
          ),
        ),
      ),
    );

    await tester.tap(_icon(GravityIcons.pencil));
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'Entered');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(commitCount, 1);
    expect(value, 'Entered');
  });
}

Finder _icon(CarpenterIconSource icon) => find.byWidgetPredicate(
  (widget) => widget is CarpenterIconButton && widget.icon == icon,
);
