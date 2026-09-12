import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'goldens/messenger_workspace_test.dart' show host;

void main() {
  testWidgets('Plus header wraps and exposes actual exit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var exits = 0;
    await tester.pumpWidget(host(CarpenterMessengerHost(
      title: 'Мессенджер+', accountLabel: 'Александра Константинопольская',
      onLogout: () => exits++, child: const Center(child: Text('Переписка')),
    ), scale: 2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Выйти'));
    expect(exits, 1);
  });
  testWidgets('attachment and entity actions address the displayed message', (tester) async {
    int? attachment; var entities = 0;
    await tester.pumpWidget(host(Center(child: CarpenterMessageBubble(
      message: const CarpenterMessageItem(id:'a',author:'Анна',text:'Согласуйте',status:'',
        attachmentLabels:['Смета.pdf'],relatedObjectLabel:'Заказ №42',needAnswer:true),
      onAttachment: (index) => attachment = index, onRelatedObject: () => entities++,
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Смета.pdf')); await tester.tap(find.text('Заказ №42'));
    expect(attachment, 0); expect(entities, 1); expect(find.text('Нужен ответ'), findsOneWidget);
  });
}
