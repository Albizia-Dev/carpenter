import 'package:flutter/widgets.dart';

import '../../../internal/selection/menu_panel.dart';
import 'menu_entry.dart';

/// A keyboard- and pointer-operable list of semantic actions.
final class CarpenterMenu extends StatelessWidget {
  const CarpenterMenu({
    super.key,
    required this.items,
    this.onDismissRequested,
    this.autofocus = true,
    this.semanticLabel,
  });

  final List<CarpenterMenuItem> items;
  final VoidCallback? onDismissRequested;
  final bool autofocus;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => MenuPanel(
    entries: [
      for (final item in items)
        if (item.action.visible)
          MenuPanelEntry(
            id: item.effectiveId,
            label: item.action.label,
            semanticLabel: item.action.effectiveSemanticLabel,
            semanticHint: item.action.disabledReason,
            icon: item.action.icon,
            enabled: item.action.isEnabled,
            selected: item.selected,
            onActivate: item.action.onInvoke,
          ),
    ],
    onDismissRequested: onDismissRequested,
    autofocus: autofocus,
    semanticLabel: semanticLabel,
  );
}
