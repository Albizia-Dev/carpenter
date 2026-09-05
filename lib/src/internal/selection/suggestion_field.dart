import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../components/basic/input/field_shell.dart';
import '../../components/basic/input/input.dart';
import '../../foundation/roles.dart';
import '../overlay/anchored_overlay_host.dart';
import 'menu_navigation.dart';
import 'menu_panel.dart';

final class SuggestionField<T> extends StatefulWidget {
  const SuggestionField({
    super.key,
    required this.controller,
    required this.options,
    required this.open,
    required this.onOpenChanged,
    required this.onQueryChanged,
    required this.onSelected,
    this.selectedOptionId,
    this.loadState = OptionsLoadState.ready,
    this.loadingText = 'Loading',
    this.emptyText = 'No options',
    this.failedText = 'Unable to load options',
    this.label,
    this.placeholder,
    this.description,
    this.feedback,
    this.errorText,
    this.semanticLabel,
    this.required = false,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
    this.placement = OverlayPlacement.bottomStart,
    this.clearAction,
    this.focusNode,
    this.autofocus = false,
    this.replaceQueryOnSelection = false,
  });

  final TextEditingController controller;
  final List<CarpenterOption<T>> options;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<CarpenterOption<T>>? onSelected;
  final Object? selectedOptionId;
  final OptionsLoadState loadState;
  final String loadingText;
  final String emptyText;
  final String failedText;
  final String? label;
  final String? placeholder;
  final String? description;
  final CarpenterFieldFeedback? feedback;
  final String? errorText;
  final String? semanticLabel;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final OverlayPlacement placement;
  final CarpenterActionDescriptor? clearAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool replaceQueryOnSelection;

  @override
  State<SuggestionField<T>> createState() => _SuggestionFieldState<T>();
}

final class _SuggestionFieldState<T> extends State<SuggestionField<T>> {
  final MenuNavigation<Object> _navigation = MenuNavigation();
  FocusNode? _ownedFocusNode;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;
  bool get _enabled =>
      widget.availability == FieldAvailability.enabled &&
      widget.onQueryChanged != null;
  bool get _composing {
    final composing = widget.controller.value.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  @override
  void initState() {
    super.initState();
    _attachFocusNode();
    _syncOptions();
    _syncSelectedQuery();
  }

  @override
  void didUpdateWidget(SuggestionField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode(oldWidget.focusNode);
      _attachFocusNode();
    }
    final selectedChanged =
        oldWidget.selectedOptionId != widget.selectedOptionId;
    _syncOptions();
    if (selectedChanged) _syncSelectedQuery();
  }

  void _attachFocusNode() {
    _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_handleFocusChanged);
  }

  void _detachFocusNode(FocusNode? external) {
    (external ?? _ownedFocusNode)?.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    _ownedFocusNode = null;
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus && _enabled && !widget.open) {
      widget.onOpenChanged(true);
    }
  }

  void _syncOptions() {
    assert(
      widget.options.map((option) => option.id).toSet().length ==
          widget.options.length,
      'Suggestion option ids must be unique.',
    );
    _navigation.update(
      widget.options.map(
        (option) => MenuNavigationItem(key: option.id, enabled: option.enabled),
      ),
    );
    final selected = widget.selectedOptionId;
    if (selected != null) _navigation.highlight(selected);
  }

  void _syncSelectedQuery() {
    if (!widget.replaceQueryOnSelection) return;
    final selected = widget.selectedOptionId;
    if (selected == null) return;
    for (final option in widget.options) {
      if (option.id != selected) continue;
      if (widget.controller.text == option.label) return;
      widget.controller.value = TextEditingValue(
        text: option.label,
        selection: TextSelection.collapsed(offset: option.label.length),
      );
      return;
    }
  }

  CarpenterOption<T>? get _highlighted {
    final key = _navigation.highlightedKey;
    if (key == null) return null;
    for (final option in widget.options) {
      if (option.id == key && option.enabled) return option;
    }
    return null;
  }

  void _move(int delta) {
    if (!_enabled || _composing) return;
    if (!widget.open) widget.onOpenChanged(true);
    setState(() => _navigation.move(delta));
  }

  void _select(CarpenterOption<T> option) {
    if (!_enabled || !option.enabled) return;
    _navigation.highlight(option.id);
    if (widget.replaceQueryOnSelection) {
      final value = TextEditingValue(
        text: option.label,
        selection: TextSelection.collapsed(offset: option.label.length),
      );
      if (widget.controller.value != value) {
        widget.controller.value = value;
      }
    }
    widget.onSelected?.call(option);
    widget.onOpenChanged(false);
  }

  void _queryChanged(String query) {
    if (_navigation.highlightedKey != null) {
      setState(() => _navigation.highlightedKey = null);
    }
    widget.onQueryChanged?.call(query);
    if (_enabled && !widget.open) widget.onOpenChanged(true);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_enabled || _composing) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home && widget.open) {
      setState(() => _navigation.first());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end && widget.open) {
      setState(() => _navigation.last());
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter && widget.open) {
      final option = _highlighted;
      if (option != null) _select(option);
      return option == null ? KeyEventResult.ignored : KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && widget.open) {
      widget.onOpenChanged(false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _detachFocusNode(widget.focusNode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAvailability =
        widget.availability == FieldAvailability.enabled &&
            widget.onQueryChanged == null
        ? FieldAvailability.disabled
        : widget.availability;
    final anchor = Focus(
      canRequestFocus: false,
      onKeyEvent: _handleKey,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _enabled && !widget.open
            ? (_) => widget.onOpenChanged(true)
            : null,
        child: CarpenterInput(
          controller: widget.controller,
          label: widget.label,
          placeholder: widget.placeholder,
          description: widget.description,
          feedback: widget.feedback,
          errorText: widget.errorText,
          semanticLabel: widget.semanticLabel,
          required: widget.required,
          availability: effectiveAvailability,
          size: widget.size,
          shape: widget.shape,
          trailingAction: effectiveAvailability == FieldAvailability.enabled
              ? widget.clearAction
              : null,
          onChanged: _queryChanged,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
        ),
      ),
    );
    return AnchoredOverlayHost(
      open: widget.open && _enabled,
      onOpenChanged: widget.onOpenChanged,
      placement: widget.placement,
      takeFocus: false,
      allowAnchorInteraction: true,
      anchor: anchor,
      overlayBuilder: (context) => _buildMenu(),
    );
  }

  Widget _buildMenu() {
    final statusText = switch (widget.loadState) {
      OptionsLoadState.loading => widget.loadingText,
      OptionsLoadState.failed => widget.failedText,
      OptionsLoadState.ready when widget.options.isEmpty => widget.emptyText,
      OptionsLoadState.ready => null,
    };
    if (statusText != null) {
      return MenuPanel(
        autofocus: false,
        entries: [
          MenuPanelEntry(
            id: 'suggestion-status',
            label: statusText,
            semanticLabel: statusText,
            enabled: false,
            onActivate: null,
          ),
        ],
      );
    }
    return MenuPanel(
      autofocus: false,
      semanticLabel: widget.semanticLabel,
      entries: [
        for (final option in widget.options)
          MenuPanelEntry(
            id: option.id,
            label: option.label,
            semanticLabel: option.effectiveSemanticLabel,
            enabled: option.enabled,
            selected:
                option.id == _navigation.highlightedKey ||
                option.id == widget.selectedOptionId,
            onActivate: option.enabled ? () => _select(option) : null,
          ),
      ],
    );
  }
}
