import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child, {CarpenterThemeData? theme}) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: theme ?? CarpenterThemeData.light(),
      child: const MediaQuery(
        data: MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(child: SizedBox()),
        ),
      ),
    ),
  );

  Widget app(Widget child, {CarpenterThemeData? theme}) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: theme ?? CarpenterThemeData.light(),
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FocusScope(child: Align(child: child)),
        ),
      ),
    ),
  );

  testWidgets('standalone is the neutral non-underlined default', (tester) async {
    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      app(CarpenterLink(label: 'Account', onInvoke: _noop), theme: theme),
    );

    final text = tester.widget<Text>(find.text('Account'));
    final expected = theme.actions.resolve(
      ActionColorRole.neutral,
      ActionProminence.ghost,
      const <WidgetState>{},
    );
    expect(text.style!.color, expected.foreground);
    expect(text.style!.decoration, TextDecoration.none);
  });

  testWidgets('role derives semantic color and automatic underline', (
    tester,
  ) async {
    final theme = CarpenterThemeData.light();
    final cases = <CarpenterLinkRole, (ActionColorRole, TextDecoration)> {
      CarpenterLinkRole.inline: (
        ActionColorRole.utility,
        TextDecoration.underline,
      ),
      CarpenterLinkRole.standalone: (
        ActionColorRole.neutral,
        TextDecoration.none,
      ),
      CarpenterLinkRole.subtle: (
        ActionColorRole.neutral,
        TextDecoration.none,
      ),
      CarpenterLinkRole.prominent: (
        ActionColorRole.primary,
        TextDecoration.none,
      ),
    };

    for (final entry in cases.entries) {
      await tester.pumpWidget(
        app(
          CarpenterLink(
            label: entry.key.name,
            role: entry.key,
            onInvoke: _noop,
          ),
          theme: theme,
        ),
      );
      final text = tester.widget<Text>(find.text(entry.key.name));
      final expected = theme.actions.resolve(
        entry.value.$1,
        ActionProminence.ghost,
        const <WidgetState>{},
      );
      expect(text.style!.color, expected.foreground, reason: entry.key.name);
      expect(text.style!.decoration, entry.value.$2, reason: entry.key.name);
    }
  });

  testWidgets('standalone auto underline appears on keyboard focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        CarpenterLink(
          label: 'Focused account',
          autofocus: true,
          onInvoke: _noop,
        ),
      ),
    );
    await tester.pump();

    final text = tester.widget<Text>(find.text('Focused account'));
    expect(text.style!.decoration, TextDecoration.underline);
  });

  testWidgets('explicit underline policy overrides role default', (tester) async {
    await tester.pumpWidget(
      app(
        CarpenterLink(
          label: 'Inline without underline',
          role: CarpenterLinkRole.inline,
          underline: CarpenterLinkUnderline.none,
          onInvoke: _noop,
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Inline without underline')).style!.decoration,
      TextDecoration.none,
    );

    await tester.pumpWidget(
      app(
        CarpenterLink(
          label: 'Prominent underlined',
          role: CarpenterLinkRole.prominent,
          underline: CarpenterLinkUnderline.always,
          onInvoke: _noop,
        ),
      ),
    );
    expect(
      tester.widget<Text>(find.text('Prominent underlined')).style!.decoration,
      TextDecoration.underline,
    );
  });

  testWidgets('explicit action color overrides role-derived color', (
    tester,
  ) async {
    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      app(
        CarpenterLink(
          label: 'Dangerous destination',
          role: CarpenterLinkRole.subtle,
          colorRole: ActionColorRole.danger,
          onInvoke: _noop,
        ),
        theme: theme,
      ),
    );

    final text = tester.widget<Text>(find.text('Dangerous destination'));
    final expected = theme.actions.resolve(
      ActionColorRole.danger,
      ActionProminence.ghost,
      const <WidgetState>{},
    );
    expect(text.style!.color, expected.foreground);
  });

  testWidgets('link keeps activation and accessibility semantics', (tester) async {
    var invoked = false;
    await tester.pumpWidget(
      app(
        CarpenterLink(
          label: 'Open account',
          semanticLabel: 'Open selected account',
          onInvoke: () => invoked = true,
        ),
      ),
    );

    await tester.tap(find.byType(CarpenterLink));
    expect(invoked, isTrue);
    expect(find.bySemanticsLabel('Open selected account'), findsOneWidget);
  });
}

void _noop() {}
