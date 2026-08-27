import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okibi/main.dart';
import 'package:okibi/navigation/app_navigation.dart';
import 'package:okibi/pages/test_pages.dart';
import 'package:yx_navigation_flutter/yx_navigation_flutter.dart';

void main() {
  testWidgets('builds the first empty page through YX Navigation', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(Application), findsOneWidget);
    expect(find.byType(FirstTestPage), findsOneWidget);
    expect(find.byType(SecondTestPage), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('redirects both legacy routes to canonical empty pages', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    var pageContext = tester.element(find.byType(FirstTestPage));
    YxNavigation.navigatorOf(pageContext).push(AppRoutes.legacySecond);
    await tester.pumpAndSettle();

    expect(find.byType(SecondTestPage), findsOneWidget);
    pageContext = tester.element(find.byType(SecondTestPage));

    YxNavigation.navigatorOf(pageContext).push(AppRoutes.legacyFirst);
    await tester.pumpAndSettle();

    expect(find.byType(FirstTestPage), findsOneWidget);
  });
}
