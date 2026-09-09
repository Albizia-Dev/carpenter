import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final explorerInteractionsComponent = WidgetbookComponent(
  name: 'Explorer interactions',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _explorerInteractions),
  ],
);

Widget _explorerInteractions(BuildContext context) =>
    preview(const SizedBox(width: 640, child: ExplorerInteractionsExample()));

/// Compact live example for the reusable explorer interaction primitives.
///
/// Applications keep actual selection, clipboard contents, edit state and
/// persistence outside Carpenter; this example intentionally demonstrates only
/// presentation contracts that can be reused by project/file explorers.
final class ExplorerInteractionsExample extends StatefulWidget {
  const ExplorerInteractionsExample({super.key});

  @override
  State<ExplorerInteractionsExample> createState() =>
      _ExplorerInteractionsExampleState();
}

final class _ExplorerInteractionsExampleState
    extends State<ExplorerInteractionsExample> {
  String _location = 'common';
  String? _remembered = 'specifications';
  bool _editing = false;
  bool _genericEditing = false;
  String _draft = 'Specifications';
  String _value = 'Specifications';

  @override
  Widget build(BuildContext context) => CarpenterUndoScope(
    child: CarpenterClipboardScope<String>(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterExplorerLocationStrip<String>(
            primaryDestinations: const [
              CarpenterExplorerDestination<String>(
                location: 'common',
                label: 'Common',
              ),
              CarpenterExplorerDestination<String>(
                location: 'p',
                label: 'Stage P',
              ),
              CarpenterExplorerDestination<String>(
                location: 'r',
                label: 'Stage R',
              ),
            ],
            rememberedDestination: _remembered == null
                ? null
                : CarpenterExplorerDestination<String>(
                    location: _remembered!,
                    label: _value,
                  ),
            current: _location,
            onChanged: (value) => setState(() => _location = value),
          ),
          const SizedBox(height: 16),
          CarpenterInlineTextEdit(
            value: _value,
            draft: _draft,
            editing: _editing,
            onDraftChanged: (value) => setState(() => _draft = value),
            onEditRequested: () => setState(() {
              _draft = _value;
              _editing = true;
            }),
            onCommitRequested: () => setState(() {
              _value = _draft;
              _editing = false;
              _remembered = 'specifications';
            }),
            onCancelRequested: () => setState(() {
              _draft = _value;
              _editing = false;
            }),
          ),
          const SizedBox(height: 16),
          CarpenterInlineEdit(
            editing: _genericEditing,
            value: const CarpenterText.body('Custom value slot'),
            editor: const CarpenterText.body('Custom editor slot'),
            onEditRequested: () => setState(() => _genericEditing = true),
            onCommitRequested: () => setState(() => _genericEditing = false),
            onCancelRequested: () => setState(() => _genericEditing = false),
          ),
        ],
      ),
    ),
  );
}
