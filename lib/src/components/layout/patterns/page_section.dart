import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/button/button.dart';
import '../../basic/text.dart';

extension type const CarpenterPageSectionId(String value) {}

/// A semantic page section that participates in the document flow.
///
/// Sections are deliberately surface-neutral. A section is not a card unless
/// the caller explicitly places a [CarpenterCard] (or another surface) inside
/// it. This keeps ordinary record and form pages visually continuous instead
/// of turning every logical group into a separate tile.
final class CarpenterPageSection extends StatefulWidget {
  const CarpenterPageSection({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.description,
    this.actions = const [],
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final CarpenterPageSectionId id;
  final String title;
  final String? description;
  final Widget child;
  final List<Widget> actions;
  final bool collapsible;
  final bool initiallyExpanded;

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
    final tightGap = context.units(theme.spacing.xsmall);
    final actionGap = context.units(theme.spacing.small);
    final contentGap = context.units(theme.spacing.medium);
    final actions = <Widget>[
      ...widget.actions,
      if (widget.collapsible)
        CarpenterButton(
          label: _expanded ? 'Collapse' : 'Expand',
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

    Widget header = LayoutBuilder(
      builder: (context, constraints) {
        if (actions.isEmpty) return heading;
        if (constraints.maxWidth < context.units(32.5.rem)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading,
              SizedBox(height: actionGap),
              Wrap(
                spacing: actionGap,
                runSpacing: actionGap,
                children: actions,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: heading),
            SizedBox(width: contentGap),
            Wrap(
              spacing: actionGap,
              runSpacing: actionGap,
              children: actions,
            ),
          ],
        );
      },
    );

    return Semantics(
      container: true,
      label: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (_expanded) ...[
            SizedBox(height: contentGap),
            widget.child,
          ],
        ],
      ),
    );
  }
}
