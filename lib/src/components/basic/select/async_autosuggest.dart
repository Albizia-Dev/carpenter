import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import 'autosuggest.dart';

/// Cooperative cancellation signal for one suggestion request. Cancelling
/// notifies listeners once but does not abort HTTP or other transport work
/// automatically.
final class CarpenterSearchCancellation extends ChangeNotifier {
  bool _cancelled = false;

  /// Whether cancellation has been requested. Once true, it remains true for
  /// the lifetime of this signal.
  bool get isCancelled => _cancelled;

  /// Marks the request cancelled and notifies listeners on the first call
  /// only. Loaders should check isCancelled after asynchronous work or
  /// connect this signal to their transport cancellation mechanism.
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      notifyListeners();
    }
  }
}

/// Loads options for a trimmed query and a per-request cancellation signal.
/// Return the complete suggestion list for that query. The autosuggest owns
/// the signal and ignores cancelled or superseded completions; the loader
/// owns any transport resources.
typedef CarpenterSuggestionLoader<T> =
    Future<List<CarpenterOption<T>>> Function(
      String query,
      CarpenterSearchCancellation cancellation,
    );

/// Async lifecycle wrapper for CarpenterAutosuggest with debounce and stale-result protection.
final class CarpenterAsyncAutosuggest<T> extends StatefulWidget {
  /// Creates a suggestion field with an owned text controller, debounce
  /// timer, and per-request cancellation. The parent handles selected
  /// options; this wrapper does not expose an external text controller.
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

  /// Asynchronous source called after the debounce delay with a trimmed query
  /// meeting minimumQueryLength. Thrown errors select the failed options
  /// state rather than escaping through the widget callback.
  final CarpenterSuggestionLoader<T> load;

  /// Receives the selected option before the suggestion popup is closed.
  /// Store or process the option value in application state.
  final ValueChanged<CarpenterOption<T>> onSelected;

  /// Optional visible field label forwarded to the underlying autosuggest.
  final String? label;

  /// Hint shown by the underlying autosuggest when its owned text controller
  /// is empty.
  final String? placeholder;

  /// Minimum trimmed character count before a request is scheduled. Shorter
  /// input cancels the current signal, clears suggestions, and closes the
  /// popup. Defaults to one.
  final int minimumQueryLength;

  /// Delay after the latest query edit before starting its request; defaults
  /// to 300 milliseconds. Editing restarts the timer. An already running
  /// request is superseded when the next load starts.
  final Duration debounce;

  /// Editing availability forwarded to the underlying autosuggest. Defaults
  /// to enabled.
  final FieldAvailability availability;

  /// Creates the text, timer, popup, and request-generation state. Disposal
  /// cancels timers and the current request signal and disposes the owned
  /// controller.
  @override
  State<CarpenterAsyncAutosuggest<T>> createState() =>
      _CarpenterAsyncAutosuggestState<T>();
}

final class _CarpenterAsyncAutosuggestState<T>
    extends State<CarpenterAsyncAutosuggest<T>> {
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
      if (!mounted || generation != _generation || cancellation.isCancelled)
        return;
      setState(() {
        _suggestions = result;
        _loadState = OptionsLoadState.ready;
      });
    } catch (_) {
      if (!mounted || generation != _generation || cancellation.isCancelled)
        return;
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
