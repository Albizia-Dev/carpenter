import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/basic/additional_primitives.dart';
import 'package:carpenter_widgetbook/use_cases/collections/editable_table.dart';
import 'package:carpenter_widgetbook/use_cases/patterns/validation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Widget child, {
    double width = 1100,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Application(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('calendar preview round-trips selection and clearing', (
    tester,
  ) async {
    await mount(tester, const CalendarPreview(), width: 380);
    final calendar = tester.widget<CarpenterCalendar>(
      find.byType(CarpenterCalendar),
    );
    calendar.onChanged(DateTime(2026, 9, 16));
    await tester.pump();
    expect(
      tester.widget<CarpenterCalendar>(find.byType(CarpenterCalendar)).selected,
      DateTime(2026, 9, 16),
    );
    await tester.tap(find.text('Clear selection'));
    await tester.pump();
    expect(find.text('No selected date'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editable table preview owns additions, removal, and totals', (
    tester,
  ) async {
    await mount(tester, const EditableTablePreview(initiallyEmpty: true));
    expect(find.text('No rows'), findsOneWidget);
    await tester.tap(find.text('Add row'));
    await tester.pump();
    expect(find.text('1 draft lines'), findsOneWidget);
    final amount = tester.widget<CarpenterNumberInput>(
      find.byType(CarpenterNumberInput),
    );
    amount.onChanged!(500);
    await tester.pump();
    expect(find.text('500'), findsWidgets);
    await tester.tap(find.text('Remove'));
    // Row activation also listens for double taps; let the tap arena settle.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('No rows'), findsOneWidget);
    expect(find.text('0 draft lines'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('validation preview reports errors and accepts corrected draft', (
    tester,
  ) async {
    await mount(tester, const ValidationPreview());
    await tester.tap(find.text('Validate draft'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Check the form'), findsOneWidget);
    expect(find.textContaining('errors: 1'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Project name');
    await tester.pump();
    await tester.tap(find.text('Validate draft'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Check the form'), findsNothing);
    expect(find.textContaining('errors: 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('async preview loads selectable suggestions without networking', (
    tester,
  ) async {
    await mount(tester, const AsyncAutosuggestPreview());
    await tester.enterText(find.byType(EditableText), 'Materials');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    final autosuggest = tester.widget<CarpenterAutosuggest<String>>(
      find.byType(CarpenterAutosuggest<String>),
    );
    expect(autosuggest.suggestions.map((option) => option.label), [
      'Materials',
    ]);
    autosuggest.onSuggestionSelected!(autosuggest.suggestions.single);
    await tester.pump();
    expect(find.text('Selected: Materials'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('async preview surfaces failure and disposes a pending load', (
    tester,
  ) async {
    await mount(tester, const AsyncAutosuggestPreview(fail: true));
    await tester.enterText(find.byType(EditableText), 'Mat');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(
      tester
          .widget<CarpenterAutosuggest<String>>(
            find.byType(CarpenterAutosuggest<String>),
          )
          .loadState,
      OptionsLoadState.failed,
    );
    await tester.enterText(find.byType(EditableText), 'Planning');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
