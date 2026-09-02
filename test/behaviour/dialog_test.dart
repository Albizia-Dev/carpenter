import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets(
    'showCarpenterDialog captures local theme and rem and returns value',
    (tester) async {
      int? result;
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
          home: UnitsRoot(
            rem: const Px(18),
            child: CarpenterTheme(
              data: CarpenterThemeData.light(),
              child: Builder(
                builder: (context) => CarpenterButton(
                  label: 'Open typed dialog',
                  onInvoke: () async {
                    result = await showCarpenterDialog<int>(
                      context: context,
                      title: 'Typed dialog',
                      content: const CarpenterText.body('Choose a result'),
                      actionsBuilder: (close) => [
                        CarpenterActionDescriptor(
                          id: 'accept',
                          label: 'Accept',
                          onInvoke: () => close(42),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open typed dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Typed dialog'), findsOneWidget);
      expect(find.text('Choose a result'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(result, 42);
      expect(find.text('Typed dialog'), findsNothing);
    },
  );

  testWidgets('typed dialog ignores delayed close after dismissal', (
    tester,
  ) async {
    CarpenterDialogClose<int>? delayedClose;
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFFFFFFFF),
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, _, _) => builder(context),
        ),
        home: UnitsRoot(
          rem: const Px(16),
          child: CarpenterTheme(
            data: CarpenterThemeData.light(),
            child: Builder(
              builder: (context) => CarpenterButton(
                label: 'Open delayed dialog',
                onInvoke: () {
                  showCarpenterDialog<int>(
                    context: context,
                    title: 'Delayed dialog',
                    content: const CarpenterText.body('Wait for completion'),
                    actionsBuilder: (close) {
                      delayedClose = close;
                      return const [];
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open delayed dialog'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    delayedClose!(42);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Open delayed dialog'), findsOneWidget);
  });

  testWidgets('initial focus and Tab traversal remain trapped', (tester) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterDialog(
          open: true,
          onOpenChanged: (_) {},
          title: 'Confirm',
          initialFocusNode: first,
          content: Column(
            children: [
              CarpenterButton(
                label: 'First',
                focusNode: first,
                onInvoke: _noop,
              ),
              CarpenterButton(
                label: 'Second',
                focusNode: second,
                onInvoke: _noop,
              ),
            ],
          ),
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(second.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(first.hasFocus, isTrue);
  });

  testWidgets('Escape follows policy and restores previous focus', (
    tester,
  ) async {
    final outside = FocusNode();
    addTearDown(outside.dispose);
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterDialog(
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              title: 'Dialog',
              content: const CarpenterText.body('Content'),
              child: CarpenterButton(
                label: 'Open',
                focusNode: outside,
                autofocus: true,
                onInvoke: () => update(() => open = true),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(open, isFalse);
    expect(outside.hasFocus, isTrue);
  });

  testWidgets('escapeOnly policy ignores outside pointer', (tester) async {
    var open = true;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterDialog(
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              title: 'Dialog',
              dismissPolicy: DialogDismissPolicy.escapeOnly,
              content: const SizedBox(width: 100, height: 60),
              child: const SizedBox(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(open, isTrue);
  });

  testWidgets('outsideAndEscape policy dismisses outside pointer', (
    tester,
  ) async {
    var open = true;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterDialog(
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              title: 'Dialog',
              dismissPolicy: DialogDismissPolicy.outsideAndEscape,
              content: const SizedBox(width: 100, height: 60),
              child: const SizedBox(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(open, isFalse);
  });

  testWidgets('nested overlay gets first Escape and dialog semantics remain', (
    tester,
  ) async {
    var dialogOpen = true;
    var popoverOpen = true;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterDialog(
              open: dialogOpen,
              onOpenChanged: (value) => update(() => dialogOpen = value),
              title: 'Layered dialog',
              content: CarpenterPopover(
                open: popoverOpen,
                onOpenChanged: (value) => update(() => popoverOpen = value),
                anchor: const CarpenterText.label('Nested anchor'),
                content: const CarpenterText.body('Nested content'),
              ),
              child: const SizedBox(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Layered dialog'), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(popoverOpen, isFalse);
    expect(dialogOpen, isTrue);
  });
}

void _noop() {}
