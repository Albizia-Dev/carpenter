import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/helpers/labels.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Unlisted { firstValue }

void main() {
  test('known semantic labels preserve curated copy', () {
    expect(semanticValueLabel(ControlSize.xsmall), 'Extra small');
    expect(
      semanticValueLabel(DialogDismissPolicy.outsideAndEscape),
      'Outside and Escape',
    );
  });
  test('new enum values are readable rather than Dart qualified names', () {
    expect(semanticValueLabel(_Unlisted.firstValue), 'First value');
    expect(humanizeIdentifier('URLParser'), 'Url parser');
    expect(humanizeIdentifier('snake_case'), 'Snake case');
    expect(humanizeIdentifier(''), '');
    expect(semanticValueLabel(12), '12');
  });
}
