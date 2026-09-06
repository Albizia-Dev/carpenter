import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final applicationRuntimeComponent = WidgetbookComponent(
  name: 'Runtime & Commands',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: (_) => const _RuntimePreview()),
    WidgetbookUseCase(name: 'Raw runtime scope', builder: _rawRuntimeScope),
  ],
);

Widget _rawRuntimeScope(BuildContext context) {
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
      effects: const [CarpenterRefreshCommandEffect({'runtime'})],
      execute: (_) => const CarpenterCommandResult(message: 'Runtime refreshed'),
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
                    CarpenterCommandButton<void>(command: _command, input: null),
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
