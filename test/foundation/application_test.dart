import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('provides Carpenter theme and root units', (tester) async {
    late CarpenterThemeData inheritedTheme;
    late double rem;
    final theme = CarpenterThemeData.dark();

    await tester.pumpWidget(
      Application(
        theme: theme,
        home: Builder(
          builder: (context) {
            inheritedTheme = CarpenterTheme.of(context);
            rem = context.units(const Rem(1));
            return const SizedBox.expand();
          },
        ),
      ),
    );

    expect(inheritedTheme, same(theme));
    expect(rem, 16);
  });

  testWidgets('uses a framework page route by default', (tester) async {
    await tester.pumpWidget(
      Application(
        home: const SizedBox.expand(key: Key('home')),
        routes: <String, WidgetBuilder>{
          '/details': (context) => const SizedBox.expand(key: Key('details')),
        },
      ),
    );

    Navigator.of(
      tester.element(find.byKey(const Key('home'))),
    ).pushNamed('/details');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('details')), findsOneWidget);
  });
}
