import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../application/command.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../page/capability.dart';
import '../../basic/button/button.dart';
import '../../basic/card.dart';
import '../../basic/checkbox.dart';
import '../../basic/loader.dart';
import '../../basic/input/input.dart';
import '../../basic/input/text_area.dart';
import '../../basic/text.dart';
import '../../behaviour/dialog.dart';
import '../../behaviour/notice.dart';

extension type const CarpenterPageSectionId(String value) {}

final class CarpenterPageSection extends StatefulWidget {
  const CarpenterPageSection({super.key, required this.id, required this.title, required this.child, this.description, this.actions = const [], this.collapsible = false, this.initiallyExpanded = true});
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
  void didUpdateWidget(CarpenterPageSection oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.initiallyExpanded != widget.initiallyExpanded) _expanded = widget.initiallyExpanded; }
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context); final gap = context.units(theme.spacing.medium);
    final actions = <Widget>[...widget.actions, if (widget.collapsible) CarpenterButton(label: _expanded ? 'Collapse' : 'Expand', size: ControlSize.small, prominence: ActionProminence.ghost, onInvoke: () => setState(() => _expanded = !_expanded))];
    return CarpenterCard(semanticLabel: widget.title, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        final heading = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CarpenterText.title(widget.title, emphasis: TypographyEmphasis.strong), if (widget.description != null) ...[SizedBox(height: gap / 2), CarpenterText.caption(widget.description!, colorRole: ContentColorRole.secondary)]]);
        if (actions.isEmpty) return heading;
        return constraints.maxWidth < 520 ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading, SizedBox(height: gap), Wrap(spacing: gap, runSpacing: gap, children: actions)]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: heading), SizedBox(width: gap), Wrap(spacing: gap / 2, runSpacing: gap / 2, children: actions)]);
      }),
      if (_expanded) ...[SizedBox(height: gap), widget.child],
    ]));
  }
}

final class CarpenterActionBar extends StatelessWidget {
  const CarpenterActionBar({super.key, this.primary = const [], this.secondary = const [], this.compactBreakpoint = 640});
  final List<Widget> primary; final List<Widget> secondary; final double compactBreakpoint;
  @override
  Widget build(BuildContext context) { final gap = context.units(CarpenterTheme.of(context).spacing.small); return LayoutBuilder(builder: (context, constraints) => Wrap(alignment: constraints.maxWidth < compactBreakpoint ? WrapAlignment.start : WrapAlignment.end, spacing: gap, runSpacing: gap, children: [...secondary, ...primary])); }
}

final class CarpenterFilterControl extends StatelessWidget {
  const CarpenterFilterControl({super.key, required this.child, this.width = 180}); final Widget child; final double width;
  @override Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) => SizedBox(width: constraints.maxWidth.isFinite ? width.clamp(0, constraints.maxWidth).toDouble() : width, child: child));
}

final class CarpenterCollectionGroupHeader extends StatelessWidget {
  const CarpenterCollectionGroupHeader({super.key, required this.title, this.leading, this.subtitle, this.metadata = const [], this.action});
  final Widget title; final Widget? leading; final Widget? subtitle; final List<Widget> metadata; final Widget? action;
  @override
  Widget build(BuildContext context) { final gap = context.units(CarpenterTheme.of(context).spacing.small); final details = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [if (leading != null) ...[leading!, SizedBox(width: gap)], Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, if (subtitle != null) ...[SizedBox(height: gap / 2), subtitle!], if (metadata.isNotEmpty) ...[SizedBox(height: gap / 2), Wrap(spacing: gap, runSpacing: gap / 2, children: metadata)]]))]); if (action == null) return details; return LayoutBuilder(builder: (context, constraints) => constraints.maxWidth < 520 ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [details, SizedBox(height: gap), action!]) : Row(children: [Expanded(child: details), SizedBox(width: gap), action!])); }
}

final class CarpenterListTileDetails extends StatelessWidget {
  const CarpenterListTileDetails({super.key, this.children = const [], this.tags = const []}); final List<Widget> children; final List<Widget> tags;
  @override Widget build(BuildContext context) { final gap = context.units(CarpenterTheme.of(context).spacing.small); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var index = 0; index < children.length; index++) ...[children[index], if (index < children.length - 1) SizedBox(height: gap / 2)], if (tags.isNotEmpty) ...[if (children.isNotEmpty) SizedBox(height: gap / 2), Wrap(spacing: gap, runSpacing: gap / 2, children: tags)]]); }
}

final class CarpenterTrailingActions extends StatelessWidget {
  const CarpenterTrailingActions({super.key, this.actions = const [], this.indicator}); final List<Widget> actions; final Widget? indicator;
  @override Widget build(BuildContext context) { final gap = context.units(CarpenterTheme.of(context).spacing.small); return Wrap(alignment: WrapAlignment.end, spacing: gap, runSpacing: gap, crossAxisAlignment: WrapCrossAlignment.center, children: [...actions, if (indicator != null) indicator!]); }
}

final class CarpenterInteractionOverlay extends StatelessWidget {
  const CarpenterInteractionOverlay({super.key, required this.child, required this.active, required this.overlay, this.error}); final Widget child; final bool active; final Widget overlay; final String? error;
  @override Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [child, if (active) Positioned.fill(child: overlay), if (error != null) Positioned(top: 12, right: 12, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: CarpenterNotice(title: 'Action failed', message: error, tone: CarpenterNoticeTone.danger)))]);
}

final class CarpenterSelectionBar<T> extends StatelessWidget {
  const CarpenterSelectionBar({super.key, required this.controller, this.actions = const []}); final CarpenterSelectionController<T> controller; final List<Widget> actions;
  @override Widget build(BuildContext context) => ListenableBuilder(listenable: controller, builder: (context, _) { if (!controller.hasSelection) return const SizedBox.shrink(); final all = [...actions, CarpenterButton(label: 'Clear selection', prominence: ActionProminence.outlined, onInvoke: controller.clear)]; return CarpenterCard(child: LayoutBuilder(builder: (context, constraints) => constraints.maxWidth < 520 ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [CarpenterText.body('Selected: ${controller.length}'), const SizedBox(height: 8), Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: all)]) : Row(children: [Expanded(child: CarpenterText.body('Selected: ${controller.length}')), ...all]))); });
}

final class CarpenterAttentionBlock extends StatelessWidget {
  const CarpenterAttentionBlock({super.key, required this.title, this.message, this.tone = CarpenterNoticeTone.warning, this.action}); final String title; final String? message; final CarpenterNoticeTone tone; final CarpenterActionDescriptor? action;
  @override Widget build(BuildContext context) => CarpenterNotice(title: title, message: message, tone: tone, action: action);
}

final class CarpenterBlockList<T> extends StatelessWidget {
  const CarpenterBlockList({super.key, required this.items, required this.itemBuilder, required this.emptyMessage}); final List<T> items; final Widget Function(BuildContext context, T item) itemBuilder; final String emptyMessage;
  @override Widget build(BuildContext context) { if (items.isEmpty) return Center(child: CarpenterText.body(emptyMessage, colorRole: ContentColorRole.secondary)); final gap = context.units(CarpenterTheme.of(context).spacing.medium); return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var index = 0; index < items.length; index++) ...[itemBuilder(context, items[index]), if (index < items.length - 1) SizedBox(height: gap)]]); }
}

final class CarpenterBlockGroup extends StatelessWidget {
  const CarpenterBlockGroup({super.key, required this.children, this.spacing}); final List<Widget> children; final double? spacing;
  @override Widget build(BuildContext context) { final gap = spacing ?? context.units(CarpenterTheme.of(context).spacing.medium); return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (var index = 0; index < children.length; index++) ...[children[index], if (index < children.length - 1) SizedBox(height: gap)]]); }
}

typedef CarpenterControllerFactory<C extends ChangeNotifier> = C Function(BuildContext context);
final class CarpenterControllerHost<C extends ChangeNotifier> extends StatefulWidget {
  const CarpenterControllerHost({super.key, required this.create, required this.builder}); final CarpenterControllerFactory<C> create; final Widget Function(BuildContext context, C controller) builder;
  @override State<CarpenterControllerHost<C>> createState() => _CarpenterControllerHostState<C>();
}
final class _CarpenterControllerHostState<C extends ChangeNotifier> extends State<CarpenterControllerHost<C>> {
  C? _controller; @override void didChangeDependencies() { super.didChangeDependencies(); _controller ??= widget.create(context); } @override void dispose() { _controller?.dispose(); super.dispose(); } @override Widget build(BuildContext context) => ListenableBuilder(listenable: _controller!, builder: (context, _) => widget.builder(context, _controller!));
}

final class CarpenterDialogCollectionBody extends StatelessWidget {
  const CarpenterDialogCollectionBody({super.key, required this.collection, this.header, this.error, this.loading = false, this.unavailable = false, this.unavailableMessage = 'Data unavailable', this.footer}); final Widget collection; final Widget? header; final String? error; final bool loading; final bool unavailable; final String unavailableMessage; final Widget? footer;
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (header != null) ...[header!, const SizedBox(height: 12)], if (error != null) ...[CarpenterNotice(title: 'Error', message: error, tone: CarpenterNoticeTone.danger), const SizedBox(height: 8)], if (loading) ...[const Align(alignment: AlignmentDirectional.centerStart, child: CarpenterLoader()), const SizedBox(height: 8)], Expanded(child: unavailable ? Center(child: CarpenterText.body(unavailableMessage)) : collection), if (footer != null) ...[const SizedBox(height: 8), footer!]]);
}

final class CarpenterSelectableCollection<T> extends StatelessWidget {
  const CarpenterSelectableCollection({super.key, required this.items, required this.itemIdentity, required this.title, required this.subtitle, required this.selected, required this.onSelectionChanged, this.details, this.selectionEnabled}); final List<T> items; final Object Function(T item) itemIdentity; final String Function(T item) title; final String Function(T item) subtitle; final Widget Function(T item)? details; final bool Function(T item) selected; final bool Function(T item)? selectionEnabled; final void Function(T item, bool selected) onSelectionChanged;
  @override Widget build(BuildContext context) => ListView.separated(itemCount: items.length, separatorBuilder: (_, _) => const SizedBox(height: 8), itemBuilder: (context, index) { final item = items[index]; return CarpenterCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [CarpenterCheckbox(value: selected(item) ? CheckboxValue.checked : CheckboxValue.unchecked, label: '', semanticLabel: 'Select ${itemIdentity(item)}', onChanged: selectionEnabled?.call(item) == false ? null : (value) => onSelectionChanged(item, value == CheckboxValue.checked)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [CarpenterText.label(title(item), emphasis: TypographyEmphasis.strong), const SizedBox(height: 4), CarpenterText.body(subtitle(item), colorRole: ContentColorRole.secondary), if (details != null) ...[const SizedBox(height: 6), details!(item)]]))])); });
}

@immutable
final class CarpenterTextFieldDescriptor {
  const CarpenterTextFieldDescriptor({required this.id, required this.label, this.initialValue, this.placeholder, this.maxLines = 1}); final String id; final String label; final String? initialValue; final String? placeholder; final int maxLines;
}

final class CarpenterTextFieldsDialog extends StatefulWidget {
  const CarpenterTextFieldsDialog({super.key, required this.open, required this.onOpenChanged, required this.child, required this.title, required this.fields, required this.onSubmit, this.header, this.confirmLabel = 'Save', this.cancelLabel = 'Cancel'});
  final bool open; final ValueChanged<bool> onOpenChanged; final Widget child; final String title; final List<CarpenterTextFieldDescriptor> fields; final ValueChanged<Map<String, String>> onSubmit; final Widget? header; final String confirmLabel; final String cancelLabel;
  @override State<CarpenterTextFieldsDialog> createState() => _CarpenterTextFieldsDialogState();
}
final class _CarpenterTextFieldsDialogState extends State<CarpenterTextFieldsDialog> {
  late final Map<String, TextEditingController> _controllers = {for (final field in widget.fields) field.id: TextEditingController(text: field.initialValue)};
  @override void dispose() { for (final controller in _controllers.values) controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => CarpenterDialog(open: widget.open, onOpenChanged: widget.onOpenChanged, child: widget.child, title: widget.title, content: CarpenterBlockGroup(children: [if (widget.header != null) widget.header!, for (final field in widget.fields) field.maxLines == 1 ? CarpenterInput(controller: _controllers[field.id]!, label: field.label, placeholder: field.placeholder) : CarpenterTextArea(controller: _controllers[field.id]!, label: field.label, placeholder: field.placeholder, minLines: 1, maxLines: field.maxLines)]), actions: [CarpenterActionDescriptor(id: 'prompt.cancel', label: widget.cancelLabel, onInvoke: () => widget.onOpenChanged(false)), CarpenterActionDescriptor(id: 'prompt.submit', label: widget.confirmLabel, colorRole: ActionColorRole.primary, onInvoke: () { widget.onSubmit({for (final entry in _controllers.entries) entry.key: entry.value.text.trim()}); widget.onOpenChanged(false); })]);
}

/// Convenience single-field variant of [CarpenterTextFieldsDialog].
final class CarpenterTextPromptDialog extends StatelessWidget {
  const CarpenterTextPromptDialog({super.key, required this.open, required this.onOpenChanged, required this.child, required this.title, required this.label, required this.onSubmit, this.initialValue, this.header, this.placeholder, this.maxLines = 1, this.confirmLabel = 'Save', this.cancelLabel = 'Cancel'});
  final bool open; final ValueChanged<bool> onOpenChanged; final Widget child; final String title; final String label; final ValueChanged<String> onSubmit; final String? initialValue; final Widget? header; final String? placeholder; final int maxLines; final String confirmLabel; final String cancelLabel;
  @override Widget build(BuildContext context) => CarpenterTextFieldsDialog(open: open, onOpenChanged: onOpenChanged, child: child, title: title, header: header, confirmLabel: confirmLabel, cancelLabel: cancelLabel, fields: [CarpenterTextFieldDescriptor(id: 'value', label: label, initialValue: initialValue, placeholder: placeholder, maxLines: maxLines)], onSubmit: (values) => onSubmit(values['value'] ?? ''));
}
