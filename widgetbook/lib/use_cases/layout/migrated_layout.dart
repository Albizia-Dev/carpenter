import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final appFrameComponent = WidgetbookComponent(
  name: 'App Frame',
  useCases: [WidgetbookUseCase(name: 'Desktop and touch', builder: _appFrame)],
);

final tabsLayoutComponent = WidgetbookComponent(
  name: 'Tabs Layout',
  useCases: [WidgetbookUseCase(name: 'Adaptive', builder: (_) => const _TabsLayoutPreview())],
);

final restorableSplitComponent = WidgetbookComponent(
  name: 'Restorable Split',
  useCases: [WidgetbookUseCase(name: 'Adaptive and resizable', builder: (_) => const _SplitPreview())],
);

Widget _appFrame(BuildContext context) => previewColumn([
  SizedBox(
    width: 760,
    height: 260,
    child: CarpenterAppFrame(
      targetPlatform: TargetPlatform.macOS,
      topPanelBuilder: (context, panel) => CarpenterTopPanel(title: panel.isDesktop ? 'Desktop frame' : 'Touch frame', subtitle: panel.targetPlatform.name),
      child: const Center(child: CarpenterText.body('Application content')),
    ),
  ),
  SizedBox(
    width: 390,
    height: 260,
    child: CarpenterAppFrame(
      targetPlatform: TargetPlatform.android,
      topPanelBuilder: (context, panel) => CarpenterTopPanel(title: 'Touch frame', subtitle: panel.targetPlatform.name),
      child: const Center(child: CarpenterText.body('Same frame contract')),
    ),
  ),
]);

final class _TabsLayoutPreview extends StatefulWidget {
  const _TabsLayoutPreview();
  @override
  State<_TabsLayoutPreview> createState() => _TabsLayoutPreviewState();
}

final class _TabsLayoutPreviewState extends State<_TabsLayoutPreview> {
  String _tab = 'general';
  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: 880,
      height: 360,
      child: CarpenterTabsLayout<String>(
        value: _tab,
        onChanged: (value) => setState(() => _tab = value),
        tabs: [
          CarpenterLayoutTab(value: 'general', label: 'General', badge: '4', builder: (_) => const CarpenterCard(child: CarpenterText.body('General settings'))),
          CarpenterLayoutTab(value: 'finance', label: 'Finance', builder: (_) => const CarpenterCard(child: CarpenterText.body('Finance settings'))),
          CarpenterLayoutTab(value: 'audit', label: 'Audit', builder: (_) => const CarpenterCard(child: CarpenterText.body('Audit trail'))),
        ],
      ),
    ),
  );
}

final class _SplitPreview extends StatefulWidget {
  const _SplitPreview();
  @override
  State<_SplitPreview> createState() => _SplitPreviewState();
}

final class _SplitPreviewState extends State<_SplitPreview> {
  late final CarpenterMemoryRestorationStore _store = CarpenterMemoryRestorationStore();
  late final CarpenterPageRestorationController _restoration = CarpenterPageRestorationController(pageId: const CarpenterPageId('widgetbook.split'), store: _store);

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: 980,
      height: 420,
      child: CarpenterAdaptiveSplitLayout(
        restoration: _restoration,
        primary: const CarpenterCard(child: CarpenterText.body('Navigation / list')),
        secondary: const CarpenterCard(child: CarpenterText.body('Primary work area')),
        inspector: const SizedBox(width: 220, child: CarpenterCard(child: CarpenterInspector(value: {'status': 'ready', 'owner': 'Nikolai'}))),
      ),
    ),
  );
}
