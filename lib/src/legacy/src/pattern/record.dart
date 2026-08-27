import 'package:carpenter/src/legacy/src/block/page_blocks.dart';
import 'package:carpenter/src/legacy/src/component/card/carpenter_card.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/page/capability.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/controller.dart';
import 'package:carpenter/src/legacy/src/page/descriptor.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Semantic header for one domain entity.
class CarpenterEntityHeader extends StatelessWidget {
  const CarpenterEntityHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.statuses = const [],
    this.metadata = const [],
    this.primaryAction,
    this.secondaryActions = const [],
    this.overflowAction,
    this.breadcrumbs = const [],
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget> statuses;
  final List<Widget> metadata;
  final Widget? primaryAction;
  final List<Widget> secondaryActions;
  final Widget? overflowAction;
  final List<Widget> breadcrumbs;

  @override
  Widget build(BuildContext context) => CarpenterPageHeader(
    breadcrumbs: breadcrumbs,
    leading: leading,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        if (statuses.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: statuses),
        ],
        if (metadata.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 10, runSpacing: 6, children: metadata),
        ],
      ],
    ),
    subtitle: subtitle,
    commandBar:
        primaryAction == null &&
            secondaryActions.isEmpty &&
            overflowAction == null
        ? null
        : CarpenterActionBar(
            primary: [if (primaryAction != null) primaryAction!],
            secondary: [
              ...secondaryActions,
              if (overflowAction != null) overflowAction!,
            ],
          ),
  );
}

/// Responsive summary of the most important record facts.
class CarpenterRecordSummary extends StatelessWidget {
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
      if (children.isEmpty) {
        return const SizedBox.shrink();
      }
      final columns = (constraints.maxWidth / minItemWidth).floor().clamp(
        1,
        children.length,
      );
      final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// One primary value in a record summary.
class CarpenterRecordMetric extends StatelessWidget {
  const CarpenterRecordMetric({
    super.key,
    required this.label,
    required this.value,
    this.description,
  });

  final String label;
  final Widget value;
  final Widget? description;

  @override
  Widget build(BuildContext context) => CarpenterCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.face
              .type('caption')
              .copyWith(color: context.face.color('text.secondary')),
        ),
        const SizedBox(height: 8),
        DefaultTextStyle.merge(
          style: context.face
              .type('title')
              .copyWith(color: context.face.color('text.primary')),
          child: value,
        ),
        if (description != null) ...[
          const SizedBox(height: 6),
          DefaultTextStyle.merge(
            style: context.face
                .type('caption')
                .copyWith(color: context.face.color('text.secondary')),
            child: description!,
          ),
        ],
      ],
    ),
  );
}

class CarpenterRecordSection extends StatelessWidget {
  const CarpenterRecordSection({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.description,
    this.commands = const [],
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final CarpenterPageSectionId id;
  final String title;
  final String? description;
  final Widget child;
  final List<Widget> commands;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => CarpenterPageSection(
    id: id,
    title: title,
    description: description,
    commands: commands,
    collapsible: collapsible,
    initiallyExpanded: initiallyExpanded,
    child: child,
  );
}

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

class CarpenterRecordDetails extends StatelessWidget {
  const CarpenterRecordDetails({
    super.key,
    required this.details,
    this.labelWidth = 180,
  });

  final List<CarpenterRecordDetail> details;
  final double labelWidth;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final detail in details)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < labelWidth * 2;
              final label = Text(
                detail.label,
                style: context.face
                    .type('label.strong')
                    .copyWith(color: context.face.color('text.secondary')),
              );
              final value = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  detail.value,
                  if (detail.description != null)
                    Text(
                      detail.description!,
                      style: context.face
                          .type('caption')
                          .copyWith(
                            color: context.face.color('text.secondary'),
                          ),
                    ),
                ],
              );
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [label, const SizedBox(height: 4), value],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: labelWidth, child: label),
                        Expanded(child: value),
                      ],
                    );
            },
          ),
        ),
    ],
  );
}

class CarpenterRelatedCollection extends StatelessWidget {
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
    commands: [if (action != null) action!],
    child: child,
  );
}

final class CarpenterTimelineItem {
  const CarpenterTimelineItem({
    required this.id,
    required this.title,
    required this.timestamp,
    this.description,
    this.leading,
  });

  final Object id;
  final Widget title;
  final DateTime timestamp;
  final Widget? description;
  final Widget? leading;
}

class CarpenterTimeline extends StatelessWidget {
  const CarpenterTimeline({
    super.key,
    required this.items,
    this.emptyMessage = 'Событий пока нет',
  });

  final List<CarpenterTimelineItem> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(emptyMessage));
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return KeyedSubtree(
          key: ValueKey(item.id),
          child: CarpenterCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 480;
                final timestamp = Text(
                  item.timestamp.toLocal().toIso8601String(),
                  style: context.face
                      .type('caption')
                      .copyWith(color: context.face.color('text.muted')),
                );
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    item.title,
                    if (item.description != null) ...[
                      const SizedBox(height: 4),
                      item.description!,
                    ],
                    if (compact) ...[const SizedBox(height: 4), timestamp],
                  ],
                );
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.leading != null) ...[
                      item.leading!,
                      const SizedBox(width: 10),
                    ],
                    Expanded(child: details),
                    if (!compact) timestamp,
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

final class CarpenterRecordTab<T> {
  const CarpenterRecordTab({
    required this.value,
    required this.label,
    required this.content,
  });

  final T value;
  final Widget label;
  final Widget content;
}

/// A complete tabbed record region with standard spacing and content layout.
class CarpenterRecordTabs<T> extends StatelessWidget {
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
    assert(tabs.isNotEmpty, 'CarpenterRecordTabs requires at least one tab.');
    final selected = tabs.firstWhere(
      (tab) => tab.value == value,
      orElse: () => tabs.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterTabs<T>(
          value: selected.value,
          tabs: [
            for (final tab in tabs)
              CarpenterTab(value: tab.value, child: tab.label),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        selected.content,
      ],
    );
  }
}

/// Standard page composition for viewing one domain record.
class CarpenterRecordPage<T> extends StatelessWidget {
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
    assert(
      descriptor.kind == CarpenterPageKind.record,
      'CarpenterRecordPage requires a record descriptor.',
    );
    final customBody = body;
    return CarpenterPage(
      descriptor: descriptor,
      controller: controller,
      state: controller == null ? state : null,
      commands: commands,
      commandBindings: commandBindings,
      capabilities: capabilities,
      header: header ?? CarpenterEntityHeader(title: Text(descriptor.title)),
      body:
          customBody ??
          ListView(
            children: [
              if (summary != null) ...[summary!, const SizedBox(height: 12)],
              if (attention != null) ...[
                attention!,
                const SizedBox(height: 12),
              ],
              for (final section in sections) ...[
                section,
                const SizedBox(height: 12),
              ],
              if (tabs != null) ...[tabs!, const SizedBox(height: 12)],
              for (final collection in related) ...[
                collection,
                const SizedBox(height: 12),
              ],
              if (timeline != null) timeline!,
            ],
          ),
    );
  }
}
