import 'package:carpenter/src/legacy/src/component/button/carpenter_button.dart';
import 'package:carpenter/src/legacy/src/component/text/carpenter_text.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Text;

/// Текстовое поле Carpenter.
///
/// `CarpenterInput` является controlled/uncontrolled field-компонентом. Если
/// передан `controller`, состояние текста хранит внешний код. Если controller
/// не передан, компонент создает внутренний `TextEditingController`.
class CarpenterInput extends StatefulWidget {
  /// Создает текстовое поле.
  const CarpenterInput({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.placeholder,
    this.prefix,
    this.suffix,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.obscureText = false,
    this.obscuringCharacter = '•',
  });

  /// Внешний controller текста.
  final TextEditingController? controller;

  /// Начальное значение для внутреннего controller.
  ///
  /// Используется только когда `controller` не передан.
  final String? initialValue;

  /// Внешний focus node.
  final FocusNode? focusNode;

  /// Подпись поля.
  final String? label;

  /// Placeholder внутри пустого поля.
  final String? placeholder;

  final Widget? prefix;

  final Widget? suffix;

  /// Текст ошибки под полем.
  final String? errorText;

  /// Доступность поля.
  final bool enabled;

  /// Обработчик изменения текста.
  final ValueChanged<String>? onChanged;

  /// Тип клавиатуры.
  final TextInputType? keyboardType;

  /// Форматтеры ввода.
  final List<TextInputFormatter>? inputFormatters;

  /// Максимальное количество строк.
  final int? maxLines;

  final TextCapitalization textCapitalization;

  final ValueChanged<String>? onSubmitted;

  /// Скрывает ввод, например для пароля.
  final bool obscureText;

  /// Символ, которым заменяются скрытые знаки.
  final String obscuringCharacter;

  @override
  State<CarpenterInput> createState() => _CarpenterInputState();
}

class _CarpenterInputState extends State<CarpenterInput>
    implements TextSelectionGestureDetectorBuilderDelegate {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late final TextSelectionGestureDetectorBuilder _selectionGestureDetector;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  bool get _ownsController => widget.controller == null;

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    _selectionGestureDetector = TextSelectionGestureDetectorBuilder(
      delegate: this,
    );
    _controller.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(CarpenterInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      final oldControllerWasInternal = oldWidget.controller == null;
      _controller.removeListener(_handleTextChanged);
      if (oldControllerWasInternal) {
        _controller.dispose();
      }
      _controller =
          widget.controller ?? TextEditingController(text: widget.initialValue);
      _controller.addListener(_handleTextChanged);
    } else if (_ownsController &&
        oldWidget.initialValue != widget.initialValue &&
        _controller.text == (oldWidget.initialValue ?? '')) {
      _controller.text = widget.initialValue ?? '';
    }

    if (oldWidget.focusNode != widget.focusNode) {
      final oldFocusNodeWasInternal = oldWidget.focusNode == null;
      _focusNode.removeListener(_handleFocusChanged);
      if (oldFocusNodeWasInternal) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChanged);
    }

    if (oldWidget.enabled && !widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsController) {
      _controller.dispose();
    }
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleTextChanged() {
    setState(() {});
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  Widget _buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    final face = context.face;
    return CustomSingleChildLayout(
      delegate: DesktopTextSelectionToolbarLayoutDelegate(
        anchor: editableTextState.contextMenuAnchors.primaryAnchor,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face.color('surface.raised'),
          border: Border.all(color: face.color('border.normal')),
          borderRadius: BorderRadius.circular(face.radius('lg')),
        ),
        child: Padding(
          padding: EdgeInsets.all(face.space('0.25')),
          child: Wrap(
            spacing: face.space('0.25'),
            runSpacing: face.space('0.25'),
            children: [
              for (final item in editableTextState.contextMenuButtonItems)
                CarpenterButton(
                  type: .outlined,
                  color: .secondary,
                  compact: true,
                  label: item.label ?? _contextMenuLabel(item.type),
                  onPressed: item.onPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _contextMenuLabel(ContextMenuButtonType type) => switch (type) {
    ContextMenuButtonType.cut => 'Вырезать',
    ContextMenuButtonType.copy => 'Копировать',
    ContextMenuButtonType.paste => 'Вставить',
    ContextMenuButtonType.selectAll => 'Выделить всё',
    ContextMenuButtonType.delete => 'Удалить',
    ContextMenuButtonType.lookUp => 'Найти',
    ContextMenuButtonType.searchWeb => 'Искать в интернете',
    ContextMenuButtonType.share => 'Поделиться',
    ContextMenuButtonType.liveTextInput => 'Ввод с камеры',
    ContextMenuButtonType.custom => 'Действие',
  };

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final hasError = widget.errorText != null;
    final borderColor = !widget.enabled
        ? face.color('border.subtle')
        : hasError
        ? face.color('status.danger')
        : _focusNode.hasFocus
        ? face.color('border.focus')
        : face.color('border.normal');
    final surfaceColor = widget.enabled
        ? face.color('surface.raised')
        : face.color('action.disabled');
    final textColor = widget.enabled
        ? face.color('text.primary')
        : face.color('text.disabled');

    final field = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: face.motion.fast,
        curve: face.motion.curve,
        constraints: BoxConstraints(minHeight: face.rem(2)),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(face.radius('md')),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.prefix != null) ...[
              Padding(
                padding: EdgeInsetsDirectional.only(start: face.space('0.75')),
                child: widget.prefix!,
              ),
              SizedBox(width: face.space('0.5')),
            ],
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  widget.prefix == null ? face.space('0.75') : 0,
                  face.space('0.5'),
                  face.space('0.75'),
                  face.space('0.5'),
                ),
                child: Stack(
                  children: [
                    if (_controller.text.isEmpty && widget.placeholder != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CarpenterText(
                              widget.placeholder!,
                              style: face
                                  .type('body')
                                  .copyWith(color: face.color('text.muted')),
                            ),
                          ),
                        ),
                      ),
                    DefaultTextEditingShortcuts(
                      child: IgnorePointer(
                        ignoring: !widget.enabled,
                        child: _selectionGestureDetector.buildGestureDetector(
                          behavior: HitTestBehavior.translucent,
                          child: EditableText(
                            key: editableTextKey,
                            controller: _controller,
                            focusNode: _focusNode,
                            readOnly: !widget.enabled,
                            enableInteractiveSelection: widget.enabled,
                            onChanged: widget.onChanged,
                            onSubmitted: widget.onSubmitted,
                            keyboardType: widget.keyboardType,
                            inputFormatters: widget.inputFormatters,
                            maxLines: widget.maxLines,
                            obscureText: widget.obscureText,
                            obscuringCharacter: widget.obscuringCharacter,
                            textCapitalization: widget.textCapitalization,
                            style: face.type('body').copyWith(color: textColor),
                            cursorColor: face.color('action.primary'),
                            backgroundCursorColor: face.color(
                              'action.disabled',
                            ),
                            selectionColor: face
                                .color('action.primary')
                                .withValues(alpha: 0.28),
                            contextMenuBuilder: Overlay.maybeOf(context) == null
                                ? null
                                : _buildContextMenu,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.suffix != null) widget.suffix!,
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          CarpenterText(
            widget.label!,
            variant: CarpenterTextVariant.labelStrong,
            tone: widget.enabled
                ? CarpenterTextTone.primary
                : CarpenterTextTone.disabled,
          ),
          SizedBox(height: face.space('0.25')),
        ],
        field,
        if (widget.errorText != null) ...[
          SizedBox(height: face.space('0.25')),
          CarpenterText(
            widget.errorText!,
            variant: CarpenterTextVariant.caption,
            tone: CarpenterTextTone.danger,
          ),
        ],
      ],
    );
  }
}
