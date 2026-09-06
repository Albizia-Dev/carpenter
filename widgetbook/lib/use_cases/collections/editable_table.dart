import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final editableTableComponent = WidgetbookComponent(
  name: 'Editable Table',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final empty = context.knobs.boolean(label: 'Data \u00b7 Start empty');
        return preview(
          EditableTablePreview(key: ValueKey(empty), initiallyEmpty: empty),
        );
      },
    ),
  ],
);

final class _DraftRow {
  _DraftRow(this.id, String name, this.amount)
    : name = TextEditingController(text: name);
  final int id;
  final TextEditingController name;
  num? amount;
  void dispose() => name.dispose();
}

/// Caller-owned row editing, selection, addition, removal, and footer totals.
final class EditableTablePreview extends StatefulWidget {
  const EditableTablePreview({super.key, this.initiallyEmpty = false});
  final bool initiallyEmpty;
  @override
  State<EditableTablePreview> createState() => _EditableTablePreviewState();
}

final class _EditableTablePreviewState extends State<EditableTablePreview> {
  late final List<_DraftRow> _rows;
  int _nextId = 3;
  int? _selected;
  String _activated = 'Nothing activated';
  @override
  void initState() {
    super.initState();
    _rows = widget.initiallyEmpty
        ? []
        : [_DraftRow(1, 'Planning', 240), _DraftRow(2, 'Materials', 1250)];
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _remove(_DraftRow row) {
    setState(() {
      _rows.remove(row);
      if (_selected == row.id) _selected = null;
    });
    // Inputs detach their listeners when the removed row unmounts.
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CarpenterEditableTable<_DraftRow>(
        items: _rows,
        semanticLabel: 'Draft invoice lines',
        selected: (row) => row.id == _selected,
        onRowSelected: (row) => setState(() => _selected = row.id),
        onRowActivated: (row) => setState(() => _activated = row.name.text),
        headerActions: [
          CarpenterButton(
            label: 'Add row',
            onPressed: () =>
                setState(() => _rows.add(_DraftRow(_nextId++, '', 0))),
          ),
        ],
        columns: [
          CarpenterTableColumn<_DraftRow>.custom(
            id: 'name',
            header: 'Description',
            cellBuilder: (context, row) => CarpenterInput(
              key: ValueKey('name-${row.id}'),
              controller: row.name,
              semanticLabel: 'Line ${row.id} description',
            ),
          ),
          CarpenterTableColumn<_DraftRow>.custom(
            id: 'amount',
            header: 'Amount',
            alignment: CarpenterTableColumnAlignment.end,
            width: CarpenterTableColumnWidth.fixed(width: 12.rem),
            cellBuilder: (context, row) => CarpenterNumberInput(
              key: ValueKey('amount-${row.id}'),
              value: row.amount,
              semanticLabel: 'Line ${row.id} amount',
              allowNegative: false,
              onChanged: (value) => setState(() => row.amount = value),
            ),
          ),
          CarpenterTableColumn<_DraftRow>.custom(
            id: 'remove',
            header: 'Actions',
            width: CarpenterTableColumnWidth.fixed(width: 7.rem),
            cellBuilder: (context, row) => CarpenterButton.text(
              label: 'Remove',
              semanticLabel: 'Remove line ${row.id}',
              onPressed: () => _remove(row),
            ),
          ),
        ],
        footerCells: {
          'name': (context, rows) =>
              CarpenterTableText.header('${rows.length} draft lines'),
          'amount': (context, rows) => CarpenterTableText.cell(
            rows.fold<num>(0, (sum, row) => sum + (row.amount ?? 0)).toString(),
          ),
        },
      ),
      SizedBox(height: context.units(1.rem)),
      CarpenterText.caption('Activated: $_activated'),
    ],
  );
}
