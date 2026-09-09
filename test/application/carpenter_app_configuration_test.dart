import 'package:carpenter/carpenter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Translations {
  const _Translations(this.locale);
  final Locale locale;
}

class _Delegate extends LocalizationsDelegate<_Translations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<_Translations> load(Locale locale) =>
      SynchronousFuture(_Translations(locale));
  @override
  bool shouldReload(_Delegate old) => false;
}

void main() {
  testWidgets('host builder inherits localization and updated theme units', (
    tester,
  ) async {
    final theme = CarpenterThemeData.dark();
    double? scale;
    Locale? locale;
    CarpenterThemeData? actualTheme;
    Widget app(double rem) => CarpenterApp(
      theme: theme,
      rem: Px(rem),
      locale: const Locale('en', 'GB'),
      supportedLocales: const [Locale('en', 'GB')],
      localizationsDelegates: const [_Delegate()],
      builder: (context, child) {
        scale = context.units(1.rem);
        locale = Localizations.of<_Translations>(
          context,
          _Translations,
        )!.locale;
        actualTheme = CarpenterTheme.of(context);
        return Padding(padding: const EdgeInsets.all(4), child: child);
      },
      child: Builder(
        builder: (context) {
          expect(context.runtime.core, isNotNull);
          return const Text('Hosted page');
        },
      ),
    );
    await tester.pumpWidget(app(18));
    expect(scale, 18);
    expect(locale, const Locale('en', 'GB'));
    expect(actualTheme, same(theme));
    expect(find.text('Hosted page'), findsOneWidget);
    await tester.pumpWidget(app(22));
    expect(scale, 22);
    expect(tester.takeException(), isNull);
  });
}
