import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

enum _SurfaceKind { inline, sidePanel }

final controlComponent = WidgetbookComponent(
  name: 'Control',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _control),
    WidgetbookUseCase(name: 'Interaction state', builder: _controlState),
  ],
);

final noticeComponent = WidgetbookComponent(
  name: 'Notice',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _noticePlayground),
    WidgetbookUseCase(name: 'Tone matrix', builder: _notices),
  ],
);

final expanderComponent = WidgetbookComponent(
  name: 'Expander',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _expander),
    WidgetbookUseCase(name: 'Expanded / collapsed', builder: _expanderStates),
  ],
);

final commandComponent = WidgetbookComponent(
  name: 'Commands',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _commandPlayground),
    WidgetbookUseCase(name: 'Collect input', builder: _commandInputPlayground),
  ],
);

final hotkeyComponent = WidgetbookComponent(
  name: 'Hotkeys',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _hotkeys)],
);

final surfaceHostComponent = WidgetbookComponent(
  name: 'Surface Host',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _surfacePlayground),
  ],
);

Widget _control(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Custom interactive region',
  );
  final semanticLabel = context.knobs.string(
    label: 'Accessibility · Semantic label',
    initialValue: 'Custom interactive region',
  );
  final autofocus = context.knobs.boolean(
    label: 'Behaviour · Autofocus',
    initialValue: false,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );

  return preview(
    CarpenterControl(
      semanticLabel: semanticLabel,
      autofocus: autofocus,
      onTap: enabled ? () {} : null,
      builder: (context, state) {
        final theme = CarpenterTheme.of(context);
        final background = state.pressed
            ? theme.overlay.selected
            : state.hovered || state.focused
            ? theme.overlay.hovered
            : theme.surface.subtle;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: theme.overlay.border),
            borderRadius: BorderRadius.circular(context.units(.5.rem)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.units(1.rem),
              vertical: context.units(.75.rem),
            ),
            child: CarpenterText.body(
              '$label\nenabled=${state.enabled} hovered=${state.hovered} focused=${state.focused} pressed=${state.pressed}',
            ),
          ),
        );
      },
    ),
  );
}

Widget _controlState(BuildContext context) => preview(
  CarpenterControl(
    semanticLabel: 'Hover, focus, press with mouse or keyboard',
    onTap: () {},
    builder: (context, state) {
      final theme = CarpenterTheme.of(context);
      final background = state.pressed
          ? theme.overlay.selected
          : state.hovered || state.focused
          ? theme.overlay.hovered
          : theme.surface.subtle;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: theme.overlay.border),
          borderRadius: BorderRadius.circular(context.units(.5.rem)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.units(1.rem),
            vertical: context.units(.75.rem),
          ),
          child: CarpenterText.body(
            'enabled=${state.enabled}  hovered=${state.hovered}  focused=${state.focused}  pressed=${state.pressed}',
          ),
        ),
      );
    },
  ),
);

Widget _noticePlayground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Statement mismatch',
  );
  final message = context.knobs.string(
    label: 'Content · Message',
    initialValue:
        'Existing data remains visible while the refresh can be retried.',
  );
  final tone = context.knobs.object.segmented(
    label: 'Appearance · Tone',
    options: CarpenterNoticeTone.values,
    initialOption: CarpenterNoticeTone.warning,
    labelBuilder: (value) => value.name,
  );
  final showAction = context.knobs.boolean(
    label: 'Content · Action',
    initialValue: true,
  );
  final actionLabel = context.knobs.string(
    label: 'Content · Action label',
    initialValue: 'Retry',
  );
  final dismissible = context.knobs.boolean(
    label: 'Behaviour · Dismissible',
    initialValue: true,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 620,
    min: 280,
    max: 900,
    divisions: 31,
  );

  return preview(
    SizedBox(
      width: width,
      child: CarpenterNotice(
        title: title,
        message: message,
        tone: tone,
        action: showAction
            ? CarpenterActionDescriptor(
                id: 'retry',
                label: actionLabel,
                onInvoke: () {},
              )
            : null,
        onClose: dismissible ? () {} : null,
      ),
    ),
  );
}

Widget _notices(BuildContext context) => previewColumn([
  for (final tone in CarpenterNoticeTone.values)
    SizedBox(
      width: context.units(38.75.rem),
      child: CarpenterNotice(
        title: tone.name,
        message:
            'Semantic feedback keeps its meaning in light, dark and high-contrast themes.',
        tone: tone,
      ),
    ),
]);

Widget _expander(BuildContext context) {
  final header = context.knobs.string(
    label: 'Content · Header',
    initialValue: 'Bank requisites',
  );
  final content = context.knobs.string(
    label: 'Content · Body',
    initialValue:
        'Account 40702810900000000001\nBIC 044525225\nCorrespondent account 30101810400000000225',
  );
  final expanded = context.knobs.boolean(
    label: 'State · Initially expanded',
    initialValue: true,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 620,
    min: 280,
    max: 900,
    divisions: 31,
  );

  return preview(
    SizedBox(
      width: width,
      child: CarpenterExpander(
        key: ValueKey(expanded),
        initiallyExpanded: expanded,
        header: CarpenterText.label(
          header,
          emphasis: TypographyEmphasis.strong,
        ),
        content: CarpenterText.body(content),
      ),
    ),
  );
}

Widget _expanderStates(BuildContext context) => previewColumn([
  SizedBox(
    width: context.units(38.75.rem),
    child: CarpenterExpander(
      initiallyExpanded: false,
      header: CarpenterText.label('Collapsed'),
      content: CarpenterText.body('Hidden until the section is opened.'),
    ),
  ),
  SizedBox(
    width: context.units(38.75.rem),
    child: CarpenterExpander(
      initiallyExpanded: true,
      header: CarpenterText.label('Expanded'),
      content: CarpenterText.body('Visible content for comparison.'),
    ),
  ),
]);

Widget _commandPlayground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Save',
  );
  final presentation = context.knobs.object.segmented(
    label: 'Appearance · Presentation',
    options: CarpenterCommandPresentation.values,
    initialOption: CarpenterCommandPresentation.primary,
    labelBuilder: (value) => value.name,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final fail = context.knobs.boolean(
    label: 'Execution · Fail',
    initialValue: false,
  );
  final delay = context.knobs.double.slider(
    label: 'Execution · Delay (ms)',
    initialValue: 700,
    min: 0,
    max: 2000,
    divisions: 20,
  );

  return _CommandPreview(
    title: title,
    presentation: presentation,
    enabled: enabled,
    fail: fail,
    delay: Duration(milliseconds: delay.round()),
  );
}

final class _CommandPreview extends StatefulWidget {
  const _CommandPreview({
    required this.title,
    required this.presentation,
    required this.enabled,
    required this.fail,
    required this.delay,
  });

  final String title;
  final CarpenterCommandPresentation presentation;
  final bool enabled;
  final bool fail;
  final Duration delay;

  @override
  State<_CommandPreview> createState() => _CommandPreviewState();
}

final class _CommandPreviewState extends State<_CommandPreview> {
  late CarpenterCommandController<void> _command = _createCommand();
  String? _result;

  CarpenterCommandController<void> _createCommand() {
    final command = CarpenterCommandController<void>(
      id: 'widgetbook.command',
      title: widget.title,
      presentation: widget.presentation,
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyS, control: true),
      ],
      execute: (_) async {
        await Future<void>.delayed(widget.delay);
        if (widget.fail) throw StateError('Simulated command failure');
        if (mounted) setState(() => _result = 'Completed');
        return const CarpenterCommandResult(message: 'Completed');
      },
    );
    command.setAvailability(
      enabled: widget.enabled,
      disabledReason: widget.enabled ? null : 'Disabled from Widgetbook',
    );
    return command;
  }

  @override
  void didUpdateWidget(_CommandPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.presentation != widget.presentation ||
        oldWidget.fail != widget.fail ||
        oldWidget.delay != widget.delay) {
      _command.dispose();
      _command = _createCommand();
      _result = null;
    } else if (oldWidget.enabled != widget.enabled) {
      _command.setAvailability(
        enabled: widget.enabled,
        disabledReason: widget.enabled ? null : 'Disabled from Widgetbook',
      );
    }
  }

  @override
  void dispose() {
    _command.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => previewColumn([
    CarpenterCommandButton<void>(command: _command, input: null),
    ListenableBuilder(
      listenable: _command,
      builder: (context, _) => CarpenterText.caption(
        'enabled=${_command.value.enabled} execution=${_command.value.execution.name}${_command.value.error == null ? '' : ' error=${_command.value.error}'}${_result == null ? '' : ' result=$_result'}',
      ),
    ),
  ]);
}

Widget _commandInputPlayground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Command title',
    initialValue: 'Reject',
  );
  final initialReason = context.knobs.string(
    label: 'Content · Initial input',
    initialValue: 'Incorrect requisites',
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  return _CommandInputPreview(
    title: title,
    initialReason: initialReason,
    enabled: enabled,
  );
}

final class _CommandInputPreview extends StatefulWidget {
  const _CommandInputPreview({
    required this.title,
    required this.initialReason,
    required this.enabled,
  });

  final String title;
  final String initialReason;
  final bool enabled;

  @override
  State<_CommandInputPreview> createState() => _CommandInputPreviewState();
}

final class _CommandInputPreviewState extends State<_CommandInputPreview> {
  late final TextEditingController _reason = TextEditingController(
    text: widget.initialReason,
  );
  String? _lastInput;
  late CarpenterCommandController<String> _reject = _createCommand();

  CarpenterCommandController<String> _createCommand() {
    final command = CarpenterCommandController<String>(
      id: 'approval.reject',
      title: widget.title,
      presentation: CarpenterCommandPresentation.danger,
      execute: (input) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _lastInput = input);
        return CarpenterCommandResult(message: input);
      },
    );
    command.setAvailability(
      enabled: widget.enabled,
      disabledReason: widget.enabled ? null : 'Disabled from Widgetbook',
    );
    return command;
  }

  @override
  void didUpdateWidget(_CommandInputPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialReason != widget.initialReason) {
      _reason.text = widget.initialReason;
    }
    if (oldWidget.title != widget.title) {
      _reject.dispose();
      _reject = _createCommand();
    } else if (oldWidget.enabled != widget.enabled) {
      _reject.setAvailability(
        enabled: widget.enabled,
        disabledReason: widget.enabled ? null : 'Disabled from Widgetbook',
      );
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    _reject.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: context.units(32.5.rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterInput(controller: _reason, label: 'Reason'),
          SizedBox(height: context.units(.75.rem)),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CarpenterCommandInputButton<String>(
              command: _reject,
              inputBuilder: (_) async {
                final value = _reason.text.trim();
                return value.isEmpty ? null : value;
              },
            ),
          ),
          if (_lastInput != null) ...[
            SizedBox(height: context.units(.75.rem)),
            CarpenterText.caption('Last input: $_lastInput'),
          ],
        ],
      ),
    ),
  );
}

Widget _hotkeys(BuildContext context) {
  final platform = context.knobs.object.segmented(
    label: 'Platform · Target',
    options: TargetPlatform.values,
    initialOption: TargetPlatform.macOS,
    labelBuilder: (value) => value.name,
  );
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Open command palette',
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final command = CarpenterCommandController<void>(
    id: 'palette.open',
    title: title,
    shortcuts: const [
      SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true),
    ],
    initialState: CarpenterCommandState(enabled: enabled),
  );
  return preview(
    SizedBox(
      width: context.units(38.75.rem),
      child: CarpenterHotkeyScope(
        platform: platform,
        commands: [command],
        child: CarpenterHotkeyDisplay(title: '$title · ${platform.name}'),
      ),
    ),
  );
}

Widget _surfacePlayground(BuildContext context) {
  final kind = context.knobs.object.segmented(
    label: 'Surface · Kind',
    options: _SurfaceKind.values,
    initialOption: _SurfaceKind.sidePanel,
    labelBuilder: (value) => switch (value) {
      _SurfaceKind.inline => 'Inline',
      _SurfaceKind.sidePanel => 'Side panel',
    },
  );
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Inspector',
  );
  final body = context.knobs.string(
    label: 'Content · Body',
    initialValue:
        'The surface API adapts between wide and narrow viewport profiles.',
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Host width',
    initialValue: 900,
    min: 300,
    max: 1200,
    divisions: 30,
  );
  return _SurfacePreview(kind: kind, title: title, body: body, width: width);
}

final class _SurfacePreview extends StatefulWidget {
  const _SurfacePreview({
    required this.kind,
    required this.title,
    required this.body,
    required this.width,
  });

  final _SurfaceKind kind;
  final String title;
  final String body;
  final double width;

  @override
  State<_SurfacePreview> createState() => _SurfacePreviewState();
}

final class _SurfacePreviewState extends State<_SurfacePreview> {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    height: context.units(30.rem),
    child: CarpenterSurfaceHost(
      child: Builder(
        builder: (context) => CarpenterCard(
          child: CarpenterButton(
            label: widget.kind == _SurfaceKind.inline
                ? 'Open inline'
                : 'Open side panel',
            onInvoke: () => unawaited(
              widget.kind == _SurfaceKind.inline
                  ? context.surfaces.openInline<void>(_panel)
                  : context.surfaces.openSidePanel<void>(_panel),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _panel(BuildContext context) => ColoredBox(
    color: CarpenterTheme.of(context).overlay.background,
    child: Padding(
      padding: EdgeInsets.all(context.units(context.units(.09375.rem).rem)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterText.title(
            widget.title,
            emphasis: TypographyEmphasis.strong,
          ),
          SizedBox(height: context.units(.75.rem)),
          CarpenterText.body(widget.body),
          const Spacer(),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: CarpenterButton(
              label: 'Close',
              onInvoke: () => CarpenterSurfaceCloseScope.maybeClose(context),
            ),
          ),
        ],
      ),
    ),
  );
}
