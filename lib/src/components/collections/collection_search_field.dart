import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../basic/input/input.dart';
import 'contracts/collection_lifecycle_controller.dart';

/// Search field bound to a [CollectionLifecycleController].
///
/// Debounce, cancellation and stale-response protection remain controller-owned;
/// this widget only keeps the text editor synchronized with the query.
final class CarpenterCollectionSearchField<T, K, F> extends StatefulWidget {
  const CarpenterCollectionSearchField({
    super.key,
    required this.controller,
    this.label = 'Search',
    this.placeholder,
    this.width = const Rem(32.5),
  });

  final CollectionLifecycleController<T, K, F> controller;
  final String label;
  final String? placeholder;
  final LengthUnit width;

  @override
  State<CarpenterCollectionSearchField<T, K, F>> createState() =>
      _CarpenterCollectionSearchFieldState<T, K, F>();
}

final class _CarpenterCollectionSearchFieldState<T, K, F>
    extends State<CarpenterCollectionSearchField<T, K, F>> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.query.search ?? '',
  );
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncFromController);
  }

  @override
  void didUpdateWidget(CarpenterCollectionSearchField<T, K, F> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromController);
      widget.controller.addListener(_syncFromController);
      _syncFromController();
    }
  }

  void _syncFromController() {
    if (_focusNode.hasFocus) return;
    final value = widget.controller.query.search ?? '';
    if (_text.text == value) return;
    _text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    _focusNode.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: context.units(widget.width),
    child: CarpenterInput(
      controller: _text,
      focusNode: _focusNode,
      label: widget.label,
      placeholder: widget.placeholder,
      onChanged: widget.controller.updateSearch,
    ),
  );
}
