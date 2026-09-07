import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../basic/button/icon_button.dart';
import '../basic/gravity_icons.g.dart';
import '../basic/input/input.dart';
import '../basic/text.dart';
import '../../foundation/roles.dart';

final class _InlineCommitIntent extends Intent {
  const _InlineCommitIntent();
}

final class _InlineCancelIntent extends Intent {
  const _InlineCancelIntent();
}

/// Controlled inline-edit chrome shared by table cells, definition lists, and
/// other structured-value surfaces.
///
/// Carpenter owns focus/keyboard/action presentation while the caller owns the
/// meaningful edit state and persistence. The idle pencil becomes a checkmark
/// while editing; Enter commits and Escape cancels by default.
final class CarpenterInlineEdit extends StatelessWidget {
  const CarpenterInlineEdit({
    super.key,
    required this.editing,
    required this.value,
    required this.editor,
    required this.onEditRequested,
    required this.onCommitRequested,
    required this.onCancelRequested,
    this.committing = false,
    this.enabled = true,
    this.commitOnEnter = true,
    this.errorText,
    this.editSemanticLabel = 'Edit value',
    this.commitSemanticLabel = 'Save value',
    this.actionSize = ControlSize.xsmall,
  });

  final bool editing;
  final Widget value;
  final Widget editor;
  final VoidCallback? onEditRequested;
  final VoidCallback? onCommitRequested;
  final VoidCallback? onCancelRequested;
  final bool committing;
  final bool enabled;
  final bool commitOnEnter;
  final String? errorText;
  final String editSemanticLabel;
  final String commitSemanticLabel;
  final ControlSize actionSize;

  @override
  Widget build(BuildContext context) {
    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: editing ? editor : value),
        CarpenterIconButton(
          icon: editing ? GravityIcons.check : GravityIcons.pencil,
          semanticLabel: editing ? commitSemanticLabel : editSemanticLabel,
          prominence: ActionProminence.ghost,
          size: actionSize,
          executionPhase: committing
              ? ActionExecutionPhase.running
              : ActionExecutionPhase.idle,
          onPressed: !enabled || committing
              ? null
              : editing
              ? onCommitRequested
              : onEditRequested,
        ),
      ],
    );

    if (errorText case final message?) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          CarpenterText.feedback(
            message,
            feedbackRole: FeedbackColorRole.danger,
            role: TypographyRole.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    if (!editing) return content;
    return Actions(
      actions: <Type, Action<Intent>>{
        _InlineCommitIntent: CallbackAction<_InlineCommitIntent>(
          onInvoke: (_) {
            if (!committing && enabled) onCommitRequested?.call();
            return null;
          },
        ),
        _InlineCancelIntent: CallbackAction<_InlineCancelIntent>(
          onInvoke: (_) {
            if (!committing) onCancelRequested?.call();
            return null;
          },
        ),
      },
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          if (commitOnEnter)
            const SingleActivator(LogicalKeyboardKey.enter):
                const _InlineCommitIntent(),
          const SingleActivator(LogicalKeyboardKey.escape):
              const _InlineCancelIntent(),
        },
        child: content,
      ),
    );
  }
}

/// Controlled single-line inline text editor with Carpenter field styling and
/// the standard pencil/check interaction.
///
/// [draft] remains caller-owned. The widget owns only the ephemeral Flutter
/// text/focus objects required to render that draft.
final class CarpenterInlineTextEdit extends StatefulWidget {
  const CarpenterInlineTextEdit({
    super.key,
    required this.value,
    required this.draft,
    required this.editing,
    required this.onDraftChanged,
    required this.onEditRequested,
    required this.onCommitRequested,
    required this.onCancelRequested,
    this.committing = false,
    this.enabled = true,
    this.errorText,
    this.semanticLabel,
    this.editSemanticLabel = 'Edit value',
    this.commitSemanticLabel = 'Save value',
    this.actionSize = ControlSize.xsmall,
    this.fieldSize = FieldSize.small,
    this.placeholder,
  });

  final String value;
  final String draft;
  final bool editing;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback? onEditRequested;
  final VoidCallback? onCommitRequested;
  final VoidCallback? onCancelRequested;
  final bool committing;
  final bool enabled;
  final String? errorText;
  final String? semanticLabel;
  final String editSemanticLabel;
  final String commitSemanticLabel;
  final ControlSize actionSize;
  final FieldSize fieldSize;
  final String? placeholder;

  @override
  State<CarpenterInlineTextEdit> createState() =>
      _CarpenterInlineTextEditState();
}

final class _CarpenterInlineTextEditState
    extends State<CarpenterInlineTextEdit> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.draft,
  );
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(CarpenterInlineTextEdit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.draft != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.draft,
        selection: TextSelection.collapsed(offset: widget.draft.length),
      );
    }
    if (!oldWidget.editing && widget.editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterInlineEdit(
    editing: widget.editing,
    committing: widget.committing,
    enabled: widget.enabled,
    errorText: widget.editing ? null : widget.errorText,
    editSemanticLabel: widget.editSemanticLabel,
    commitSemanticLabel: widget.commitSemanticLabel,
    actionSize: widget.actionSize,
    onEditRequested: widget.onEditRequested,
    onCommitRequested: widget.onCommitRequested,
    onCancelRequested: widget.onCancelRequested,
    value: CarpenterText.body(
      widget.value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    editor: CarpenterInput(
      controller: _controller,
      focusNode: _focusNode,
      size: widget.fieldSize,
      placeholder: widget.placeholder,
      semanticLabel: widget.semanticLabel,
      availability: widget.enabled
          ? FieldAvailability.enabled
          : FieldAvailability.disabled,
      errorText: widget.errorText,
      onChanged: widget.onDraftChanged,
      onSubmitted: (_) {
        if (!widget.committing && widget.enabled) {
          widget.onCommitRequested?.call();
        }
      },
    ),
  );
}
