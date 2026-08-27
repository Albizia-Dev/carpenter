import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'field_shell.dart';

final class TextEditingField extends StatefulWidget {
  const TextEditingField({
    super.key,
    required this.controller,
    required this.availability,
    required this.size,
    required this.shape,
    required this.minLines,
    required this.maxLines,
    this.label,
    this.placeholder,
    this.description,
    this.errorText,
    this.semanticLabel,
    this.required = false,
    this.leading,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final int? minLines;
  final int? maxLines;
  final String? label;
  final String? placeholder;
  final String? description;
  final String? errorText;
  final String? semanticLabel;
  final bool required;
  final Widget? leading;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<TextEditingField> createState() => _TextEditingFieldState();
}

final class _TextEditingFieldState extends State<TextEditingField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditableTextState> _editableTextKey = GlobalKey();
  FocusNode? _ownedFocusNode;
  late final TextSelectionGestureDetectorBuilder _selectionGestureBuilder;
  var _hovered = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;
  bool get _disabled => widget.availability == FieldAvailability.disabled;
  bool get _readOnly => widget.availability != FieldAvailability.enabled;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableTextKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => !_disabled;

  @override
  void initState() {
    super.initState();
    _selectionGestureBuilder = TextSelectionGestureDetectorBuilder(
      delegate: this,
    );
    _attachFocusNode();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(TextEditingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode(oldWidget.focusNode);
      _attachFocusNode();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  void _attachFocusNode() {
    _ownedFocusNode = widget.focusNode == null ? FocusNode() : null;
    _focusNode.addListener(_handleFocusChanged);
  }

  void _detachFocusNode(FocusNode? externalNode) {
    (externalNode ?? _ownedFocusNode)?.removeListener(_handleFocusChanged);
    _ownedFocusNode?.dispose();
    _ownedFocusNode = null;
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _detachFocusNode(widget.focusNode);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final states = <WidgetState>{
      if (_hovered && !_disabled) WidgetState.hovered,
      if (_focusNode.hasFocus && !_disabled) WidgetState.focused,
      if (_disabled) WidgetState.disabled,
      if (widget.errorText != null) WidgetState.error,
    };
    final style = theme.fields.resolve(
      availability: widget.availability,
      states: states,
      hasError: widget.errorText != null,
    );
    final textStyle = theme.typography
        .fieldInput(context, widget.size, TypographyEmphasis.regular)
        .copyWith(color: style.foreground);
    final placeholderStyle = textStyle.copyWith(color: style.placeholder);
    final editable = EditableText(
      key: _editableTextKey,
      controller: widget.controller,
      focusNode: _focusNode,
      readOnly: _readOnly,
      style: textStyle,
      cursorColor: style.foreground,
      backgroundCursorColor: theme.surface.base,
      selectionColor: style.selection,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      autofocus: widget.autofocus && !_disabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      cursorWidth: context.units(theme.shapes.fieldCursorWidth),
      scrollPadding: EdgeInsets.all(
        context.units(theme.spacing.fieldScrollPaddingFor(widget.size)),
      ),
      keyboardAppearance: theme.brightness,
      rendererIgnoresPointer: true,
    );
    final interactiveEditable = _selectionGestureBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: editable,
    );
    final editor = Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        if (widget.controller.text.isEmpty && widget.placeholder != null)
          IgnorePointer(
            child: Text(widget.placeholder!, style: placeholderStyle),
          ),
        Semantics(
          container: true,
          textField: true,
          enabled: !_disabled,
          readOnly: _readOnly,
          multiline: widget.maxLines != 1,
          isRequired: widget.required ? true : null,
          label: widget.semanticLabel ?? widget.label,
          value: widget.controller.text,
          hint: widget.errorText ?? widget.description ?? widget.placeholder,
          child: ExcludeFocus(
            excluding: _disabled,
            child: IgnorePointer(
              ignoring: _disabled,
              child: interactiveEditable,
            ),
          ),
        ),
      ],
    );

    return MouseRegion(
      cursor: _disabled ? SystemMouseCursors.basic : SystemMouseCursors.text,
      onEnter: _disabled ? null : (_) => setState(() => _hovered = true),
      onExit: _disabled ? null : (_) => setState(() => _hovered = false),
      child: FieldShell(
        availability: widget.availability,
        size: widget.size,
        shape: widget.shape,
        states: states,
        label: widget.label,
        description: widget.description,
        errorText: widget.errorText,
        required: widget.required,
        leading: widget.leading,
        trailing: widget.trailing,
        fixedHeight: widget.minLines == 1 && widget.maxLines == 1,
        child: editor,
      ),
    );
  }
}
