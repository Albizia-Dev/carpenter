import 'package:carpenter/carpenter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final appHostComponent = WidgetbookComponent(
  name: 'App host',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final rem = context.knobs.double.slider(
          label: 'Root font size',
          initialValue: 16,
          min: 12,
          max: 24,
        );
        final title = context.knobs.string(
          label: 'Title',
          initialValue: 'Hosted application',
        );
        final frame = context.knobs.boolean(
          label: 'Application frame',
          initialValue: false,
        );
        final safeArea = context.knobs.boolean(
          label: 'Safe area',
          initialValue: true,
        );
        return SizedBox(
          height: 360,
          child: CarpenterApp(
            theme: CarpenterTheme.of(context),
            rem: Px(rem),
            title: title,
            locale: const Locale('en', 'US'),
            supportedLocales: const [Locale('en', 'US')],
            useFrame: frame,
            useSafeArea: safeArea,
            builder: (context, child) => child!,
            child: Center(child: CarpenterText.body(title)),
          ),
        );
      },
    ),
  ],
);

final applicationRuntimeComponent = WidgetbookComponent(
  name: 'Runtime & commands',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (_) => const _RuntimePreview(),
    ),
    WidgetbookUseCase(
      name: 'Scenario · Raw runtime scope',
      builder: _rawRuntimeScope,
    ),
  ],
);

Widget _rawRuntimeScope(BuildContext _) {
  final runtime = CarpenterRuntime().extend(
    CarpenterCoreRuntime(platform: defaultTargetPlatform),
  );
  return preview(
    CarpenterRuntimeScope(
      runtime: runtime,
      child: Builder(
        builder: (context) => CarpenterText.body(
          'Runtime capabilities: ${context.runtime.types.length}; platform: ${context.runtime.core.platform.name}',
        ),
      ),
    ),
  );
}

final class _RuntimePreview extends StatefulWidget {
  const _RuntimePreview();

  @override
  State<_RuntimePreview> createState() => _RuntimePreviewState();
}

final class _RuntimePreviewState extends State<_RuntimePreview> {
  late final CarpenterCommandController<void> _command;
  late final CarpenterCommandExecutor _executor;
  String _event = 'No command executed';

  @override
  void initState() {
    super.initState();
    _command = CarpenterCommandController<void>(
      id: 'runtime.refresh',
      title: 'Refresh runtime',
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyR, control: true),
      ],
      effects: const [
        CarpenterRefreshCommandEffect({'runtime'}),
      ],
      execute: (_) =>
          const CarpenterCommandResult(message: 'Runtime refreshed'),
    );
    _executor = CarpenterCommandExecutor(
      listeners: [
        (event) {
          if (!mounted) return;
          setState(() => _event = event.runtimeType.toString());
        },
      ],
    );
  }

  @override
  void dispose() {
    _command.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => preview(
    CarpenterCommandExecutionScope(
      executor: _executor,
      child: CarpenterCommandScope(
        commands: [_command],
        child: CarpenterCommandShortcutScope(
          bindings: [CarpenterCommandBinding(command: _command, input: null)],
          child: CarpenterHost(
            child: Builder(
              builder: (context) => SizedBox(
                width: context.units(32.rem),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CarpenterText.body(
                      'Platform: ${context.runtime.core.platform.name}',
                    ),
                    SizedBox(height: context.units(.75.rem)),
                    CarpenterCommandButton<void>(
                      command: _command,
                      input: null,
                    ),
                    SizedBox(height: context.units(.5.rem)),
                    CarpenterText.caption('Last lifecycle event: $_event'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
