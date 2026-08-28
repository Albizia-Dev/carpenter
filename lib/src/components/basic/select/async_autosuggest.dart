import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import 'autosuggest.dart';

final class CarpenterSearchCancellation extends ChangeNotifier {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() { if (!_cancelled) { _cancelled = true; notifyListeners(); } }
}

typedef CarpenterSuggestionLoader<T> = Future<List<CarpenterOption<T>>> Function(String query, CarpenterSearchCancellation cancellation);

/// Async lifecycle wrapper for CarpenterAutosuggest with debounce and stale-result protection.
final class CarpenterAsyncAutosuggest<T> extends StatefulWidget {
  const CarpenterAsyncAutosuggest({
    super.key,
    required this.load,
    required this.onSelected,
    this.label,
    this.placeholder,
    this.minimumQueryLength = 1,
    this.debounce = const Duration(milliseconds: 300),
    this.availability = FieldAvailability.enabled,
  });

  final CarpenterSuggestionLoader<T> load;
  final ValueChanged<CarpenterOption<T>> onSelected;
  final String? label;
  final String? placeholder;
  final int minimumQueryLength;
  final Duration debounce;
  final FieldAvailability availability;

  @override
  State<CarpenterAsyncAutosuggest<T>> createState() => _CarpenterAsyncAutosuggestState<T>();
}

final class _CarpenterAsyncAutosuggestState<T> extends State<CarpenterAsyncAutosuggest<T>> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  CarpenterSearchCancellation? _cancellation;
  int _generation = 0;
  bool _open = false;
  OptionsLoadState _loadState = OptionsLoadState.ready;
  List<CarpenterOption<T>> _suggestions = const [];

  @override
  void dispose() {
    _timer?.cancel();
    _cancellation?.cancel();
    _cancellation?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _query(String source) {
    _timer?.cancel();
    final query = source.trim();
    if (query.length < widget.minimumQueryLength) {
      _cancellation?.cancel();
      setState(() {
        _suggestions = const [];
        _loadState = OptionsLoadState.ready;
        _open = false;
      });
      return;
    }
    _timer = Timer(widget.debounce, () => _load(query));
  }

  Future<void> _load(String query) async {
    final generation = ++_generation;
    _cancellation?.cancel();
    _cancellation?.dispose();
    final cancellation = CarpenterSearchCancellation();
    _cancellation = cancellation;
    setState(() {
      _loadState = OptionsLoadState.loading;
      _open = true;
    });
    try {
      final result = await widget.load(query, cancellation);
      if (!mounted || generation != _generation || cancellation.isCancelled) return;
      setState(() {
        _suggestions = result;
        _loadState = OptionsLoadState.ready;
      });
    } catch (_) {
      if (!mounted || generation != _generation || cancellation.isCancelled) return;
      setState(() => _loadState = OptionsLoadState.failed);
    }
  }

  @override
  Widget build(BuildContext context) => CarpenterAutosuggest<T>(
    controller: _controller,
    label: widget.label,
    placeholder: widget.placeholder,
    availability: widget.availability,
    open: _open,
    onOpenChanged: (value) => setState(() => _open = value),
    suggestions: _suggestions,
    loadState: _loadState,
    onQueryChanged: _query,
    onSuggestionSelected: (option) {
      widget.onSelected(option);
      setState(() => _open = false);
    },
  );
}
