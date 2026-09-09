import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../application/command.dart';
import '../components/layout/page_header.dart';
import '../components/layout/patterns/header_actions.dart';
import '../components/layout/regions/region_role.dart';
import '../foundation/theme.dart';
import '../page/capability.dart';
import '../page/controller.dart';
import '../page/descriptor.dart';
import '../page/page.dart';
import '../page/state.dart';

/// Full-viewport page root for work that is performed in place rather than
/// merely inspected or edited as a document.
///
/// Operation pages own a bounded body viewport and may keep a footer action bar
/// visible while the body changes. This matches work surfaces such as payment
/// reconciliation, allocation, comparison and other two-sided or stateful
/// operational tasks.
final class CarpenterOperationPage extends StatelessWidget {
  /// Creates an operation page around a caller-owned operational body.
  const CarpenterOperationPage({
    super.key,
    required this.descriptor,
    required this.body,
    this.controller,
    this.state = const CarpenterPageReady(),
    this.header,
    this.subtitle,
    this.status,
    this.breadcrumbs,
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.destructiveActions = const [],
    this.navigation,
    this.attention,
    this.footer,
    this.commands = const [],
    this.commandBindings = const [],
    this.capabilities = const [],
  }) : assert(
         descriptor.kind == CarpenterPageKind.operation,
         'CarpenterOperationPage requires CarpenterPageKind.operation.',
       );

  /// Stable page descriptor. Its kind must be [CarpenterPageKind.operation].
  final CarpenterPageDescriptor descriptor;

  /// Main operational workspace. It receives the remaining bounded page height.
  final Widget body;

  /// Optional page controller supplying externally owned page state.
  final CarpenterPageController? controller;

  /// Page state used when no [controller] owns state.
  final CarpenterPageState state;

  /// Optional fully custom page header.
  final Widget? header;

  /// Optional subtitle used by the default header.
  final String? subtitle;

  /// Optional status used by the default header.
  final CarpenterPageStatus? status;

  /// Optional breadcrumbs used by the default header.
  final Widget? breadcrumbs;

  /// Primary actions shown by the default header.
  final List<CarpenterActionDescriptor> primaryActions;

  /// Secondary actions shown by the default header.
  final List<CarpenterActionDescriptor> secondaryActions;

  /// Destructive actions shown by the default header overflow treatment.
  final List<CarpenterActionDescriptor> destructiveActions;

  /// Optional page-level mode navigation shown above the workspace.
  final Widget? navigation;

  /// Optional page-level notice or attention content shown above the workspace.
  final Widget? attention;

  /// Optional persistent action area shown below the workspace.
  final Widget? footer;

  /// Commands exposed through the page command scope.
  final List<CarpenterCommand<dynamic>> commands;

  /// Shortcut bindings exposed through the page command scope.
  final List<CarpenterCommandBinding<dynamic>> commandBindings;

  /// Capabilities exposed through the page scope.
  final List<CarpenterPageCapability> capabilities;

  /// Builds the bounded operation root and persistent footer composition.
  @override
  Widget build(BuildContext context) {
    final actions = CarpenterHeaderActions(
      primary: primaryActions,
      secondary: secondaryActions,
      destructive: destructiveActions,
    );
    return CarpenterPage(
      descriptor: descriptor,
      controller: controller,
      state: state,
      commands: commands,
      commandBindings: commandBindings,
      capabilities: capabilities,
      scrollOwnership: CarpenterRegionScrollOwnership.child,
      header:
          header ??
          CarpenterPageHeader(
            title: descriptor.title,
            subtitle: subtitle,
            status: status,
            breadcrumbs: breadcrumbs,
            actions: actions.allActions.isEmpty ? null : actions,
          ),
      footer: footer,
      body: _OperationPageBody(
        navigation: navigation,
        attention: attention,
        child: body,
      ),
    );
  }
}

/// Adaptive peer layout for two equal operational panes.
///
/// Wide viewports keep both panes visible side by side. Narrow viewports turn
/// the pair into one vertical scroll surface with a stable working extent per
/// pane, avoiding the common failure mode where two scroll-owning collections
/// are placed in an unbounded column.
final class CarpenterOperationPair extends StatelessWidget {
  /// Creates an adaptive pair of peer work panes.
  const CarpenterOperationPair({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = const Rem(65),
    this.stackedPaneHeight = const Rem(42.5),
    this.gap,
    this.semanticLabel = 'Operation workspace',
  });

  /// First peer pane.
  final Widget primary;

  /// Second peer pane.
  final Widget secondary;

  /// Minimum width at which the panes are shown side by side.
  final LengthUnit breakpoint;

  /// Height reserved for each pane when the layout stacks vertically.
  final LengthUnit stackedPaneHeight;

  /// Optional gap override. The local content gap is used by default.
  final LengthUnit? gap;

  /// Semantic label for the peer workspace.
  final String semanticLabel;

  /// Builds the horizontal or vertically stacked peer layout.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(this.gap ?? theme.spacing.medium);
    final breakpoint = context.units(this.breakpoint);
    final stackedPaneHeight = context.units(this.stackedPaneHeight);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= breakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: primary),
                SizedBox(width: gap),
                Expanded(child: secondary),
              ],
            );
          }
          final children = <Widget>[
            SizedBox(height: stackedPaneHeight, child: primary),
            SizedBox(height: gap),
            SizedBox(height: stackedPaneHeight, child: secondary),
          ];
          if (constraints.maxHeight.isFinite) {
            return ListView(padding: EdgeInsets.zero, children: children);
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        },
      ),
    );
  }
}

final class _OperationPageBody extends StatelessWidget {
  const _OperationPageBody({
    required this.navigation,
    required this.attention,
    required this.child,
  });

  final Widget? navigation;
  final Widget? attention;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final chromeGap = context.units(theme.spacing.layoutToolbar);
    final bodyGap = context.units(theme.spacing.layoutSection);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canFill = constraints.maxHeight.isFinite;
        final children = <Widget>[];
        if (navigation != null) children.add(navigation!);
        if (attention != null) {
          if (children.isNotEmpty) children.add(SizedBox(height: chromeGap));
          children.add(attention!);
        }
        if (children.isNotEmpty) children.add(SizedBox(height: bodyGap));
        children.add(canFill ? Expanded(child: child) : child);
        return Column(
          mainAxisSize: canFill ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}
