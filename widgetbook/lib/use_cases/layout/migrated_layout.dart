import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final appFrameComponent = WidgetbookComponent(
  name: 'App Frame',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _appFrame),
    WidgetbookUseCase(name: 'Desktop / touch matrix', builder: _appFrameMatrix),
  ],
);

final tabsLayoutComponent = WidgetbookComponent(
  name: 'Tabs Layout',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _tabsLayout)],
);

final restorableSplitComponent = WidgetbookComponent(
  name: 'Restorable Split',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _splitLayout)],
);

Widget _appFrame(BuildContext context) {
  final platform = context.knobs.object.segmented(
    label: 'Platform · Target',
    options: TargetPlatform.values,
    initialOption: TargetPlatform.macOS,
    labelBuilder: (value) => value.name,
  );
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Carpenter application',
  );
  final subtitle = context.knobs.stringOrNull(
    label: 'Content · Subtitle',
    initialValue: 'Operational workspace',
    defaultToNull: false,
  );
  final content = context.knobs.string(
    label: 'Content · Body',
    initialValue: 'Application content',
  );
  final showAction = context.knobs.boolean(
    label: 'Content · Header action',
    initialValue: true,
  );
  final useSafeArea = context.knobs.boolean(
    label: 'Layout · Safe area',
    initialValue: true,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 760,
    min: 320,
    max: 1200,
    divisions: 44,
  );
  final height = context.knobs.double.slider(
    label: 'Layout · Height',
    initialValue: 420,
    min: 220,
    max: 800,
    divisions: 29,
  );

  return preview(
    SizedBox(
      width: width,
      height: height,
      child: CarpenterAppFrame(
        targetPlatform: platform,
        useSafeArea: useSafeArea,
        topPanelBuilder: (context, panel) => CarpenterTopPanel(
          title: title,
          subtitle:
              '${subtitle ?? ''}${subtitle == null ? '' : ' · '}${panel.framePlatform.name} · ${panel.targetPlatform.name}',
          actions: showAction
              ? [
                  CarpenterButton(
                    label: 'Action',
                    size: ControlSize.small,
                    prominence: ActionProminence.ghost,
                    onInvoke: () {},
                  ),
                ]
              : const [],
        ),
        child: Center(child: CarpenterText.body(content)),
      ),
    ),
  );
}

Widget _appFrameMatrix(BuildContext context) => previewColumn([
  SizedBox(
    width: context.units(47.5.rem),
    height: context.units(16.25.rem),
    child: CarpenterAppFrame(
      targetPlatform: TargetPlatform.macOS,
      topPanelBuilder: (context, panel) => CarpenterTopPanel(
        title: 'Desktop frame',
        subtitle: panel.targetPlatform.name,
      ),
      child: const Center(child: CarpenterText.body('Desktop content')),
    ),
  ),
  SizedBox(
    width: context.units(24.375.rem),
    height: context.units(16.25.rem),
    child: CarpenterAppFrame(
      targetPlatform: TargetPlatform.android,
      topPanelBuilder: (context, panel) => CarpenterTopPanel(
        title: 'Touch frame',
        subtitle: panel.targetPlatform.name,
      ),
      child: const Center(child: CarpenterText.body('Touch content')),
    ),
  ),
]);

Widget _tabsLayout(BuildContext context) {
  final orientation = context.knobs.object.segmented(
    label: 'Layout · Orientation',
    options: CarpenterTabsOrientation.values,
    initialOption: CarpenterTabsOrientation.adaptive,
    labelBuilder: (value) => value.name,
  );
  final breakpoint = context.knobs.double.slider(
    label: 'Layout · Vertical breakpoint',
    initialValue: 720,
    min: 320,
    max: 1200,
    divisions: 44,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 880,
    min: 320,
    max: 1200,
    divisions: 44,
  );
  final showBadges = context.knobs.boolean(
    label: 'Content · Badges',
    initialValue: true,
  );
  final financeEnabled = context.knobs.boolean(
    label: 'State · Finance enabled',
    initialValue: true,
  );
  final auditVisible = context.knobs.boolean(
    label: 'State · Audit visible',
    initialValue: true,
  );
  final generalLabel = context.knobs.string(
    label: 'Content · General label',
    initialValue: 'General',
  );

  return _TabsLayoutPreview(
    orientation: orientation,
    breakpoint: breakpoint,
    width: width,
    showBadges: showBadges,
    financeEnabled: financeEnabled,
    auditVisible: auditVisible,
    generalLabel: generalLabel,
  );
}

final class _TabsLayoutPreview extends StatefulWidget {
  const _TabsLayoutPreview({
    required this.orientation,
    required this.breakpoint,
    required this.width,
    required this.showBadges,
    required this.financeEnabled,
    required this.auditVisible,
    required this.generalLabel,
  });

  final CarpenterTabsOrientation orientation;
  final double breakpoint;
  final double width;
  final bool showBadges;
  final bool financeEnabled;
  final bool auditVisible;
  final String generalLabel;

  @override
  State<_TabsLayoutPreview> createState() => _TabsLayoutPreviewState();
}

final class _TabsLayoutPreviewState extends State<_TabsLayoutPreview> {
  String _tab = 'general';

  @override
  void didUpdateWidget(_TabsLayoutPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.auditVisible && _tab == 'audit') _tab = 'general';
    if (!widget.financeEnabled && _tab == 'finance') _tab = 'general';
  }

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: widget.width,
      height: context.units(26.25.rem),
      child: CarpenterTabsLayout<String>(
        value: _tab,
        orientation: widget.orientation,
        verticalBreakpoint: widget.breakpoint,
        onChanged: (value) => setState(() => _tab = value),
        tabs: [
          CarpenterLayoutTab(
            value: 'general',
            label: widget.generalLabel,
            badge: widget.showBadges ? '4' : null,
            builder: (_) => const CarpenterCard(
              child: CarpenterText.body('General settings'),
            ),
          ),
          CarpenterLayoutTab(
            value: 'finance',
            label: 'Finance',
            badge: widget.showBadges ? '12' : null,
            enabled: widget.financeEnabled,
            builder: (_) => const CarpenterCard(
              child: CarpenterText.body('Finance settings'),
            ),
          ),
          CarpenterLayoutTab(
            value: 'audit',
            label: 'Audit',
            visible: widget.auditVisible,
            builder: (_) =>
                const CarpenterCard(child: CarpenterText.body('Audit trail')),
          ),
        ],
      ),
    ),
  );
}

Widget _splitLayout(BuildContext context) {
  final ratio = context.knobs.double.slider(
    label: 'Layout · Initial ratio',
    initialValue: .38,
    min: .1,
    max: .9,
    divisions: 16,
  );
  final breakpoint = context.knobs.double.slider(
    label: 'Layout · Breakpoint',
    initialValue: 840,
    min: 480,
    max: 1200,
    divisions: 36,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 980,
    min: 320,
    max: 1400,
    divisions: 54,
  );
  final resizable = context.knobs.boolean(
    label: 'Behaviour · Resizable',
    initialValue: true,
  );
  final showInspector = context.knobs.boolean(
    label: 'Content · Inspector',
    initialValue: true,
  );
  final narrowRegion = context.knobs.object.segmented(
    label: 'Responsive · Narrow region',
    options: CarpenterSplitNarrowRegion.values,
    initialOption: CarpenterSplitNarrowRegion.primary,
    labelBuilder: (value) => value.name,
  );

  return _SplitPreview(
    key: ValueKey((
      ratio,
      breakpoint,
      width,
      resizable,
      showInspector,
      narrowRegion,
    )),
    ratio: ratio,
    breakpoint: breakpoint,
    width: width,
    resizable: resizable,
    showInspector: showInspector,
    narrowRegion: narrowRegion,
  );
}

final class _SplitPreview extends StatefulWidget {
  const _SplitPreview({
    super.key,
    required this.ratio,
    required this.breakpoint,
    required this.width,
    required this.resizable,
    required this.showInspector,
    required this.narrowRegion,
  });

  final double ratio;
  final double breakpoint;
  final double width;
  final bool resizable;
  final bool showInspector;
  final CarpenterSplitNarrowRegion narrowRegion;

  @override
  State<_SplitPreview> createState() => _SplitPreviewState();
}

final class _SplitPreviewState extends State<_SplitPreview> {
  late final CarpenterMemoryRestorationStore _store =
      CarpenterMemoryRestorationStore();
  late final CarpenterPageRestorationController _restoration =
      CarpenterPageRestorationController(
        pageId: const CarpenterPageId('widgetbook.split'),
        store: _store,
      );

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: widget.width,
      height: context.units(28.75.rem),
      child: CarpenterAdaptiveSplitLayout(
        restoration: _restoration,
        initialRatio: widget.ratio,
        breakpoint: widget.breakpoint,
        resizable: widget.resizable,
        narrowRegion: widget.narrowRegion,
        primary: const CarpenterCard(
          child: CarpenterText.body('Navigation / list'),
        ),
        secondary: const CarpenterCard(
          child: CarpenterText.body('Primary work area'),
        ),
        inspector: widget.showInspector
            ? SizedBox(
                width: context.units(13.75.rem),
                child: CarpenterCard(
                  child: CarpenterInspector(
                    value: {'status': 'ready', 'owner': 'Nikolai'},
                  ),
                ),
              )
            : null,
      ),
    ),
  );
}
