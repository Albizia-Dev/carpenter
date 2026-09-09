import 'dart:ui' show SemanticsAction;
import 'package:carpenter/carpenter.dart';
import 'package:carpenter/src/internal/date/calendar_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

Finder action(String label) => find.byWidgetPredicate(
  (widget) => widget is CarpenterIconButton && widget.semanticLabel == label,
);
Finder day(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void main() {
  test(
    'civil calendar handles leap years, short months, bounds and six weeks',
    () {
      expect(
        CalendarModel.addMonths(DateTime(2024, 1, 31), 1),
        DateTime(2024, 2, 29),
      );
      expect(
        CalendarModel.addMonths(DateTime(2025, 1, 31), 1),
        DateTime(2025, 2, 28),
      );
      for (final month in [
        DateTime(2024, 3),
        DateTime(2024, 11),
        DateTime(2026, 9),
      ]) {
        final days = CalendarModel.days(month);
        expect(days, hasLength(42));
        expect(days.map(carpenterFormatDate).toSet(), hasLength(42));
        expect(days.first.weekday, DateTime.monday);
        for (var i = 1; i < days.length; i++) {
          expect(
            days[i],
            DateTime(days[i - 1].year, days[i - 1].month, days[i - 1].day + 1),
          );
        }
      }
      expect(carpenterParseDate('29.02.2025'), isNull);
      expect(carpenterParseDate('29.02.2024'), DateTime(2024, 2, 29));
      expect(carpenterParseTime('24:00'), isNull);
      expect(
        carpenterParseTime('23:59'),
        const CarpenterTime(hour: 23, minute: 59),
      );
    },
  );

  for (final platform in [
    TargetPlatform.linux,
    TargetPlatform.android,
    TargetPlatform.iOS,
  ]) {
    testWidgets(
      '${platform.name}: direct date selection, numeric input, no modal',
      (tester) async {
        DateTime? value = DateTime(2026, 9, 9);
        await tester.pumpWidget(
          carpenterOverlayHarness(
            SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (_, setState) => CarpenterDateInput(
                  value: value,
                  firstDate: DateTime(2026, 9, 5),
                  lastDate: DateTime(2026, 9, 25),
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        );
        expect(
          tester.widget<EditableText>(find.byType(EditableText)).keyboardType,
          TextInputType.number,
        );
        await tester.tap(action('Open date picker'));
        await tester.pumpAndSettle();
        expect(find.byType(CarpenterDialog), findsNothing);
        expect(find.byType(CarpenterCalendar), findsOneWidget);
        await tester.tap(day('04.09.2026'));
        await tester.pump();
        expect(value, DateTime(2026, 9, 9));
        await tester.tap(day('16.09.2026'));
        await tester.pumpAndSettle();
        expect(value, DateTime(2026, 9, 16));
        expect(find.byType(CarpenterCalendar), findsNothing);
        expect(find.text('16.09.2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant({platform}),
    );
  }

  testWidgets('range commits on second selection in either direction', (
    tester,
  ) async {
    CarpenterDateRange? value;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (_, setState) => CarpenterDateRangeInput(
              value: value,
              firstDate: DateTime(2026, 9, 1),
              lastDate: DateTime(2026, 9, 30),
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(action('Open date range picker'));
    await tester.pumpAndSettle();
    await tester.tap(day('20.09.2026'));
    await tester.pump();
    expect(value, isNull);
    expect(find.text('Choose end date'), findsOneWidget);
    await tester.tap(day('10.09.2026'));
    await tester.pumpAndSettle();
    expect(value!.start, DateTime(2026, 9, 10));
    expect(value!.end, DateTime(2026, 9, 20));
    expect(find.byType(CarpenterCalendar), findsNothing);
    await tester.tap(action('Open date range picker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(value, isNull);
  });

  testWidgets('time commits hour and minute without nested popup or Apply', (
    tester,
  ) async {
    CarpenterTime? value = const CarpenterTime(hour: 14, minute: 30);
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 320,
          child: StatefulBuilder(
            builder: (_, setState) => CarpenterTimeInput(
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );
    await tester.tap(action('Open time picker'));
    await tester.pumpAndSettle();
    final hour = find.byWidgetPredicate(
      (widget) =>
          widget is CarpenterButton && widget.semanticLabel == 'Hour 15',
    );
    await tester.tap(hour);
    await tester.pump();
    expect(value!.hour, 14);
    final minute = find.byWidgetPredicate(
      (widget) =>
          widget is CarpenterButton && widget.semanticLabel == 'Minute 35',
    );
    await tester.tap(minute);
    await tester.pumpAndSettle();
    expect(value, const CarpenterTime(hour: 15, minute: 35));
    expect(find.text('15:35'), findsOneWidget);
    expect(find.byType(CarpenterDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Escape cancels range draft and disabling closes an open picker',
    (tester) async {
      var enabled = true;
      late StateSetter update;
      var callbacks = 0;
      await tester.pumpWidget(
        carpenterOverlayHarness(
          SizedBox(
            width: 320,
            child: StatefulBuilder(
              builder: (_, setState) {
                update = setState;
                return CarpenterDateRangeInput(
                  enabled: enabled,
                  value: CarpenterDateRange(
                    start: DateTime(2026, 9, 3),
                    end: DateTime(2026, 9, 8),
                  ),
                  onChanged: (_) => callbacks++,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(action('Open date range picker'));
      await tester.pumpAndSettle();
      await tester.tap(day('10.09.2026'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CarpenterCalendar), findsNothing);
      expect(callbacks, 0);
      await tester.tap(action('Open date range picker'));
      await tester.pumpAndSettle();
      update(() => enabled = false);
      await tester.pumpAndSettle();
      expect(find.byType(CarpenterCalendar), findsNothing);
      expect(callbacks, 0);
    },
  );

  testWidgets(
    'calendar roving keyboard crosses months and honors date bounds',
    (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterCalendar(
            selected: DateTime(2026, 9, 30),
            initialMonth: DateTime(2026, 9),
            firstDate: DateTime(2026, 9, 1),
            lastDate: DateTime(2026, 10, 2),
            onChanged: (value) => chosen = value,
          ),
        ),
      );
      await tester.tap(day('30.09.2026'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, DateTime(2026, 10, 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, DateTime(2026, 10, 2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'calendar exposes selection and a real accessible activation action',
    (tester) async {
      DateTime? chosen;
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterCalendar(
            selected: DateTime(2026, 9, 9),
            onChanged: (value) => chosen = value,
          ),
        ),
      );
      final node = tester.getSemantics(day('10.09.2026'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      expect(chosen, DateTime(2026, 9, 10));
    },
  );

  testWidgets(
    'calendar month and year selection fit narrow RTL at 200 percent',
    (tester) async {
      await tester.pumpWidget(
        carpenterOverlayHarness(
          SizedBox(
            width: 320,
            child: CarpenterCalendar(
              selected: DateTime(2026, 9, 9),
              onChanged: (_) {},
            ),
          ),
          direction: TextDirection.rtl,
          textScale: 2,
        ),
      );
      final header = find.byWidgetPredicate(
        (widget) =>
            widget is CarpenterButton &&
            widget.semanticLabel == 'Choose month and year',
      );
      await tester.tap(header);
      await tester.pump();
      expect(find.text('January'), findsOneWidget);
      await tester.tap(header);
      await tester.pump();
      expect(find.text('2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
