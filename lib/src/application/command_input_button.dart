import 'dart:async';

import 'package:flutter/widgets.dart';

import '../components/basic/button/button.dart';
import '../foundation/roles.dart';
import '../foundation/icon_data.dart';
import 'command.dart';

/// Asynchronously collects input for a command immediately before execution;
/// returning `null` cancels that invocation.
typedef CarpenterCommandInputBuilder<I> =
    Future<I?> Function(BuildContext context);

/// Presents a command whose input is collected just before execution.
final class CarpenterCommandInputButton<I> extends StatelessWidget {
  /// Creates a command-backed button that asks [inputBuilder] for fresh input on
  /// each invocation.
  const CarpenterCommandInputButton({
    super.key,
    required this.command,
    required this.inputBuilder,
    this.secondary,
  });

  /// Command whose live availability, presentation, execution state, and title
  /// drive the rendered button.
  final CarpenterCommand<I> command;

  /// Caller-owned asynchronous input collector; a `null` result means the command
  /// is not executed.
  final CarpenterCommandInputBuilder<I> inputBuilder;

  /// Optional presentation override for secondary/outlined emphasis; when absent
  /// the command presentation decides.
  final bool? secondary;

  /// Projects command state into a button, collects input only after activation,
  /// executes through the nearest command-execution scope, and leaves failures to
  /// command state/listeners.
  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<CarpenterCommandState>(
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

      final action = command.toInputAction(context, inputBuilder: inputBuilder);

      return CarpenterButton(
        label: state.execution == CarpenterCommandExecution.executing
            ? '${command.title}…'
            : command.title,
        colorRole: useDanger ? ActionColorRole.danger : ActionColorRole.primary,
        prominence: useDanger || useSecondary
            ? ActionProminence.outlined
            : ActionProminence.high,
        executionPhase: switch (state.execution) {
          CarpenterCommandExecution.idle => ActionExecutionPhase.idle,
          CarpenterCommandExecution.executing => ActionExecutionPhase.running,
          CarpenterCommandExecution.failed => ActionExecutionPhase.failed,
        },
        onInvoke: enabled ? action.onInvoke : null,
      );
    },
  );
}

/// Projects commands that collect input into shared header, menu, and dialog actions.
extension CarpenterCommandInputActionProjection<I> on CarpenterCommand<I> {
  /// Takes a snapshot of current command availability. Rebuild the descriptor
  /// when [CarpenterCommand.state] changes. Input cancellation, an unmounted
  /// [context], or changed availability prevents execution after collection.
  /// Failures during execution remain in command state and executor listeners.
  CarpenterActionDescriptor toInputAction(
    BuildContext context, {
    required CarpenterCommandInputBuilder<I> inputBuilder,
    String? label,
    CarpenterIconSource? icon,
  }) {
    final current = state.value;
    final visible = current.visibility == CarpenterCommandVisibility.visible;
    bool available() =>
        state.value.enabled &&
        state.value.visibility == CarpenterCommandVisibility.visible &&
        state.value.execution != CarpenterCommandExecution.executing;
    var collecting = false;
    Future<void> invoke() async {
      if (collecting || !context.mounted || !available()) return;
      collecting = true;
      try {
        final input = await inputBuilder(context);
        if (input == null || !context.mounted || !available()) return;
        try {
          await context.executeCommand(this, input);
        } catch (_) {
          // Command state and executor listeners already own execution failures.
        }
      } finally {
        collecting = false;
      }
    }

    return CarpenterActionDescriptor(
      id: id,
      label: label ?? title,
      icon: icon,
      visible: visible,
      colorRole: switch (presentation) {
        CarpenterCommandPresentation.danger => ActionColorRole.danger,
        CarpenterCommandPresentation.primary => ActionColorRole.primary,
        _ => ActionColorRole.neutral,
      },
      shortcut: shortcuts.isEmpty ? null : shortcuts.first,
      disabledReason: available() ? null : current.disabledReason,
      onInvoke: available() ? () => unawaited(invoke()) : null,
    );
  }
}
