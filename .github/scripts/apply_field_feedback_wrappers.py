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
