import 'package:flutter/widgets.dart';

import '../components/basic/button/button.dart';
import '../foundation/roles.dart';
import 'command.dart';

typedef CarpenterCommandInputBuilder<I> =
    Future<I?> Function(BuildContext context);

/// Presents a command whose input is collected just before execution.
final class CarpenterCommandInputButton<I> extends StatelessWidget {
  const CarpenterCommandInputButton({
    super.key,
    required this.command,
    required this.inputBuilder,
    this.secondary,
  });

  final CarpenterCommand<I> command;
  final CarpenterCommandInputBuilder<I> inputBuilder;
  final bool? secondary;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<CarpenterCommandState>(
        valueListenable: command.state,
        builder: (context, state, _) {
          if (state.visibility == CarpenterCommandVisibility.hidden) {
            return const SizedBox.shrink();
          }
          final enabled =
              state.enabled &&
              state.execution != CarpenterCommandExecution.executing;
          final useDanger =
              command.presentation == CarpenterCommandPresentation.danger;
          final useSecondary =
              secondary ??
              command.presentation == CarpenterCommandPresentation.secondary;

          Future<void> invoke() async {
            final input = await inputBuilder(context);
            if (input == null) return;
            try {
              await command.execute(input);
            } catch (_) {
              // Command state is the canonical error channel.
            }
          }

          return CarpenterButton(
            label: state.execution == CarpenterCommandExecution.executing
                ? '${command.title}…'
                : command.title,
            colorRole: useDanger
                ? ActionColorRole.danger
                : ActionColorRole.primary,
            prominence: useDanger || useSecondary
                ? ActionProminence.outlined
                : ActionProminence.high,
            executionPhase: switch (state.execution) {
              CarpenterCommandExecution.idle => ActionExecutionPhase.idle,
              CarpenterCommandExecution.executing =>
                ActionExecutionPhase.running,
              CarpenterCommandExecution.failed => ActionExecutionPhase.failed,
            },
            onInvoke: enabled ? invoke : null,
          );
        },
      );
}
