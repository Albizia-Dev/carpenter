import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../application/command.dart';
import '../foundation/theme.dart';
import 'capability.dart';
import 'controller.dart';
import 'descriptor.dart';
import 'scope.dart';
import 'state.dart';
import 'state_boundary.dart';

/// Infrastructure host shared by page patterns.
final class CarpenterPage extends StatelessWidget {
  const CarpenterPage({
    super.key,
    required this.descriptor,
    required this.body,
    this.controller,
    this.state = const CarpenterPageReady(),
    this.commands = const [],
    this.commandBindings = const [],
    this.capabilities = const [],
    this.header,
    this.footer,
    this.aside,
    this.overlay,
  });

  final CarpenterPageDescriptor descriptor;
  final Widget body;
  final CarpenterPageController? controller;
  final CarpenterPageState state;
  final List<CarpenterCommand<dynamic>> commands;
  final List<CarpenterCommandBinding<dynamic>> commandBindings;
  final List<CarpenterPageCapability> capabilities;
  final Widget? header;
  final Widget? footer;
  final Widget? aside;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final pageController = controller;
    if (pageController != null) {
      return ValueListenableBuilder<CarpenterPageState>(
        valueListenable: pageController,
        builder: (context, current, _) => _build(context, current),
      );
    }
    return _build(context, state);
  }

  Widget _build(BuildContext context, CarpenterPageState pageState) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutSection);
    final permission = descriptor.permission;
    final effectiveState = permission != null && !permission.granted
        ? CarpenterPageForbidden(reason: permission.reason)
        : pageState;
    final pageCommands = <CarpenterCommand<dynamic>>[
      ...?(controller?.pageCommands),
      ...commands,
      for (final binding in commandBindings) binding.command,
    ];
    Widget content = ColoredBox(
      color: theme.surface.base,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(
                  context.units(theme.spacing.layoutPage),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (header != null) ...[header!, SizedBox(height: gap)],
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: CarpenterPageStateBoundary(
                              state: effectiveState,
                              child: body,
                            ),
                          ),
                          if (aside != null) ...[SizedBox(width: gap), aside!],
                        ],
                      ),
                    ),
                    if (footer != null) ...[SizedBox(height: gap), footer!],
                  ],
                ),
              ),
            ),
            if (overlay != null) Positioned.fill(child: overlay!),
          ],
        ),
      ),
    );
    content = CarpenterCommandScope(commands: pageCommands, child: content);
    if (commandBindings.isNotEmpty)
      content = CarpenterCommandShortcutScope(
        bindings: commandBindings,
        child: content,
      );
    return CarpenterPageScope(
      descriptor: descriptor,
      controller: controller,
      commands: pageCommands,
      capabilities: capabilities,
      child: content,
    );
  }
}
