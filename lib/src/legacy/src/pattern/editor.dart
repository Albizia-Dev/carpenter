import 'dart:async';

import 'package:carpenter/src/legacy/src/block/page_blocks.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/page/capability.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/descriptor.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:carpenter/src/legacy/src/pattern/record.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

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

  Future<CarpenterValidationResult> validate() async {
    final validator = descriptor.validator;
    return validator == null
        ? const CarpenterValidationResult.valid()
        : await validator(value);
  }

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

class CarpenterEditorControllerBase<TRecord>
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
    for (final field in fields) {
      field.addListener(_fieldChanged);
    }
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

  void _fieldChanged() {
    value = CarpenterEditorReady(dirty: fields.any((field) => field.dirty));
  }

  @override
  Future<bool> validate() async {
    value = const CarpenterEditorValidating();
    final errors = <CarpenterFieldId, String>{};
    for (final field in fields) {
      final result = await field.validate();
      if (!result.isValid) {
        errors[field.descriptor.id] = result.message!;
      }
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
    for (final field in fields) {
      field.reset();
    }
    onCancel?.call();
  }

  @override
  void dispose() {
    for (final field in fields) {
      field.removeListener(_fieldChanged);
    }
    super.dispose();
  }
}

class CarpenterEditorSection extends CarpenterRecordSection {
  const CarpenterEditorSection({
    super.key,
    required super.id,
    required super.title,
    required super.child,
    super.description,
    super.commands,
    super.collapsible,
    super.initiallyExpanded,
  });
}

class CarpenterFieldGroup extends StatelessWidget {
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
      final effectiveColumns = constraints.maxWidth < 640 ? 1 : columns;
      final width =
          (constraints.maxWidth - (effectiveColumns - 1) * 12) /
          effectiveColumns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

/// Standard label, required marker, help and validation presentation.
class CarpenterFormField extends StatelessWidget {
  const CarpenterFormField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.error,
    this.description,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? error;
  final String? description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text.rich(
        TextSpan(
          text: label,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: context.face.color('status.danger')),
              ),
          ],
        ),
      ),
      if (description != null) ...[
        const SizedBox(height: 4),
        Text(
          description!,
          style: context.face
              .type('caption')
              .copyWith(color: context.face.color('text.secondary')),
        ),
      ],
      const SizedBox(height: 5),
      child,
      if (error != null) ...[
        const SizedBox(height: 4),
        Text(
          error!,
          style: context.face
              .type('caption')
              .copyWith(color: context.face.color('status.danger')),
        ),
      ],
    ],
  );
}

class CarpenterValidationSummary extends StatelessWidget {
  const CarpenterValidationSummary({super.key, required this.errors});

  final Map<CarpenterFieldId, String> errors;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();
    return CarpenterAttentionBlock(
      title: 'Проверьте заполнение',
      message: errors.values.join('\n'),
      tone: CarpenterNoticeTone.danger,
    );
  }
}

class CarpenterEditorPage<TRecord> extends StatelessWidget {
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
    CarpenterEditorSaving() => const CarpenterPageBlocking(
      message: 'Сохранение…',
    ),
    CarpenterEditorForbidden() => const CarpenterPageForbidden(),
    CarpenterEditorConflict(:final message) => CarpenterPageUnavailable(
      message: message ?? 'Запись была изменена другим пользователем.',
    ),
    _ => const CarpenterPageReady(),
  };

  @override
  Widget build(BuildContext context) {
    assert(descriptor.kind == CarpenterPageKind.editor);
    final customBody = body;
    return CarpenterPage(
      descriptor: descriptor,
      state: _pageState,
      header: header ?? CarpenterPageHeader(title: Text(descriptor.title)),
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
            ],
          ),
      commands: commands,
      commandBindings: commandBindings,
      capabilities: capabilities,
    );
  }
}
