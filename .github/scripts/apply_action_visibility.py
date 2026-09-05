from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, got {count}: {old!r}')
    target.write_text(text.replace(old, new))


# Command projection preserves logical visibility and disabled reason.
path = 'lib/src/application/command.dart'
replace_once(
    path,
    '''    final current = state.value;\n    final available =\n        current.visibility == CarpenterCommandVisibility.visible &&\n        current.enabled &&\n        current.execution != CarpenterCommandExecution.executing;\n    return CarpenterActionDescriptor(\n      id: id,\n      label: label ?? title,\n      semanticLabel: semanticLabel,\n      icon: icon,\n      colorRole: colorRole ?? _commandColorRole(presentation),\n      shortcut: shortcut ?? (shortcuts.isEmpty ? null : shortcuts.first),\n      onInvoke: available\n''',
    '''    final current = state.value;\n    final visible = current.visibility == CarpenterCommandVisibility.visible;\n    final available =\n        visible &&\n        current.enabled &&\n        current.execution != CarpenterCommandExecution.executing;\n    return CarpenterActionDescriptor(\n      id: id,\n      label: label ?? title,\n      semanticLabel: semanticLabel,\n      icon: icon,\n      colorRole: colorRole ?? _commandColorRole(presentation),\n      shortcut: shortcut ?? (shortcuts.isEmpty ? null : shortcuts.first),\n      visible: visible,\n      disabledReason: available ? null : current.disabledReason,\n      onInvoke: available\n''',
)

# Action strips omit hidden descriptors before width resolution.
path = 'lib/src/components/behaviour/action_strip.dart'
replace_once(
    path,
    '''    final entries = [\n      for (final item in items)\n        ActionOverflowEntry(\n''',
    '''    final entries = [\n      for (final item in items)\n        if (item.action.visible)\n          ActionOverflowEntry(\n''',
)

# Menus omit hidden descriptors and expose disabled reasons semantically.
path = 'lib/src/components/behaviour/menu/menu.dart'
replace_once(
    path,
    '''    entries: [\n      for (final item in items)\n        MenuPanelEntry(\n          id: item.effectiveId,\n          label: item.action.label,\n          semanticLabel: item.action.effectiveSemanticLabel,\n          icon: item.action.icon,\n          enabled: item.action.isEnabled,\n          selected: item.selected,\n          onActivate: item.action.onInvoke,\n        ),\n    ],\n''',
    '''    entries: [\n      for (final item in items)\n        if (item.action.visible)\n          MenuPanelEntry(\n            id: item.effectiveId,\n            label: item.action.label,\n            semanticLabel: item.action.effectiveSemanticLabel,\n            semanticHint: item.action.disabledReason,\n            icon: item.action.icon,\n            enabled: item.action.isEnabled,\n            selected: item.selected,\n            onActivate: item.action.onInvoke,\n          ),\n    ],\n''',
)

# Menu panel can carry an explanatory accessibility hint.
path = 'lib/src/internal/selection/menu_panel.dart'
replace_once(
    path,
    '''    required this.semanticLabel,\n    required this.enabled,\n    required this.onActivate,\n    this.icon,\n''',
    '''    required this.semanticLabel,\n    required this.enabled,\n    required this.onActivate,\n    this.semanticHint,\n    this.icon,\n''',
)
replace_once(
    path,
    '''  final String semanticLabel;\n  final CarpenterIconSource? icon;\n''',
    '''  final String semanticLabel;\n  final String? semanticHint;\n  final CarpenterIconSource? icon;\n''',
)
replace_once(
    path,
    '''      selected: entry.selected,\n      label: entry.semanticLabel,\n      onTap: entry.enabled ? onActivate : null,\n''',
    '''      selected: entry.selected,\n      label: entry.semanticLabel,\n      hint: entry.semanticHint,\n      onTap: entry.enabled ? onActivate : null,\n''',
)

# ActionControl can expose a descriptor's disabled reason to accessibility.
path = 'lib/src/internal/rendering/action_control.dart'
replace_once(
    path,
    '''    required this.childBuilder,\n    this.focusNode,\n''',
    '''    required this.childBuilder,\n    this.semanticHint,\n    this.focusNode,\n''',
)
replace_once(
    path,
    '''  final String semanticLabel;\n  final VoidCallback? onInvoke;\n''',
    '''  final String semanticLabel;\n  final String? semanticHint;\n  final VoidCallback? onInvoke;\n''',
)
replace_once(
    path,
    '''      enabled: onInvoke != null,\n      label: semanticLabel,\n      value: _running ? 'running' : null,\n''',
    '''      enabled: onInvoke != null,\n      label: semanticLabel,\n      hint: semanticHint,\n      value: _running ? 'running' : null,\n''',
)

# Descriptor-backed text buttons respect logical visibility and reason.
path = 'lib/src/components/basic/button/button.dart'
for marker in [
    "  }) : assert(\n         onPressed == null || onInvoke == null,",
    "  }) : prominence = ActionProminence.filled,\n       assert(\n         onPressed == null || onInvoke == null,",
    "  }) : prominence = ActionProminence.outlined,\n       assert(\n         onPressed == null || onInvoke == null,",
    "  }) : prominence = ActionProminence.ghost,\n       assert(\n         onPressed == null || onInvoke == null,",
]:
    if marker.startswith('  }) : assert'):
        replacement = "  }) : _visible = true,\n       _semanticHint = null,\n       assert(\n         onPressed == null || onInvoke == null,"
    else:
        prefix = marker.split('       assert')[0]
        replacement = prefix + "       _visible = true,\n       _semanticHint = null,\n       assert(\n         onPressed == null || onInvoke == null,"
    replace_once(path, marker, replacement)
replace_once(
    path,
    '''       semanticLabel = action.semanticLabel,\n       colorRole = action.colorRole;\n''',
    '''       semanticLabel = action.semanticLabel,\n       colorRole = action.colorRole,\n       _visible = action.visible,\n       _semanticHint = action.disabledReason;\n''',
)
replace_once(
    path,
    '''  final String? semanticLabel;\n\n  VoidCallback? get _effectiveOnPressed => onPressed ?? onInvoke;\n\n  @override\n  Widget build(BuildContext context) {\n    return ActionControl(\n      semanticLabel: semanticLabel ?? label,\n''',
    '''  final String? semanticLabel;\n  final bool _visible;\n  final String? _semanticHint;\n\n  VoidCallback? get _effectiveOnPressed => onPressed ?? onInvoke;\n\n  @override\n  Widget build(BuildContext context) {\n    if (!_visible) return const SizedBox.shrink();\n    return ActionControl(\n      semanticLabel: semanticLabel ?? label,\n      semanticHint: _semanticHint,\n''',
)

# Descriptor-backed icon buttons follow the same contract.
path = 'lib/src/components/basic/button/icon_button.dart'
replace_once(
    path,
    '''  }) : assert(\n         onPressed == null || onInvoke == null,\n''',
    '''  }) : _visible = true,\n       _semanticHint = null,\n       assert(\n         onPressed == null || onInvoke == null,\n''',
)
replace_once(
    path,
    '''       onInvoke = null,\n       colorRole = action.colorRole;\n''',
    '''       onInvoke = null,\n       colorRole = action.colorRole,\n       _visible = action.visible,\n       _semanticHint = action.disabledReason;\n''',
)
replace_once(
    path,
    '''  final bool autofocus;\n\n  VoidCallback? get _effectiveOnPressed => onPressed ?? onInvoke;\n\n  @override\n  Widget build(BuildContext context) {\n    return ActionControl(\n      semanticLabel: semanticLabel,\n''',
    '''  final bool autofocus;\n  final bool _visible;\n  final String? _semanticHint;\n\n  VoidCallback? get _effectiveOnPressed => onPressed ?? onInvoke;\n\n  @override\n  Widget build(BuildContext context) {\n    if (!_visible) return const SizedBox.shrink();\n    return ActionControl(\n      semanticLabel: semanticLabel,\n      semanticHint: _semanticHint,\n''',
)
