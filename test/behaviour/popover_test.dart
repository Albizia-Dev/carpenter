import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('controlled lifecycle mounts and unmounts content', (
    tester,
  ) async {
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterPopover(
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              anchor: const SizedBox(width: 80, height: 32),
              content: const CarpenterText.body('Popover content'),
              semanticLabel: 'Реквизиты',
            );
          },
        ),
      ),
    );
    expect(find.text('Popover content'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Реквизиты'));
    await tester.pumpAndSettle();
    expect(open, isTrue);
    expect(find.text('Popover content'), findsOneWidget);
    update(() => open = false);
    await tester.pumpAndSettle();
    expect(find.text('Popover content'), findsNothing);
  });

  testWidgets('menu popover owns exactly one framed surface', (tester) async {
    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterPopover(
          open: true,
          onOpenChanged: _ignore,
          anchor: const SizedBox(width: 80, height: 32),
          content: CarpenterMenu(
            items: [
              CarpenterMenuItem(
                action: CarpenterActionDescriptor(
                  id: 'reply',
                  label: 'Ответить',
                  onInvoke: () {},
                ),
              ),
            ],
          ),
        ),
        theme: theme,
      ),
    );
    await tester.pumpAndSettle();

    final framedSurfaces = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .where((box) {
          final decoration = box.decoration;
          return decoration is BoxDecoration &&
              decoration.color == theme.overlay.background &&
              decoration.border != null;
        });
    expect(framedSurfaces, hasLength(1));
  });

  testWidgets('outside click and Escape request dismissal and restore focus', (
    tester,
  ) async {
    final anchorFocus = FocusNode();
    addTearDown(anchorFocus.dispose);
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return Column(
              children: [
                Focus(
                  focusNode: anchorFocus,
                  autofocus: true,
                  child: CarpenterPopover(
                    open: open,
                    onOpenChanged: (value) => update(() => open = value),
                    anchor: const SizedBox(width: 80, height: 32),
                    content: const CarpenterText.body('Focusable content'),
                    semanticLabel: 'Open',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();
    expect(anchorFocus.hasFocus, isTrue);
    await tester.tap(find.bySemanticsLabel('Open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(open, isFalse);
    expect(anchorFocus.hasFocus, isTrue);

    await tester.tap(find.bySemanticsLabel('Open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(open, isFalse);
  });

  testWidgets('nested outside dismissal closes only the top overlay', (
    tester,
  ) async {
    var outerOpen = true;
    var innerOpen = true;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterPopover(
              open: outerOpen,
              onOpenChanged: (value) => update(() => outerOpen = value),
              anchor: const SizedBox(width: 80, height: 32),
              content: CarpenterPopover(
                open: innerOpen,
                onOpenChanged: (value) => update(() => innerOpen = value),
                anchor: const SizedBox(width: 80, height: 32),
                content: const CarpenterText.body('Nested content'),
                semanticLabel: 'Nested',
              ),
              semanticLabel: 'Outer',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nested content'), findsOneWidget);
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(innerOpen, isFalse);
    expect(outerOpen, isTrue);
  });

  testWidgets('overlay follows an anchor moved by scrolling', (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 300,
          height: 240,
          child: SingleChildScrollView(
            controller: scrollController,
            child: const Column(
              children: [
                SizedBox(height: 120),
                CarpenterPopover(
                  open: true,
                  onOpenChanged: _ignore,
                  anchor: SizedBox(width: 80, height: 32),
                  content: CarpenterText.body('Moving overlay'),
                ),
                SizedBox(height: 400),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text('Moving overlay'));
    scrollController.jumpTo(40);
    await tester.pump();
    final after = tester.getTopLeft(find.text('Moving overlay'));
    expect(after.dy, closeTo(before.dy - 40, 0.01));
  });

  testWidgets('supports dark high contrast, RTL, 200% text and resize', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      carpenterOverlayHarness(
        const Align(
          alignment: Alignment.bottomRight,
          child: CarpenterPopover(
            open: true,
            onOpenChanged: _ignore,
            anchor: SizedBox(width: 40, height: 32),
            content: CarpenterText.body('محتوى طويل'),
          ),
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(480, 320));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

void _ignore(bool value) {}
