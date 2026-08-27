import 'dart:async';

import 'package:carpenter/src/components/basic/button/button.dart';
import 'package:carpenter/src/components/basic/card.dart';
import 'package:carpenter/src/components/basic/checkbox.dart';
import 'package:carpenter/src/components/basic/input/input.dart';
import 'package:carpenter/src/components/basic/input/text_area.dart';
import 'package:carpenter/src/components/basic/text.dart';
import 'package:carpenter/src/foundation/roles.dart';
import 'package:carpenter/src/legacy/src/component/loader/carpenter_loader.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/page/capability.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart' hide Text;

extension type const CarpenterPageSectionId(String value) {}

/// Standard page section with optional collapse and section commands.
class CarpenterPageSection extends StatefulWidget {
  const CarpenterPageSection({
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
  State<CarpenterPageSection> createState() => _CarpenterPageSectionState();
}

class _CarpenterPageSectionState extends State<CarpenterPageSection> {
  late bool expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarpenterText(widget.title, role: .title),
        if (widget.description != null) ...[
          const SizedBox(height: 4),
          CarpenterText(
            widget.description!,
            role: .caption,
            colorRole: .secondary,
          ),
        ],
      ],
    );
    final actions = <Widget>[
      ...widget.commands,
      if (widget.collapsible)
        CarpenterIconButton(
          semanticLabel: expanded ? 'Свернуть' : 'Развернуть',
          onPressed: () => setState(() => expanded = !expanded),
          icon: CarpenterText(expanded ? '⌃' : '⌄'),
        ),
    ];

    return CarpenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (actions.isEmpty) return heading;
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading,
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: actions),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: heading),
                  ...actions,
                ],
              );
            },
          ),
          if (expanded) ...[const SizedBox(height: 12), widget.child],
        ],
      ),
    );
  }
}

/// Responsive container for page and collection actions.
class CarpenterActionBar extends StatelessWidget {
  const CarpenterActionBar({
    super.key,
    this.primary = const [],
    this.secondary = const [],
    this.compactBreakpoint = 640,
  });

  final List<Widget> primary;
  final List<Widget> secondary;
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      alignment: constraints.maxWidth < compactBreakpoint
          ? WrapAlignment.start
          : WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [...secondary, ...primary],
    ),
  );
}

/// Responsive region for query and filter controls.
class CarpenterFilterBar extends StatelessWidget {
  const CarpenterFilterBar({
    super.key,
    this.query,
    this.filters = const [],
    this.actions = const [],
  });

  final Widget? query;
  final List<Widget> filters;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [if (query != null) query!, ...filters, ...actions],
  );
}

/// Standard width constraint for one query/filter control.
class CarpenterFilterControl extends StatelessWidget {
  const CarpenterFilterControl({
    super.key,
    required this.child,
    this.width = 180,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: constraints.maxWidth.isFinite
          ? width.clamp(0, constraints.maxWidth).toDouble()
          : width,
      child: child,
    ),
  );
}

/// Adaptive header for one group inside a collection.
class CarpenterCollectionGroupHeader extends StatelessWidget {
  const CarpenterCollectionGroupHeader({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.metadata = const [],
    this.action,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final List<Widget> metadata;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Expanded(
          child: CarpenterBlockGroup(
            spacing: 4,
            children: [
              DefaultTextStyle.merge(
                style: context.face
                    .type('body.strong')
                    .copyWith(color: context.face.color('text.primary')),
                child: title,
              ),
              if (subtitle != null) subtitle!,
              if (metadata.isNotEmpty)
                Wrap(spacing: 6, runSpacing: 6, children: metadata),
            ],
          ),
        ),
      ],
    );
    if (action == null) return details;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 520
          ? CarpenterBlockGroup(children: [details, action!])
          : Row(
              children: [
                Expanded(child: details),
                action!,
              ],
            ),
    );
  }
}

/// Vertically composed subtitle and tags for collection rows.
class CarpenterListTileDetails extends StatelessWidget {
  const CarpenterListTileDetails({
    super.key,
    this.children = const [],
    this.tags = const [],
  });

  final List<Widget> children;
  final List<Widget> tags;

  @override
  Widget build(BuildContext context) => CarpenterBlockGroup(
    spacing: 4,
    children: [
      ...children,
      if (tags.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: tags),
    ],
  );
}

/// Compact trailing action cluster for collection rows.
class CarpenterTrailingActions extends StatelessWidget {
  const CarpenterTrailingActions({
    super.key,
    this.actions = const [],
    this.indicator,
  });

  final List<Widget> actions;
  final Widget? indicator;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 6,
    runSpacing: 6,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [...actions, if (indicator != null) indicator!],
  );
}

/// Standard full-surface interaction overlay with optional error notice.
class CarpenterInteractionOverlay extends StatelessWidget {
  const CarpenterInteractionOverlay({
    super.key,
    required this.child,
    required this.active,
    required this.overlay,
    this.error,
  });

  final Widget child;
  final bool active;
  final Widget overlay;
  final String? error;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      if (active) Positioned.fill(child: overlay),
      if (error != null)
        Positioned(
          top: 12,
          right: 12,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: CarpenterNotice(
              title: const CarpenterText('Действие не выполнено'),
              content: CarpenterText(error!),
              tone: CarpenterNoticeTone.danger,
            ),
          ),
        ),
    ],
  );
}

/// Standard actions shown while collection items are selected.
class CarpenterSelectionBar<T> extends StatelessWidget {
  const CarpenterSelectionBar({
    super.key,
    required this.controller,
    this.commands = const [],
  });

  final CarpenterSelectionController<T> controller;
  final List<Widget> commands;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (!controller.hasSelection) return const SizedBox.shrink();
      final actions = [
        ...commands,
        CarpenterButton(
          label: 'Снять выбор',
          prominence: .outlined,
          onInvoke: controller.clear,
        ),
      ];
      return CarpenterCard(
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 520
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CarpenterText('Выбрано: ${controller.length}'),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: actions,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: CarpenterText('Выбрано: ${controller.length}'),
                    ),
                    ...actions,
                  ],
                ),
        ),
      );
    },
  );
}

class CarpenterEmptyState extends StatelessWidget {
  const CarpenterEmptyState({super.key, required this.descriptor});

  final CarpenterEmptyStateDescriptor descriptor;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarpenterText(
            descriptor.title,
            textAlign: TextAlign.center,
            role: .title,
          ),
          if (descriptor.message != null) ...[
            const SizedBox(height: 8),
            CarpenterText(
              descriptor.message!,
              textAlign: TextAlign.center,
              colorRole: .secondary,
            ),
          ],
          if (descriptor.action != null) ...[
            const SizedBox(height: 16),
            CarpenterCommandButton<void>(
              command: descriptor.action!,
              input: null,
            ),
          ],
        ],
      ),
    ),
  );
}

class CarpenterAttentionBlock extends StatelessWidget {
  const CarpenterAttentionBlock({
    super.key,
    required this.title,
    this.message,
    this.tone = CarpenterNoticeTone.warning,
    this.action,
  });

  final String title;
  final String? message;
  final CarpenterNoticeTone tone;
  final Widget? action;

  @override
  Widget build(BuildContext context) => CarpenterNotice(
    title: CarpenterText(title),
    content: message == null ? null : CarpenterText(message!),
    tone: tone,
    action: action,
  );
}

/// Standard vertically spaced list for structural and related page regions.
///
/// Domain pages provide items and one domain row; Carpenter owns empty
/// presentation, spacing and the surrounding vertical composition.
class CarpenterBlockList<T> extends StatelessWidget {
  const CarpenterBlockList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.emptyMessage,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return CarpenterEmptyState(
        descriptor: CarpenterEmptyStateDescriptor(
          title: emptyMessage,
          kind: CarpenterEmptyStateKind.collection,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          itemBuilder(context, items[index]),
          if (index < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Standard vertical composition for a group of structural or domain blocks.
///
/// Pages describe the blocks while Carpenter owns their spacing.
class CarpenterBlockGroup extends StatelessWidget {
  const CarpenterBlockGroup({
    super.key,
    required this.children,
    this.spacing = 8,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < children.length; index++) ...[
        children[index],
        if (index < children.length - 1) SizedBox(height: spacing),
      ],
    ],
  );
}

typedef CarpenterControllerFactory<C extends ChangeNotifier> =
    C Function(BuildContext context);

/// Owns a small presentation/application controller outside a domain widget.
class CarpenterControllerHost<C extends ChangeNotifier> extends StatefulWidget {
  const CarpenterControllerHost({
    super.key,
    required this.create,
    required this.builder,
  });

  final CarpenterControllerFactory<C> create;
  final Widget Function(BuildContext context, C controller) builder;

  @override
  State<CarpenterControllerHost<C>> createState() =>
      _CarpenterControllerHostState<C>();
}

class _CarpenterControllerHostState<C extends ChangeNotifier>
    extends State<CarpenterControllerHost<C>> {
  C? controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller ??= widget.create(context);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller!,
    builder: (context, _) => widget.builder(context, controller!),
  );
}

/// Cancellation owned by an asynchronous suggestion field.
class CarpenterSearchCancellation extends ChangeNotifier {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    notifyListeners();
  }
}

typedef CarpenterSuggestionLoader<T> =
    Future<List<T>> Function(
      String query,
      CarpenterSearchCancellation cancellation,
    );

/// Complete searchable suggestion field.
///
/// Carpenter owns text synchronization, debounce, cancellation, stale-result
/// protection, loading, errors and suggestion layout. A domain module only
/// supplies the loader and how one result is described.
class CarpenterAsyncSearchField<T> extends StatefulWidget {
  const CarpenterAsyncSearchField({
    super.key,
    required this.load,
    required this.title,
    required this.onSelected,
    this.subtitle,
    this.selected,
    this.selectedLabel,
    this.onQueryChanged,
    this.placeholder,
    this.error,
    this.debounce = const Duration(milliseconds: 300),
    this.minimumQueryLength = 1,
    this.maxSuggestionHeight = 240,
  });

  final CarpenterSuggestionLoader<T> load;
  final String Function(T item) title;
  final String Function(T item)? subtitle;
  final ValueChanged<T?> onSelected;
  final Object? selected;
  final String? selectedLabel;
  final ValueChanged<String>? onQueryChanged;
  final String? placeholder;
  final String? error;
  final Duration debounce;
  final int minimumQueryLength;
  final double maxSuggestionHeight;

  @override
  State<CarpenterAsyncSearchField<T>> createState() =>
      _CarpenterAsyncSearchFieldState<T>();
}

typedef CarpenterInspectorLabelBuilder = String Function(String key);
typedef CarpenterInspectorScalarBuilder = String Function(Object? value);
typedef CarpenterInspectorFieldFilter =
    bool Function(String key, Object? value);

/// Recursive readable presentation for map/list payloads.
class CarpenterInspector extends StatelessWidget {
  const CarpenterInspector({
    super.key,
    required this.value,
    this.labelBuilder,
    this.scalarBuilder,
    this.fieldFilter,
    this.emptyMessage = 'Нет данных',
  });

  final Object? value;
  final CarpenterInspectorLabelBuilder? labelBuilder;
  final CarpenterInspectorScalarBuilder? scalarBuilder;
  final CarpenterInspectorFieldFilter? fieldFilter;
  final String emptyMessage;

  String _label(String key) => labelBuilder?.call(key) ?? key;

  String _scalar(Object? value) =>
      scalarBuilder?.call(value) ?? value?.toString() ?? '—';

  @override
  Widget build(BuildContext context) => _InspectorValue(
    value: value,
    label: _label,
    scalar: _scalar,
    fieldFilter: fieldFilter,
    emptyMessage: emptyMessage,
  );
}

class _InspectorValue extends StatelessWidget {
  const _InspectorValue({
    required this.value,
    required this.label,
    required this.scalar,
    required this.fieldFilter,
    required this.emptyMessage,
  });

  final Object? value;
  final String Function(String key) label;
  final String Function(Object? value) scalar;
  final CarpenterInspectorFieldFilter? fieldFilter;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (value is Map) {
      final entries = (value as Map).entries
          .where((entry) {
            final key = '${entry.key}';
            return fieldFilter?.call(key, entry.value) ??
                (entry.value != null && '${entry.value}'.isNotEmpty);
          })
          .toList(growable: false);
      if (entries.isEmpty) return CarpenterText(emptyMessage);
      return CarpenterBlockGroup(
        spacing: 8,
        children: [
          for (final entry in entries)
            _InspectorField(
              label: label('${entry.key}'),
              value: entry.value is Map || entry.value is List
                  ? CarpenterInspector(
                      value: entry.value,
                      labelBuilder: label,
                      scalarBuilder: scalar,
                      fieldFilter: fieldFilter,
                      emptyMessage: emptyMessage,
                    )
                  : CarpenterText(scalar(entry.value)),
            ),
        ],
      );
    }
    if (value is List) {
      final items = value as List;
      return CarpenterBlockList<Object?>(
        items: items.cast<Object?>(),
        emptyMessage: emptyMessage,
        itemBuilder: (context, item) => CarpenterCard(
          child: CarpenterInspector(
            value: item,
            labelBuilder: label,
            scalarBuilder: scalar,
            fieldFilter: fieldFilter,
            emptyMessage: emptyMessage,
          ),
        ),
      );
    }
    return CarpenterText(scalar(value));
  }
}

class _InspectorField extends StatelessWidget {
  const _InspectorField({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelWidget = CarpenterText(
        label,
        role: .label,
        emphasis: .strong,
        colorRole: .secondary,
      );
      if (constraints.maxWidth < 420) {
        return CarpenterBlockGroup(spacing: 4, children: [labelWidget, value]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 210, child: labelWidget),
          const SizedBox(width: 12),
          Expanded(child: value),
        ],
      );
    },
  );
}

/// Standard body for async dialogs that contain one scrollable collection.
class CarpenterDialogCollectionBody extends StatelessWidget {
  const CarpenterDialogCollectionBody({
    super.key,
    required this.collection,
    this.header,
    this.error,
    this.loading = false,
    this.unavailable = false,
    this.unavailableMessage = 'Данные недоступны',
    this.footer,
  });

  final Widget collection;
  final Widget? header;
  final String? error;
  final bool loading;
  final bool unavailable;
  final String unavailableMessage;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (header != null) ...[header!, const SizedBox(height: 12)],
      if (error != null) ...[
        CarpenterNotice(
          title: const CarpenterText('Ошибка'),
          content: CarpenterText(error!),
          tone: CarpenterNoticeTone.danger,
        ),
        const SizedBox(height: 8),
      ],
      if (loading) ...[
        const CarpenterIndeterminateProgress(),
        const SizedBox(height: 8),
      ],
      if (unavailable)
        Expanded(child: Center(child: CarpenterText(unavailableMessage)))
      else
        Expanded(child: collection),
      if (footer != null) ...[const SizedBox(height: 8), footer!],
    ],
  );
}

/// Standard page navigation and contextual selection message.
class CarpenterPaginationBar extends StatelessWidget {
  const CarpenterPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.leading,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final pageLabel = CarpenterText('Страница $page из $totalPages');
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarpenterIconButton(
          icon: const CarpenterText('‹'),
          semanticLabel: 'Предыдущая страница',
          onPressed: page <= 1 ? null : () => onPageChanged(page - 1),
        ),
        CarpenterIconButton(
          icon: const CarpenterText('›'),
          semanticLabel: 'Следующая страница',
          onPressed: page >= totalPages ? null : () => onPageChanged(page + 1),
        ),
      ],
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [pageLabel, buttons],
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 420
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[leading!, const SizedBox(height: 8)],
                Align(alignment: Alignment.centerRight, child: pageLabel),
                Align(alignment: Alignment.centerRight, child: buttons),
              ],
            )
          : Row(
              children: [
                if (leading != null) Expanded(child: leading!),
                controls,
              ],
            ),
    );
  }
}

/// Scrollable selectable records used by resolution/reconciliation dialogs.
class CarpenterSelectableCollection<T> extends StatelessWidget {
  const CarpenterSelectableCollection({
    super.key,
    required this.items,
    required this.itemIdentity,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelectionChanged,
    this.details,
    this.selectionEnabled,
  });

  final List<T> items;
  final Object Function(T item) itemIdentity;
  final Widget Function(T item) title;
  final Widget Function(T item) subtitle;
  final Widget Function(T item)? details;
  final bool Function(T item) selected;
  final bool Function(T item)? selectionEnabled;
  final void Function(T item, bool selected) onSelectionChanged;

  @override
  Widget build(BuildContext context) => ListView.separated(
    itemCount: items.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final item = items[index];
      return KeyedSubtree(
        key: ValueKey(itemIdentity(item)),
        child: CarpenterCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarpenterCheckbox(
                value: selected(item)
                    ? CheckboxValue.checked
                    : CheckboxValue.unchecked,
                label: '',
                semanticLabel: 'Выбрать ${itemIdentity(item)}',
                onChanged: selectionEnabled?.call(item) == false
                    ? null
                    : (value) => onSelectionChanged(
                        item,
                        value == CheckboxValue.checked,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CarpenterBlockGroup(
                  spacing: 4,
                  children: [
                    DefaultTextStyle.merge(
                      style: context.face
                          .type('body.strong')
                          .copyWith(color: context.face.color('text.primary')),
                      child: title(item),
                    ),
                    subtitle(item),
                    if (details != null) details!(item),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Complete single-text-value dialog for notes, reasons and simple edits.
class CarpenterTextPromptDialog extends StatefulWidget {
  const CarpenterTextPromptDialog({
    super.key,
    required this.title,
    required this.label,
    this.initialValue,
    this.header,
    this.placeholder,
    this.maxLines = 1,
    this.confirmLabel = 'Сохранить',
    this.cancelLabel = 'Отмена',
    this.constraints = const BoxConstraints(maxWidth: 560),
  });

  final String title;
  final String label;
  final String? initialValue;
  final Widget? header;
  final String? placeholder;
  final int maxLines;
  final String confirmLabel;
  final String cancelLabel;
  final BoxConstraints constraints;

  @override
  State<CarpenterTextPromptDialog> createState() =>
      _CarpenterTextPromptDialogState();
}

class _CarpenterTextPromptDialogState extends State<CarpenterTextPromptDialog> {
  late final TextEditingController text = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    title: CarpenterText(widget.title),
    constraints: widget.constraints,
    content: CarpenterBlockGroup(
      spacing: 12,
      children: [
        if (widget.header != null) widget.header!,
        CarpenterBlockGroup(
          spacing: 6,
          children: [
            CarpenterText(widget.label),
            if (widget.maxLines == 1)
              CarpenterInput(controller: text, placeholder: widget.placeholder)
            else
              CarpenterTextArea(
                controller: text,
                placeholder: widget.placeholder,
                minLines: 1,
                maxLines: widget.maxLines,
              ),
          ],
        ),
      ],
    ),
    actions: [
      CarpenterButton(
        label: widget.cancelLabel,
        prominence: .outlined,
        onInvoke: () => Navigator.pop(context),
      ),
      CarpenterButton(
        label: widget.confirmLabel,
        colorRole: .primary,
        prominence: .high,
        onInvoke: () => Navigator.pop(context, text.text.trim()),
      ),
    ],
  );
}

final class CarpenterTextFieldDescriptor {
  const CarpenterTextFieldDescriptor({
    required this.id,
    required this.label,
    this.initialValue,
    this.placeholder,
    this.maxLines = 1,
  });

  final String id;
  final String label;
  final String? initialValue;
  final String? placeholder;
  final int maxLines;
}

/// Complete multi-text-field dialog with controller ownership in Carpenter.
class CarpenterTextFieldsDialog extends StatefulWidget {
  const CarpenterTextFieldsDialog({
    super.key,
    required this.title,
    required this.fields,
    this.header,
    this.confirmLabel = 'Сохранить',
    this.cancelLabel = 'Отмена',
    this.constraints = const BoxConstraints(maxWidth: 560),
  });

  final String title;
  final List<CarpenterTextFieldDescriptor> fields;
  final Widget? header;
  final String confirmLabel;
  final String cancelLabel;
  final BoxConstraints constraints;

  @override
  State<CarpenterTextFieldsDialog> createState() =>
      _CarpenterTextFieldsDialogState();
}

class _CarpenterTextFieldsDialogState extends State<CarpenterTextFieldsDialog> {
  late final Map<String, TextEditingController> fields = {
    for (final field in widget.fields)
      field.id: TextEditingController(text: field.initialValue),
  };

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    title: CarpenterText(widget.title),
    constraints: widget.constraints,
    content: CarpenterBlockGroup(
      spacing: 12,
      children: [
        if (widget.header != null) widget.header!,
        for (final field in widget.fields)
          CarpenterBlockGroup(
            spacing: 6,
            children: [
              CarpenterText(field.label),
              if (field.maxLines == 1)
                CarpenterInput(
                  controller: fields[field.id]!,
                  placeholder: field.placeholder,
                )
              else
                CarpenterTextArea(
                  controller: fields[field.id]!,
                  placeholder: field.placeholder,
                  minLines: 1,
                  maxLines: field.maxLines,
                ),
            ],
          ),
      ],
    ),
    actions: [
      CarpenterButton(
        label: widget.cancelLabel,
        prominence: .outlined,
        onInvoke: () => Navigator.pop(context),
      ),
      CarpenterButton(
        label: widget.confirmLabel,
        colorRole: .primary,
        prominence: .high,
        onInvoke: () => Navigator.pop(context, {
          for (final entry in fields.entries) entry.key: entry.value.text,
        }),
      ),
    ],
  );
}

class _CarpenterAsyncSearchFieldState<T>
    extends State<CarpenterAsyncSearchField<T>> {
  late final TextEditingController _text;
  late final FocusNode _focusNode;
  Timer? _debounce;
  CarpenterSearchCancellation? _cancellation;
  List<T> _items = const [];
  bool _loading = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.selectedLabel ?? '');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant CarpenterAsyncSearchField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != null &&
        widget.selectedLabel != oldWidget.selectedLabel &&
        widget.selectedLabel != _text.text) {
      _text.text = widget.selectedLabel ?? '';
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cancellation?.cancel();
    _cancellation?.dispose();
    _focusNode.dispose();
    _text.dispose();
    super.dispose();
  }

  void _changed(String value) {
    widget.onQueryChanged?.call(value);
    widget.onSelected(null);
    _debounce?.cancel();
    _cancellation?.cancel();
    final query = value.trim();
    if (query.length < widget.minimumQueryLength) {
      setState(() {
        _loading = false;
        _items = const [];
      });
      return;
    }
    _debounce = Timer(widget.debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final generation = ++_generation;
    _cancellation?.cancel();
    _cancellation?.dispose();
    final cancellation = CarpenterSearchCancellation();
    _cancellation = cancellation;
    setState(() => _loading = true);
    try {
      final items = await widget.load(query, cancellation);
      if (!mounted || cancellation.isCancelled || generation != _generation) {
        return;
      }
      setState(() => _items = items);
    } catch (_) {
      if (!mounted || cancellation.isCancelled || generation != _generation) {
        return;
      }
      setState(() => _items = const []);
    } finally {
      if (mounted && !cancellation.isCancelled && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  void _select(T item) {
    _debounce?.cancel();
    _cancellation?.cancel();
    _text.text = widget.title(item);
    setState(() => _items = const []);
    widget.onSelected(item);
  }

  @override
  Widget build(BuildContext context) => CarpenterBlockGroup(
    spacing: 6,
    children: [
      Row(
        children: [
          Expanded(
            child: CarpenterInput(
              controller: _text,
              focusNode: _focusNode,
              placeholder: widget.placeholder,
              leadingIcon: CarpenterIcons.search,
              onChanged: _changed,
            ),
          ),
          if (_loading) ...[
            const SizedBox(width: 8),
            const SizedBox.square(
              dimension: 14,
              child: CarpenterLoader(strokeWidth: 2),
            ),
          ],
        ],
      ),
      if (_text.text.isNotEmpty && _items.isNotEmpty)
        CarpenterCard(
          padded: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxSuggestionHeight),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final subtitle = widget.subtitle?.call(item);
                return CarpenterListTile(
                  title: CarpenterText(widget.title(item)),
                  subtitle: subtitle == null || subtitle.isEmpty
                      ? null
                      : CarpenterText(subtitle),
                  onPressed: () => _select(item),
                );
              },
            ),
          ),
        ),
      if (widget.error != null) CarpenterText(widget.error!, role: .caption),
    ],
  );
}
