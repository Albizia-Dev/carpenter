import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 650.0, 1280.0, 2560.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('header actions stay at top at $width / $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          CarpenterApp(
            child: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Align(
                alignment: Alignment.topCenter,
                child: CarpenterEntityHeader(
                  title:
                      'Основной расчётный счёт организации с длинным названием',
                  subtitle: '••8230',
                  primaryActions: [
                    CarpenterActionDescriptor(
                      id: 'edit',
                      label: 'Редактировать',
                      onInvoke: () {},
                    ),
                  ],
                  secondaryActions: [
                    CarpenterActionDescriptor(
                      id: 'archive',
                      label: 'В архив',
                      onInvoke: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final header = tester.getRect(find.byType(CarpenterPageHeader));
        final actions = tester.getRect(find.byType(CarpenterToolbar));
        expect(actions.top, header.top);
        expect(actions.right, lessThanOrEqualTo(header.right));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
