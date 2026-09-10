import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final document in [true, false]) {
    testWidgets('page state preserves mounted content in document=$document', (
      tester,
    ) async {
      final state = ValueNotifier<CarpenterPageState>(
        const CarpenterPageReady(),
      );
      addTearDown(state.dispose);
      var invoked = 0;
      await tester.pumpWidget(
        CarpenterApp(
          child: ValueListenableBuilder<CarpenterPageState>(
            valueListenable: state,
            builder: (context, current, _) {
              final boundary = CarpenterPageStateBoundary(
                state: current,
                child: _Draft(onInvoke: () => invoked++),
              );
              return document
                  ? SingleChildScrollView(child: boundary)
                  : boundary;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Unsaved draft');
      final element = tester.element(find.byType(EditableText));
      for (final current in [
        const CarpenterPageRefreshing(),
        const CarpenterPageBlocking(message: 'Saving'),
        const CarpenterPageInitialLoading(
          presentation: CarpenterLoadingPresentation.topBar,
        ),
        const CarpenterPageInitialLoading(
          presentation: CarpenterLoadingPresentation.skeleton,
        ),
        const CarpenterPageReady(),
      ]) {
        state.value = current;
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.element(find.byType(EditableText)), same(element));
        expect(
          tester
              .widget<EditableText>(find.byType(EditableText))
              .controller
              .text,
          'Unsaved draft',
        );
        for (final progress in tester.widgetList<CarpenterProgress>(
          find.byType(CarpenterProgress),
        )) {
          expect(progress.value, isNull);
        }
        if (current is CarpenterPageBlocking) {
          await tester.tap(find.text('Apply'), warnIfMissed: false);
          expect(invoked, 0);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .focusNode
                .hasFocus,
            isFalse,
          );
        }
      }
      await tester.tap(find.text('Apply'));
      expect(invoked, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _Draft extends StatefulWidget {
  const _Draft({required this.onInvoke});
  final VoidCallback onInvoke;
  @override
  State<_Draft> createState() => _DraftState();
}

class _DraftState extends State<_Draft> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterPageBody(
    children: [
      CarpenterInput(controller: controller, label: 'Name'),
      CarpenterButton(label: 'Apply', onInvoke: widget.onInvoke),
      const SizedBox(height: 400),
    ],
  );
}
