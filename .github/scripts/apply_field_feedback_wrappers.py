from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, got {count}: {old!r}')
    target.write_text(text.replace(old, new))


# Masked input.
path = 'lib/src/components/basic/input/masked_input.dart'
replace_once(path, "import '../../../foundation/roles.dart';\nimport 'input.dart';\n", "import '../../../foundation/roles.dart';\nimport 'field_shell.dart';\nimport 'input.dart';\n")
replace_once(path, '    this.description,\n    this.errorText,\n', '    this.description,\n    this.feedback,\n    this.errorText,\n')
replace_once(path, '  final String? description;\n  final String? errorText;\n', '  final String? description;\n  final CarpenterFieldFeedback? feedback;\n  final String? errorText;\n')
replace_once(path, '    description: description,\n    errorText: errorText,\n', '    description: description,\n    feedback: feedback,\n    errorText: errorText,\n')

# Number input.
path = 'lib/src/components/basic/input/number_input.dart'
replace_once(path, "import '../../../foundation/roles.dart';\nimport 'input.dart';\n", "import '../../../foundation/roles.dart';\nimport 'field_shell.dart';\nimport 'input.dart';\n")
replace_once(path, '    this.description,\n    this.errorText,\n', '    this.description,\n    this.feedback,\n    this.errorText,\n')
replace_once(path, '  final String? description;\n  final String? errorText;\n', '  final String? description;\n  final CarpenterFieldFeedback? feedback;\n  final String? errorText;\n')
replace_once(path, '    description: widget.description,\n    errorText: widget.errorText ?? _localError,\n', '    description: widget.description,\n    feedback: widget.feedback,\n    errorText: widget.errorText ?? _localError,\n')

# Date input.
path = 'lib/src/components/basic/input/date_input.dart'
replace_once(path, "import 'adaptive_picker.dart';\nimport 'masked_input.dart';\n", "import 'adaptive_picker.dart';\nimport 'field_shell.dart';\nimport 'masked_input.dart';\n")
replace_once(path, '    this.description,\n    this.errorText,\n', '    this.description,\n    this.feedback,\n    this.errorText,\n')
replace_once(path, '  final String? description;\n  final String? errorText;\n', '  final String? description;\n  final CarpenterFieldFeedback? feedback;\n  final String? errorText;\n')
replace_once(path, '        description: widget.description,\n        errorText: widget.errorText ?? _validationError,\n', '        description: widget.description,\n        feedback: widget.feedback,\n        errorText: widget.errorText ?? _validationError,\n')

# Date range input.
path = 'lib/src/components/basic/input/date_range_input.dart'
replace_once(path, "import 'date_input.dart';\nimport 'masked_input.dart';\n", "import 'date_input.dart';\nimport 'field_shell.dart';\nimport 'masked_input.dart';\n")
replace_once(path, '    this.description,\n    this.errorText,\n', '    this.description,\n    this.feedback,\n    this.errorText,\n')
replace_once(path, '  final String? description;\n  final String? errorText;\n', '  final String? description;\n  final CarpenterFieldFeedback? feedback;\n  final String? errorText;\n')
replace_once(path, '        description: widget.description,\n        errorText: widget.errorText ?? _validationError,\n', '        description: widget.description,\n        feedback: widget.feedback,\n        errorText: widget.errorText ?? _validationError,\n')

# Time input.
path = 'lib/src/components/basic/input/time_input.dart'
replace_once(path, "import 'adaptive_picker.dart';\nimport 'masked_input.dart';\n", "import 'adaptive_picker.dart';\nimport 'field_shell.dart';\nimport 'masked_input.dart';\n")
replace_once(path, '    this.description,\n    this.errorText,\n', '    this.description,\n    this.feedback,\n    this.errorText,\n')
replace_once(path, '  final String? description;\n  final String? errorText;\n', '  final String? description;\n  final CarpenterFieldFeedback? feedback;\n  final String? errorText;\n')
replace_once(path, '        description: widget.description,\n        errorText: widget.errorText ?? _validationError,\n', '        description: widget.description,\n        feedback: widget.feedback,\n        errorText: widget.errorText ?? _validationError,\n')

# File input.
path = 'lib/src/components/basic/input/file_input.dart'
replace_once(path, "import '../text.dart';\nimport 'input.dart';\n", "import '../text.dart';\nimport 'field_shell.dart';\nimport 'input.dart';\n")
replace_once(path, '    this.description,\n    this.errorText,\n', '    this.description,\n    this.feedback,\n    this.errorText,\n')
replace_once(path, '  final String? description;\n  final String? errorText;\n', '  final String? description;\n  final CarpenterFieldFeedback? feedback;\n  final String? errorText;\n')
replace_once(path, '            description: widget.description,\n            errorText: widget.errorText,\n', '            description: widget.description,\n            feedback: widget.feedback,\n            errorText: widget.errorText,\n')

# Input Widgetbook feedback matrix.
path = 'widgetbook/lib/use_cases/basic/input.dart'
replace_once(
    path,
    "    WidgetbookUseCase(name: 'Availability', builder: _availabilityComparison),\n    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),\n",
    "    WidgetbookUseCase(name: 'Availability', builder: _availabilityComparison),\n    WidgetbookUseCase(name: 'Feedback', builder: _feedbackComparison),\n    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),\n",
)
replace_once(
    path,
    "Widget _availabilityComparison(BuildContext context) =>\n    preview(const _InputAvailabilityComparison());\n\n",
    "Widget _availabilityComparison(BuildContext context) =>\n    preview(const _InputAvailabilityComparison());\n\nWidget _feedbackComparison(BuildContext context) => previewColumn(const [\n  _InputPreview(\n    initialText: 'Draft',\n    label: 'Information',\n    feedback: CarpenterFieldFeedback.info('Saved remotely'),\n  ),\n  _InputPreview(\n    initialText: 'Approved',\n    label: 'Success',\n    feedback: CarpenterFieldFeedback.success('Ready to submit'),\n  ),\n  _InputPreview(\n    initialText: 'Needs review',\n    label: 'Warning',\n    feedback: CarpenterFieldFeedback.warning('Check this value'),\n  ),\n  _InputPreview(\n    initialText: 'Invalid',\n    label: 'Danger',\n    feedback: CarpenterFieldFeedback.danger('Enter a valid value'),\n  ),\n]);\n\n",
)
replace_once(
    path,
    "    this.description,\n    this.errorText,\n",
    "    this.description,\n    this.feedback,\n    this.errorText,\n",
)
replace_once(
    path,
    "  final String? description;\n  final String? errorText;\n",
    "  final String? description;\n  final CarpenterFieldFeedback? feedback;\n  final String? errorText;\n",
)
replace_once(
    path,
    "    description: widget.description,\n    errorText: widget.errorText,\n",
    "    description: widget.description,\n    feedback: widget.feedback,\n    errorText: widget.errorText,\n",
)
