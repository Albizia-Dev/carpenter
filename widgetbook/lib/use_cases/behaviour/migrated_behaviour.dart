import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final noticeComponent = WidgetbookComponent(
  name: 'Notice',
  useCases: [
    WidgetbookUseCase(name: 'Tones', builder: _notices),
    WidgetbookUseCase(name: 'Responsive actions', builder: _noticeResponsive),
  ],
);

final expanderComponent = WidgetbookComponent(
  name: 'Expander',
  useCases: [WidgetbookUseCase(name: 'Interactive', builder: _expander)],
);

final commandComponent = WidgetbookComponent(
  name: 'Commands',
  useCases: [WidgetbookUseCase(name: 'Execution states', builder: (_) => const _CommandPreview())],
);

final hotkeyComponent = WidgetbookComponent(
  name: 'Hotkeys',
  useCases: [WidgetbookUseCase(name: 'Platform formatting', builder: _hotkeys)],
);

final surfaceHostComponent = WidgetbookComponent(
  name: 'Surface Host',
  useCases: [WidgetbookUseCase(name: 'Inline and side panel', builder: (_) => const _SurfacePreview())],
);

Widget _notices(BuildContext context) => previewColumn([
  for (final tone in CarpenterNoticeTone.values)
    SizedBox(width: 620, child: CarpenterNotice(title: tone.name, message: 'Semantic feedback keeps its meaning in light, dark and high-contrast themes.', tone: tone)),
]);

Widget _noticeResponsive(BuildContext context) => preview(
  SizedBox(
    width: 360,
    child: CarpenterNotice(
      title: 'Statement mismatch',
      message: 'Existing data remains visible while the refresh can be retried.',
      tone: CarpenterNoticeTone.warning,
      action: CarpenterActionDescriptor(id: 'retry', label: 'Retry', onInvoke: () {}),
      onClose: () {},
    ),
  ),
);

Widget _expander(BuildContext context) => preview(
  const SizedBox(
    width: 620,
    child: CarpenterExpander(
      initiallyExpanded: true,
      header: CarpenterText.label('Bank requisites', emphasis: TypographyEmphasis.strong),
      content: CarpenterText.body('Account 40702810900000000001\nBIC 044525225\nCorrespondent account 30101810400000000225'),
    ),
  ),
);

final class _CommandPreview extends StatefulWidget {
  const _CommandPreview();
  @override
  State<_CommandPreview> createState() => _CommandPreviewState();
}

final class _CommandPreviewState extends State<_CommandPreview> {
  late final CarpenterCommandController<void> _save = CarpenterCommandController<void>(
    id: 'record.save',
    title: 'Save',
    presentation: CarpenterCommandPresentation.primary,
    shortcuts: const [SingleActivator(LogicalKeyboardKey.keyS, control: true)],
    execute: (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return const CarpenterCommandResult(message: 'Saved', refreshScopes: {'record'});
    },
  );
  late final CarpenterCommandController<void> _archive = CarpenterCommandController<void>(
    id: 'record.archive',
    title: 'Archive',
    presentation: CarpenterCommandPresentation.danger,
    execute: (_) async => const CarpenterCommandResult(),
  );

  @override
  void dispose() { _save.dispose(); _archive.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => preview(
    Wrap(spacing: 12, runSpacing: 12, children: [
      CarpenterCommandButton<void>(command: _save, input: null),
      CarpenterCommandButton<void>(command: _archive, input: null),
      CarpenterButton(label: _save.value.enabled ? 'Disable save' : 'Enable save', prominence: ActionProminence.outlined, onInvoke: () => setState(() => _save.setAvailability(enabled: !_save.value.enabled, disabledReason: 'Read only'))),
    ]),
  );
}

Widget _hotkeys(BuildContext context) {
  final platform = context.knobs.object.dropdown(
    label: 'Platform',
    options: TargetPlatform.values,
    initialOption: TargetPlatform.macOS,
    labelBuilder: (value) => value.name,
  );
  final command = CarpenterCommandController<void>(
    id: 'palette.open',
    title: 'Open command palette',
    shortcuts: const [SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true)],
  );
  return preview(
    SizedBox(
      width: 620,
      child: CarpenterHotkeyScope(
        platform: platform,
        commands: [command],
        child: const CarpenterHotkeyDisplay(title: 'Keyboard runtime'),
      ),
    ),
  );
}

final class _SurfacePreview extends StatefulWidget {
  const _SurfacePreview();
  @override
  State<_SurfacePreview> createState() => _SurfacePreviewState();
}

final class _SurfacePreviewState extends State<_SurfacePreview> {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 900,
    height: 480,
    child: CarpenterSurfaceHost(
      child: Builder(
        builder: (context) => CarpenterCard(
          child: Wrap(spacing: 12, runSpacing: 12, children: [
            CarpenterButton(
              label: 'Open inline',
              onInvoke: () => unawaited(context.surfaces.openInline<void>((context) => _panel(context, 'Inline surface'))),
            ),
            CarpenterButton(
              label: 'Open side panel',
              prominence: ActionProminence.outlined,
              onInvoke: () => unawaited(context.surfaces.openSidePanel<void>((context) => _panel(context, 'Side panel'))),
            ),
          ]),
        ),
      ),
    ),
  );

  Widget _panel(BuildContext context, String title) => ColoredBox(
    color: CarpenterTheme.of(context).overlay.background,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CarpenterText.title(title, emphasis: TypographyEmphasis.strong),
        const SizedBox(height: 12),
        const CarpenterText.body('The same surface API adapts from centered/side presentation to a full-width narrow viewport.'),
        const Spacer(),
        Align(alignment: AlignmentDirectional.centerEnd, child: CarpenterButton(label: 'Close', onInvoke: () => CarpenterSurfaceCloseScope.maybeClose(context))),
      ]),
    ),
  );
}
