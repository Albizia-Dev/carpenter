import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../application/command.dart';
import '../components/basic/card.dart';
import '../components/basic/text.dart';
import '../components/collections/tabs.dart';
import '../components/layout/page_header.dart';
import '../components/layout/patterns/header_actions.dart';
import '../components/layout/patterns/page_body.dart';
import '../components/layout/patterns/page_section.dart';
import '../foundation/roles.dart';
import '../foundation/theme.dart';
import '../page/capability.dart';
import '../page/controller.dart';
import '../page/descriptor.dart';
import '../page/page.dart';
import '../page/state.dart';

/// Rich entity header retained from the previous record pattern.
final class CarpenterEntityHeader extends StatelessWidget {
  const CarpenterEntityHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.status,
    this.breadcrumbs,
    this.metadata = const [],
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.destructiveActions = const [],
  });
  final String title;
  final String? subtitle;
  final CarpenterPageStatus? status;
  final Widget? breadcrumbs;
  final List<Widget> metadata;
  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;
  final List<CarpenterActionDescriptor> destructiveActions;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    final actions = CarpenterHeaderActions(
      primary: primaryActions,
      secondary: secondaryActions,
      destructive: destructiveActions,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterPageHeader(
          title: title,
          subtitle: subtitle,
          status: status,
          breadcrumbs: breadcrumbs,
          actions: actions.allActions.isEmpty ? null : actions,
        ),
        if (metadata.isNotEmpty) ...[
          SizedBox(height: gap),
          Wrap(spacing: gap, runSpacing: gap, children: metadata),
        ],
      ],
    );
  }
}

final class CarpenterRecordSummary extends StatelessWidget {
  const CarpenterRecordSummary({
    super.key,
    required this.children,
    this.minItemWidth = 180,
  });
  final List<Widget> children;
  final double minItemWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (children.isEmpty) return const SizedBox.shrink();
      final gap = context.units(CarpenterTheme.of(context).spacing.small);
      final columns = (constraints.maxWidth / minItemWidth).floor().clamp(
        1,
        children.length,
      );
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

final class CarpenterRecordMetric extends StatelessWidget {
  const CarpenterRecordMetric({
    super.key,
    required this.label,
    required this.value,
    this.description,
  });
  final String label;
  final Widget value;
  final String? description;
  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return CarpenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterText.caption(label, colorRole: ContentColorRole.secondary),
          SizedBox(height: gap),
          value,
          if (description != null) ...[
            SizedBox(height: gap / 2),
            CarpenterText.caption(
              description!,
              colorRole: ContentColorRole.secondary,
            ),
          ],
        ],
      ),
    );
  }
}

final class CarpenterRecordSection extends StatelessWidget {
  const CarpenterRecordSection({
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
  Widget build(BuildContext context) => CarpenterPageSection(
    id: id,
    title: title,
    description: description,
    actions: actions,
    collapsible: collapsible,
    initiallyExpanded: initiallyExpanded,
    child: child,
  );
}

@immutable
final class CarpenterRecordDetail {
  const CarpenterRecordDetail({
    required this.label,
    required this.value,
    this.description,
  });
  final String label;
  final Widget value;
  final String? description;
}

final class CarpenterRecordDetails extends StatelessWidget {
  const CarpenterRecordDetails({
    super.key,
    required this.details,
    this.labelWidth = 180,
  });
  final List<CarpenterRecordDetail> details;
  final double labelWidth;
  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final detail in details)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final label = CarpenterText.label(
                  detail.label,
                  emphasis: TypographyEmphasis.strong,
                  colorRole: ContentColorRole.secondary,
                );
                final value = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    detail.value,
                    if (detail.description != null)
                      CarpenterText.caption(
                        detail.description!,
                        colorRole: ContentColorRole.secondary,
                      ),
                  ],
                );
                return constraints.maxWidth < labelWidth * 2
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label,
                          SizedBox(height: gap / 2),
                          value,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: labelWidth, child: label),
                          SizedBox(width: gap),
                          Expanded(child: value),
                        ],
                      );
              },
            ),
          ),
      ],
    );
  }
}

final class CarpenterRelatedCollection extends StatelessWidget {
  const CarpenterRelatedCollection({
    super.key,
    required this.title,
    required this.child,
    this.action,
  });
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => CarpenterRecordSection(
    id: CarpenterPageSectionId('related.$title'),
    title: title,
    actions: [if (action != null) action!],
    child: child,
  );
}

@immutable
final class CarpenterTimelineItem {
  const CarpenterTimelineItem({
    required this.id,
    required this.title,
    required this.timestamp,
    this.description,
    this.leading,
  });
  final Object id;
  final String title;
  final DateTime timestamp;
  final String? description;
  final Widget? leading;
}

final class CarpenterTimeline extends StatelessWidget {
  const CarpenterTimeline({
    super.key,
    required this.items,
    this.emptyMessage = 'No events',
  });
  final List<CarpenterTimelineItem> items;
  final String emptyMessage;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: CarpenterText.body(emptyMessage));
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: CarpenterCard(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < context.units(30.rem);
                  final timestamp = CarpenterText.caption(
                    item.timestamp.toLocal().toIso8601String(),
                    colorRole: ContentColorRole.muted,
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.leading != null) ...[
                        item.leading!,
                        SizedBox(width: gap),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CarpenterText.label(
                              item.title,
                              emphasis: TypographyEmphasis.strong,
                            ),
                            if (item.description != null) ...[
                              SizedBox(height: gap / 2),
                              CarpenterText.body(
                                item.description!,
                                colorRole: ContentColorRole.secondary,
                              ),
                            ],
                            if (compact) ...[
                              SizedBox(height: gap / 2),
                              timestamp,
                            ],
                          ],
                        ),
                      ),
                      if (!compact) timestamp,
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

@immutable
final class CarpenterRecordTab<T> {
  const CarpenterRecordTab({
    required this.value,
    required this.label,
    required this.content,
  });
  final T value;
  final String label;
  final Widget content;
}

final class CarpenterRecordTabs<T> extends StatelessWidget {
  const CarpenterRecordTabs({
    super.key,
    required this.value,
    required this.tabs,
    required this.onChanged,
  });
  final T value;
  final List<CarpenterRecordTab<T>> tabs;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final selected =
        tabs.where((tab) => tab.value == value).firstOrNull ?? tabs.first;
    final gap = context.units(CarpenterTheme.of(context).spacing.medium);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterTabs<T>(
          value: selected.value,
          tabs: [
            for (final tab in tabs)
              CarpenterTab(value: tab.value, label: tab.label),
          ],
          onChanged: onChanged,
        ),
        SizedBox(height: gap),
        selected.content,
      ],
    );
  }
}

/// Full record composition, migrated onto the current page infrastructure.
final class CarpenterRecordPage<T> extends StatelessWidget {
  const CarpenterRecordPage({
    super.key,
    required this.descriptor,
    this.controller,
    this.state = const CarpenterPageReady(),
    this.header,
    this.summary,
    this.attention,
    this.sections = const [],
    this.related = const [],
    this.tabs,
    this.timeline,
    this.body,
    this.capabilities = const [],
    this.commands = const [],
    this.commandBindings = const [],
  });
  final CarpenterPageDescriptor descriptor;
  final CarpenterPageController? controller;
  final CarpenterPageState state;
  final Widget? header;
  final Widget? summary;
  final Widget? attention;
  final List<Widget> sections;
  final List<Widget> related;
  final Widget? tabs;
  final Widget? timeline;
  final Widget? body;
  final List<CarpenterPageCapability> capabilities;
  final List<CarpenterCommand<dynamic>> commands;
  final List<CarpenterCommandBinding<dynamic>> commandBindings;

  @override
  Widget build(BuildContext context) {
    assert(descriptor.kind == CarpenterPageKind.record);
    return CarpenterPage(
      descriptor: descriptor,
      controller: controller,
      state: state,
      commands: commands,
      commandBindings: commandBindings,
      capabilities: capabilities,
      header: header ?? CarpenterEntityHeader(title: descriptor.title),
      body:
          body ??
          CarpenterPageBody(
            children: [
              if (summary != null) summary!,
              if (attention != null) attention!,
              ...sections,
              if (tabs != null) tabs!,
              ...related,
              if (timeline != null) timeline!,
            ],
          ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
