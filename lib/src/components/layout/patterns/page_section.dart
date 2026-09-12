import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/button/button.dart';
import '../../basic/card.dart';
import '../../basic/text.dart';

extension type const CarpenterPageSectionId(String value) {}

/// Semantic purpose of a page section inside a larger task composition.
///
/// The role controls default presentation and spacing, but never changes the
/// meaning or state ownership of the section child.
enum CarpenterPageSectionRole {
  /// A section whose main child is a collection such as a table, list or tree.
  collection,

  /// A bounded operational pane used while performing or comparing work.
  operation,

  /// A section whose main child is a form or field group.
  form,

  /// A neutral semantic grouping of related content.
  group,
}

/// Visual treatment applied to a [CarpenterPageSection].
enum CarpenterPageSectionPresentation {
  /// Resolve presentation from the section role and current nesting context.
  automatic,

  /// Keep the section on the parent surface without an additional container.
  flat,

  /// Give the section an explicit bordered panel surface.
  panel,

  /// Give the section a quiet surface without a border.
  subtle,
}

/// A semantic page section that participates in nested task composition.
///
/// Page sections are intentionally capable of containing other sections. The
/// automatic presentation rule prevents operation panels from becoming cards
/// inside cards: the outer operation section owns the panel and nested
/// automatic sections stay flat. Collection, form and group sections are flat
/// by default, so nesting expresses information hierarchy without accumulating
/// decorative chrome.
final class CarpenterPageSection extends StatefulWidget {
  /// Creates a semantic section with optional local navigation, tools,
  /// attention content and footer.
  const CarpenterPageSection({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.description,
    this.actions = const [],
    this.navigation,
    this.toolbar,
    this.attention,
    this.footer,
    this.role = CarpenterPageSectionRole.group,
    this.presentation = CarpenterPageSectionPresentation.automatic,
    this.fillAvailable = false,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  /// Stable semantic identifier for restoration and section addressing.
  final CarpenterPageSectionId id;

  /// Visible section heading.
  final String title;

  /// Optional supporting text shown directly below the heading.
  final String? description;

  /// Main section content. It may itself be another semantic section.
  final Widget child;

  /// Actions aligned with the section heading.
  final List<Widget> actions;

  /// Optional local navigation such as tabs or a segmented mode selector.
  final Widget? navigation;

  /// Optional local toolbar such as search, filters or view controls.
  final Widget? toolbar;

  /// Optional attention content shown before the main child.
  final Widget? attention;

  /// Optional local footer shown after the main child.
  final Widget? footer;

  /// Semantic purpose used to resolve the automatic visual treatment.
  final CarpenterPageSectionRole role;

  /// Requested surface treatment for this section.
  final CarpenterPageSectionPresentation presentation;

  /// Whether the main child should consume remaining bounded section height.
  ///
  /// This is useful for scroll-owning collections and operational panes. In an
  /// unbounded document flow the child keeps its intrinsic height instead.
  final bool fillAvailable;

  /// Whether the section exposes a local collapse/expand action.
  final bool collapsible;

  /// Initial expanded state used when [collapsible] is enabled.
  final bool initiallyExpanded;

  /// Creates the mutable expansion state for this section.
  @override
  State<CarpenterPageSection> createState() => _CarpenterPageSectionState();
}

final class _CarpenterPageSectionState extends State<CarpenterPageSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(CarpenterPageSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final tightGap = context.units(theme.spacing.small) / 2;
    final chromeGap = context.units(theme.spacing.small);
    final contentGap = context.units(theme.spacing.medium);
    final actions = <Widget>[
      ...widget.actions,
      if (widget.collapsible)
        CarpenterButton(
          label: _expanded ? 'Свернуть' : 'Развернуть',
          size: ControlSize.small,
          prominence: ActionProminence.ghost,
          onInvoke: () => setState(() => _expanded = !_expanded),
        ),
    ];

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: CarpenterText.body(
            widget.title,
            emphasis: TypographyEmphasis.strong,
          ),
        ),
        if (widget.description != null) ...[
          SizedBox(height: tightGap),
          CarpenterText.caption(
            widget.description!,
            colorRole: ContentColorRole.secondary,
          ),
        ],
      ],
    );

    final header = LayoutBuilder(
      builder: (context, constraints) {
        if (actions.isEmpty) return heading;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: heading),
            SizedBox(width: contentGap),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: chromeGap,
                runSpacing: chromeGap,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ),
          ],
        );
      },
    );

    final parent = _PageSectionNestingScope.maybeOf(context);
    final effectivePresentation = switch (widget.presentation) {
      CarpenterPageSectionPresentation.automatic =>
        widget.role == CarpenterPageSectionRole.operation &&
                !(parent?.insidePanel ?? false)
            ? CarpenterPageSectionPresentation.panel
            : CarpenterPageSectionPresentation.flat,
      final explicit => explicit,
    };
    final insidePanel = switch (effectivePresentation) {
      CarpenterPageSectionPresentation.panel ||
      CarpenterPageSectionPresentation.subtle => true,
      CarpenterPageSectionPresentation.flat ||
      CarpenterPageSectionPresentation.automatic =>
        parent?.insidePanel ?? false,
    };

    Widget section = LayoutBuilder(
      builder: (context, constraints) {
        final canFill =
            widget.fillAvailable && constraints.maxHeight.isFinite && _expanded;
        final children = <Widget>[header];
        if (_expanded) {
          if (widget.navigation != null) {
            children
              ..add(SizedBox(height: chromeGap))
              ..add(widget.navigation!);
          }
          if (widget.toolbar != null) {
            children
              ..add(SizedBox(height: chromeGap))
              ..add(widget.toolbar!);
          }
          if (widget.attention != null) {
            children
              ..add(SizedBox(height: chromeGap))
              ..add(widget.attention!);
          }
          children.add(SizedBox(height: contentGap));
          children.add(canFill ? Expanded(child: widget.child) : widget.child);
          if (widget.footer != null) {
            children
              ..add(SizedBox(height: contentGap))
              ..add(widget.footer!);
          }
        }
        return Semantics(
          container: true,
          label: widget.title,
          child: _PageSectionNestingScope(
            insidePanel: insidePanel,
            child: Column(
              mainAxisSize: canFill ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );

    final panelPadding = EdgeInsets.all(contentGap);
    section = switch (effectivePresentation) {
      CarpenterPageSectionPresentation.panel => CarpenterCard(
        padding: panelPadding,
        surfaceRole: CarpenterCardSurfaceRole.overlay,
        child: section,
      ),
      CarpenterPageSectionPresentation.subtle => CarpenterCard(
        padding: panelPadding,
        surfaceRole: CarpenterCardSurfaceRole.subtle,
        bordered: false,
        child: section,
      ),
      CarpenterPageSectionPresentation.flat ||
      CarpenterPageSectionPresentation.automatic => section,
    };
    return section;
  }
}

final class _PageSectionNestingScope extends InheritedWidget {
  const _PageSectionNestingScope({
    required this.insidePanel,
    required super.child,
  });

  final bool insidePanel;

  static _PageSectionNestingScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PageSectionNestingScope>();

  @override
  bool updateShouldNotify(_PageSectionNestingScope oldWidget) =>
      insidePanel != oldWidget.insidePanel;
}
