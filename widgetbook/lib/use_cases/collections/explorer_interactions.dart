import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

/// Compact live example for the reusable explorer interaction primitives.
///
/// Applications keep actual selection, clipboard contents, edit state and
/// persistence outside Carpenter; this example intentionally demonstrates only
/// the presentation contracts that can be reused by project/file explorers.
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
  String _draft = 'Specifications';
  String _value = 'Specifications';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CarpenterExplorerLocationStrip<String>(
        value: _location,
        onChanged: (value) => setState(() => _location = value),
        destinations: const [
          CarpenterExplorerDestination(value: 'common', label: 'Common'),
          CarpenterExplorerDestination(value: 'p', label: 'Stage P'),
          CarpenterExplorerDestination(value: 'r', label: 'Stage R'),
        ],
        remembered: _remembered == null
            ? null
            : CarpenterExplorerDestination(
                value: _remembered!,
                label: _value,
              ),
      ),
      const SizedBox(height: 16),
      CarpenterInlineTextEdit(
        value: _value,
        draft: _draft,
        editing: _editing,
        onEditingChanged: (value) => setState(() => _editing = value),
        onDraftChanged: (value) => setState(() => _draft = value),
        onCommit: () {
          setState(() {
            _value = _draft;
            _editing = false;
            _remembered = 'specifications';
          });
        },
        onCancel: () {
          setState(() {
            _draft = _value;
            _editing = false;
          });
        },
      ),
    ],
  );
}
