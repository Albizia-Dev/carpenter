import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final validationComponent = WidgetbookComponent(
  name: 'Form Validation',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => preview(
        ValidationPreview(
          showDescription: context.knobs.boolean(
            label: 'Content \u00b7 Show description',
            initialValue: true,
          ),
        ),
      ),
    ),
  ],
);

/// An editable field with real validation, not a manually painted error state.
final class ValidationPreview extends StatefulWidget {
  const ValidationPreview({super.key, this.showDescription = true});
  final bool showDescription;
  @override
  State<ValidationPreview> createState() => _ValidationPreviewState();
}

final class _ValidationPreviewState extends State<ValidationPreview> {
  static const _nameId = CarpenterFieldId('name');
  final _text = TextEditingController();
  late final CarpenterFieldBinding<String> _field;
  late final CarpenterEditorControllerBase<String> _editor;
  @override
  void initState() {
    super.initState();
    _field = CarpenterFieldBinding(
      descriptor: CarpenterFieldDescriptor<String>(
        id: _nameId,
        label: 'Name',
        validator: (value) => value.trim().isEmpty
            ? const CarpenterValidationResult.invalid('Enter a name')
            : const CarpenterValidationResult.valid(),
      ),
      value: '',
    );
    _editor = CarpenterEditorControllerBase<String>(
      mode: CarpenterEditorMode.create,
      fields: [_field],
      onSave: (values) async => values[_nameId]! as String,
    );
  }

  @override
  void dispose() {
    _editor.dispose();
    _field.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _editor,
    builder: (context, _) {
      final state = _editor.value;
      final errors = state is CarpenterEditorValidationFailure
          ? state.errors
          : <CarpenterFieldId, String>{};
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterFormField(
            label: 'Name',
            required: true,
            error: errors[_nameId],
            description: widget.showDescription
                ? 'Validation is invoked explicitly; edits remain in the draft.'
                : null,
            child: CarpenterInput(
              controller: _text,
              semanticLabel: 'Draft name',
              onChanged: (value) => _field.value = value,
            ),
          ),
          SizedBox(height: context.units(1.rem)),
          CarpenterButton(
            label: 'Validate draft',
            onPressed: () async {
              await _editor.validate();
            },
          ),
          SizedBox(height: context.units(1.rem)),
          CarpenterValidationSummary(errors: errors),
          CarpenterText.caption(
            'Dirty: ${_field.dirty}; errors: ${errors.length}',
          ),
        ],
      );
    },
  );
}
