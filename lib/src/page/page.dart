import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../application/command.dart';
import '../components/layout/regions/primary_region.dart';
import '../components/layout/regions/region_role.dart';
import '../foundation/theme.dart';
import 'capability.dart';
import 'controller.dart';
import 'descriptor.dart';
import 'scope.dart';
import 'state.dart';
import 'state_boundary.dart';

/// Infrastructure host shared by page patterns.
///
/// The page owns its outer inset and, by default, the single vertical document
/// viewport. Collection/explorer pages whose body already owns a viewport can
/// opt into [CarpenterRegionScrollOwnership.child].
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
    this.scrollOwnership = CarpenterRegionScrollOwnership.region,
    this.headerBehavior = CarpenterPageHeaderBehavior.sticky,
    this.scrollController,
  }) : assert(
         headerBehavior != CarpenterPageHeaderBehavior.scrolls ||
             scrollOwnership == CarpenterRegionScrollOwnership.region,
         'A scrolling page header requires CarpenterPage to own scrolling.',
       );

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
  final CarpenterRegionScrollOwnership scrollOwnership;
  final CarpenterPageHeaderBehavior headerBehavior;
  final ScrollController? scrollController;

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

    Widget primary({required bool bounded}) => Row(
      crossAxisAlignment: bounded
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CarpenterPageStateBoundary(
            state: effectiveState,
            child: body,
          ),
        ),
        if (aside != null) ...[SizedBox(width: gap), aside!],
      ],
    );

    Widget pageContent;
    if (scrollOwnership == CarpenterRegionScrollOwnership.region) {
      final document = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerBehavior == CarpenterPageHeaderBehavior.scrolls &&
              header != null) ...[
            header!,
            SizedBox(height: gap),
          ],
          primary(bounded: false),
        ],
      );
      pageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerBehavior == CarpenterPageHeaderBehavior.sticky &&
              header != null) ...[
            header!,
            SizedBox(height: gap),
          ],
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: document,
            ),
          ),
          if (footer != null) ...[SizedBox(height: gap), footer!],
        ],
      );
    } else {
      pageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[header!, SizedBox(height: gap)],
          Expanded(child: primary(bounded: true)),
          if (footer != null) ...[SizedBox(height: gap), footer!],
        ],
      );
    }

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
                child: pageContent,
              ),
            ),
            if (overlay != null) Positioned.fill(child: overlay!),
          ],
        ),
      ),
    );
    content = CarpenterCommandScope(commands: pageCommands, child: content);
    if (commandBindings.isNotEmpty) {
      content = CarpenterCommandShortcutScope(
        bindings: commandBindings,
        child: content,
      );
    }
    return CarpenterPageScope(
      descriptor: descriptor,
      controller: controller,
      commands: pageCommands,
      capabilities: capabilities,
      child: content,
    );
  }
}
