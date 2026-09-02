import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/layout/semantic_layout.dart';
import 'package:carpenter_widgetbook/use_cases/patterns/page_patterns.dart';
import 'package:carpenter_widgetbook/helpers/layout_viewport.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('page pattern fits the mobile landscape viewport preset', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(
      _harness(
        Builder(
          builder: (context) => layoutViewportFrame(
            context,
            preset: LayoutViewportPreset.mobileLandscape,
            child: buildNetworkCollectionPageDemo(),
          ),
        ),
      ),
    );
    await tester.pump(const Milliseconds(500).toDuration());
    expect(find.text('Invoices'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network application shell composes loaded collection regions', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(_harness(buildInvoiceWorkspaceDemo()));
    await tester.pump(const Milliseconds(500).toDuration());

    expect(find.text('Accounts receivable'), findsOneWidget);
    expect(find.text('INV-2026-0412'), findsOneWidget);
    expect(find.text('Invoices'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network collection preserves rows after refresh failure', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(_harness(buildNetworkCollectionPageDemo()));
    expect(find.text('Loading collection'), findsOneWidget);

    await tester.pump(const Milliseconds(500).toDuration());
    expect(find.text('INV-2026-0412'), findsOneWidget);

    if (find.text('Simulate timeout').evaluate().isEmpty) {
      await tester.tap(find.text('More actions'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Simulate timeout').last);
    await tester.pump();
    expect(find.text('INV-2026-0412'), findsOneWidget);
    expect(find.text('Refreshing collection'), findsOneWidget);

    await tester.pump(const Milliseconds(500).toDuration());
    expect(find.text('INV-2026-0412'), findsOneWidget);
    expect(find.text('The demo service timed out'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network form keeps action content during async save', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(_harness(buildNetworkFormPageDemo()));
    await tester.tap(find.text('Save changes'));
    await tester.pump();
    expect(find.text('Save changes'), findsOneWidget);

    await tester.pump(const Milliseconds(700).toDuration());
    expect(find.text('Save changes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('network master detail keeps selection controlled', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(_harness(buildNetworkMasterDetailPageDemo()));
    await tester.pump(const Milliseconds(500).toDuration());

    await tester.tap(find.textContaining('INV-2026-0412').first);
    await tester.pump();
    expect(find.text('Northwind Logistics'), findsWidgets);
    expect(find.text('Warehouse automation milestone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _useLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _harness(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(size: Size(1200, 900)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Center(
                child: SizedBox(width: 1100, height: 840, child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
