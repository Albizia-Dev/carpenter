import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../application/command.dart';
import '../components/basic/text.dart';
import '../components/behaviour/notice.dart';
import '../components/layout/page_header.dart';
import '../components/layout/patterns/page_body.dart';
import '../components/layout/patterns/page_blocks.dart';
import '../foundation/roles.dart';
import '../foundation/theme.dart';
import '../page/capability.dart';
import '../page/descriptor.dart';
import '../page/page.dart';
import '../page/state.dart';

extension type const CarpenterFieldId(String value) {}

enum CarpenterEditorMode { create, edit }

sealed class CarpenterEditorState {
  const CarpenterEditorState();
}

final class CarpenterEditorInitialLoading extends CarpenterEditorState {
  const CarpenterEditorInitialLoading();
}

final class CarpenterEditorReady extends CarpenterEditorState {
  const CarpenterEditorReady({required this.dirty});
  final bool dirty;
}

final class CarpenterEditorValidating extends CarpenterEditorState {
  const CarpenterEditorValidating();
}

final class CarpenterEditorSaving extends CarpenterEditorState {
  const CarpenterEditorSaving();
}

final class CarpenterEditorSaved extends CarpenterEditorState {
  const CarpenterEditorSaved();
}

final class CarpenterEditorValidationFailure extends CarpenterEditorState {
  const CarpenterEditorValidationFailure(this.errors);
  final Map<CarpenterFieldId, String> errors;
}

final class CarpenterEditorSaveFailure extends CarpenterEditorState {
  const CarpenterEditorSaveFailure(this.error);
  final Object error;
}

final class CarpenterEditorConflict extends CarpenterEditorState {
  const CarpenterEditorConflict({this.message});
  final String? message;
}

final class CarpenterEditorForbidden extends CarpenterEditorState {
  const CarpenterEditorForbidden();
}

final class CarpenterValidationResult {
  const CarpenterValidationResult.valid() : message = null;
  const CarpenterValidationResult.invalid(this.message);
  final String? message;
  bool get isValid => message == null;
}

final class CarpenterFieldContext {
  const CarpenterFieldContext({required this.mode, required this.values});
  final CarpenterEditorMode mode;
  final Map<CarpenterFieldId, Object?> values;
}

@immutable
final class CarpenterFieldDescriptor<TValue> {
  const CarpenterFieldDescriptor({
    required this.id,
    required this.label,
    this.description,
    this.formatter,
    this.parser,
    this.validator,
    this.visibility,
    this.editability,
  });
  final CarpenterFieldId id;
  final String label;
  final String? description;
  final String Function(TValue value)? formatter;
  final TValue Function(String raw)? parser;
  final FutureOr<CarpenterValidationResult> Function(TValue value)? validator;
  final bool Function(CarpenterFieldContext context)? visibility;
  final bool Function(CarpenterFieldContext context)? editability;
}

final class CarpenterFieldBinding<T> extends ValueNotifier<T> {
  CarpenterFieldBinding({required this.descriptor, required T value})
    : initialValue = value,
      super(value);
  final CarpenterFieldDescriptor<T> descriptor;
  final T initialValue;
  bool get dirty => value != initialValue;
  Future<CarpenterValidationResult> validate() async =>
      descriptor.validator == null
      ? const CarpenterValidationResult.valid()
      : await descriptor.validator!(value);
  void reset() => value = initialValue;
}

abstract interface class CarpenterEditorController<TRecord>
    implements ValueListenable<CarpenterEditorState> {
  CarpenterEditorMode get mode;
  List<CarpenterFieldBinding<dynamic>> get fields;
  Future<bool> validate();
  Future<TRecord?> save();
  void cancel();
}

final class CarpenterEditorControllerBase<TRecord>
    extends ValueNotifier<CarpenterEditorState>
    implements CarpenterEditorController<TRecord> {
  CarpenterEditorControllerBase({
    required this.mode,
    required this.fields,
    required Future<TRecord> Function(Map<CarpenterFieldId, Object?> values)
    onSave,
    this.onCancel,
  }) : _onSave = onSave,
       super(const CarpenterEditorReady(dirty: false)) {
    for (final field in fields) field.addListener(_fieldChanged);
  }
  @override
  final CarpenterEditorMode mode;
  @override
  final List<CarpenterFieldBinding<dynamic>> fields;
  final Future<TRecord> Function(Map<CarpenterFieldId, Object?> values) _onSave;
  final VoidCallback? onCancel;
  Map<CarpenterFieldId, Object?> get values => {
    for (final field in fields) field.descriptor.id: field.value,
  };
  void _fieldChanged() =>
      value = CarpenterEditorReady(dirty: fields.any((field) => field.dirty));
  @override
  Future<bool> validate() async {
    value = const CarpenterEditorValidating();
    final errors = <CarpenterFieldId, String>{};
    for (final field in fields) {
      final result = await field.validate();
      if (!result.isValid) errors[field.descriptor.id] = result.message!;
    }
    value = errors.isEmpty
        ? CarpenterEditorReady(dirty: fields.any((field) => field.dirty))
        : CarpenterEditorValidationFailure(errors);
    return errors.isEmpty;
  }

  @override
  Future<TRecord?> save() async {
    if (!await validate()) return null;
    value = const CarpenterEditorSaving();
    try {
      final result = await _onSave(values);
      value = const CarpenterEditorSaved();
      return result;
    } catch (error) {
      value = CarpenterEditorSaveFailure(error);
      return null;
    }
  }

  @override
  void cancel() {
    for (final field in fields) field.reset();
    onCancel?.call();
  }

  @override
  void dispose() {
    for (final field in fields) field.removeListener(_fieldChanged);
    super.dispose();
  }
}

final class CarpenterFieldGroup extends StatelessWidget {
  const CarpenterFieldGroup({
    super.key,
    required this.children,
    this.columns = 1,
  });
  final List<Widget> children;
  final int columns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      final effective = constraints.maxWidth < context.units(40.rem)
          ? 1
          : columns;
      final width = (constraints.maxWidth - (effective - 1) * gap) / effective;
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

/// Presentational form row combining a label, optional help text, a
/// caller-owned editor, and an optional error notice. It does not bind or
/// validate the editor automatically.
final class CarpenterFormField extends StatelessWidget {
  /// Wraps an editor with form-level labeling and error presentation. The
  /// caller runs validation and passes the resulting error; required only
  /// adds a marker.
  const CarpenterFormField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.error,
    this.description,
  });

  /// Visible label above the editor. A required marker is appended when
  /// required is true.
  final String label;

  /// Caller-owned editing widget. Bind its value and callbacks explicitly;
  /// the wrapper creates no field controller.
  final Widget child;

  /// Whether the label includes a required marker. Does not install a
  /// validator or reject empty values.
  final bool required;

  /// Optional error message rendered as a danger notice below the editor.
  /// Null removes the notice.
  final String? error;

  /// Optional supporting text between the label and editor. Unlike the basic
  /// field shell, this form wrapper can show description and error together.
  final String? description;

  /// Composes the label, help text, editor, and danger notice in vertical
  /// order with theme spacing.
  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterText.label(
          required ? '$label *' : label,
          emphasis: TypographyEmphasis.strong,
        ),
        if (description != null) ...[
          SizedBox(height: gap / 2),
          CarpenterText.caption(
            description!,
            colorRole: ContentColorRole.secondary,
          ),
        ],
        SizedBox(height: gap / 2),
        child,
        if (error != null) ...[
          SizedBox(height: gap / 2),
          CarpenterNotice(title: error!, tone: CarpenterNoticeTone.danger),
        ],
      ],
    );
  }
}

/// Form-level summary of externally computed field errors. An empty map
/// produces no visible content.
final class CarpenterValidationSummary extends StatelessWidget {
  /// Displays the supplied field errors without running validators or
  /// modifying field state.
  const CarpenterValidationSummary({super.key, required this.errors});

  /// Messages keyed by stable field IDs. Values are joined in map iteration
  /// order; field IDs are not displayed as labels.
  final Map<CarpenterFieldId, String> errors;

  /// Returns an empty box when there are no errors, otherwise a danger
  /// attention block containing all messages separated by newlines.
  @override
  Widget build(BuildContext context) => errors.isEmpty
      ? const SizedBox.shrink()
      : CarpenterAttentionBlock(
          title: 'Check the form',
          message: errors.values.join('\n'),
          tone: CarpenterNoticeTone.danger,
        );
}

final class CarpenterEditorPage<TRecord> extends StatelessWidget {
  const CarpenterEditorPage({
    super.key,
    required this.descriptor,
    required this.editorState,
    this.body,
    this.header,
    this.summary,
    this.attention,
    this.sections = const [],
    this.commands = const [],
    this.commandBindings = const [],
    this.capabilities = const [],
  });
  final CarpenterPageDescriptor descriptor;
  final CarpenterEditorState editorState;
  final Widget? body;
  final Widget? header;
  final Widget? summary;
  final Widget? attention;
  final List<Widget> sections;
  final List<CarpenterCommand<dynamic>> commands;
  final List<CarpenterCommandBinding<dynamic>> commandBindings;
  final List<CarpenterPageCapability> capabilities;

  CarpenterPageState get _pageState => switch (editorState) {
    CarpenterEditorInitialLoading() => const CarpenterPageInitialLoading(),
    CarpenterEditorSaving() => const CarpenterPageBlocking(message: 'Saving…'),
    CarpenterEditorForbidden() => const CarpenterPageForbidden(),
    CarpenterEditorConflict(:final message) => CarpenterPageUnavailable(
      message: message ?? 'The record was changed elsewhere.',
    ),
    _ => const CarpenterPageReady(),
  };

  @override
  Widget build(BuildContext context) {
    assert(descriptor.kind == CarpenterPageKind.editor);
    return CarpenterPage(
      descriptor: descriptor,
      state: _pageState,
      header: header ?? CarpenterPageHeader(title: descriptor.title),
      commands: commands,
      commandBindings: commandBindings,
      capabilities: capabilities,
      body:
          body ??
          CarpenterPageBody(
            children: [
              if (summary != null) summary!,
              if (editorState case CarpenterEditorValidationFailure(
                :final errors,
              ))
                CarpenterValidationSummary(errors: errors),
              if (editorState case CarpenterEditorSaveFailure(:final error))
                CarpenterAttentionBlock(
                  title: 'Save failed',
                  message: error.toString(),
                  tone: CarpenterNoticeTone.danger,
                ),
              if (attention != null) attention!,
              ...sections,
            ],
          ),
    );
  }
}
