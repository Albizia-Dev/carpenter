import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/icon_data.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../../internal/rendering/focus_ring.dart';
import '../../../../internal/rendering/interactive_region.dart';
import '../../../basic/button/button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/input/input.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';
import '../../../collections/contracts/collection_load_phase.dart';

/// A visible destination in a workspace catalogue or navigation search.
///
/// [id] is opaque: Carpenter never parses routes or decides permission. Only
/// supplied destinations can be invoked; callers remove inaccessible items or
/// retain an unavailable pinned item with a human-readable [disabledReason].
@immutable
final class CarpenterNavigationDestination {
  /// Creates an immutable, backend-neutral destination with stable identity.
  const CarpenterNavigationDestination({
    required this.id,
    required this.label,
    required this.icon,
    this.description,
    this.enabled = true,
    this.disabledReason,
  });

  /// Stable identity independent from display text or list position.
  final String id;

  /// Primary visible destination name.
  final String label;

  /// Icon supplied through the Carpenter icon facade.
  final CarpenterIconSource icon;

  /// Workspace or contour description distinguishing similarly named pages.
  final String? description;

  /// Whether selection can be requested. Defaults to enabled.
  final bool enabled;

  /// Explanation shown for an unavailable retained destination.
  final String? disabledReason;
}

/// Searchable catalogue content for a caller-owned dialog or page.
///
/// Query, filtered results, loading and failures are controlled independently.
/// This component performs no search or network calls. During refresh existing
/// rows stay usable; initial loading without rows displays progress. Arrow keys
/// move focus between enabled destinations, Enter chooses the focused result
/// (or the first enabled result from the input), and Escape belongs to the host.
/// Tab follows ordinary control order. Focus nodes are ephemeral and disposed
/// here; [controller] and an optional [focusNode] remain caller-owned.
final class CarpenterNavigationPalette extends StatefulWidget {
  /// Creates catalogue content. The host bounds its height when necessary;
  /// rows wrap descriptions and remain scrollable with long content or scaling.
  const CarpenterNavigationPalette({
    super.key,
    required this.controller,
    required this.destinations,
    required this.onQueryChanged,
    required this.onSelected,
    this.selectedId,
    this.loadPhase = CollectionLoadPhase.ready,
    this.errorMessage,
    this.onRetry,
    this.placeholder = 'Название раздела или страницы',
    this.emptyLabel = 'Ничего не найдено',
    this.emptyDescription = 'Попробуйте другое название.',
    this.semanticLabel = 'Переход к разделу',
    this.focusNode,
    this.autofocus = true,
  });

  /// Caller-owned text editing state; never replaced or disposed by the palette.
  final TextEditingController controller;

  /// Already-filtered results with unique IDs, in application-defined order.
  final List<CarpenterNavigationDestination> destinations;

  /// Receives query edits; the caller rebuilds results and request state.
  final ValueChanged<String> onQueryChanged;

  /// Requests selection once for an enabled destination; does not dismiss a host.
  final ValueChanged<String> onSelected;

  /// Current application destination, distinct from transient keyboard focus.
  final String? selectedId;

  /// Current request phase; existing results remain visible while refreshing.
  final CollectionLoadPhase loadPhase;

  /// Safe user-facing failure text. Does not replace usable existing results.
  final String? errorMessage;

  /// Optional retry callback. No retry is scheduled internally.
  final VoidCallback? onRetry;

  /// Input hint and accessible name.
  final String placeholder;

  /// Heading when no destinations are available and no request is pending.
  final String emptyLabel;

  /// Supporting empty-result explanation, chosen by the application.
  final String emptyDescription;

  /// Accessible name for the catalogue content region.
  final String semanticLabel;

  /// Optional external input focus node; ownership remains with the caller.
  final FocusNode? focusNode;

  /// Whether the input requests focus when first mounted. Defaults to true.
  final bool autofocus;

  /// Owns transient row focus while preserving caller-owned query state.
  @override
  State<CarpenterNavigationPalette> createState() => _NavigationPaletteState();
}

final class _NavigationPaletteState extends State<CarpenterNavigationPalette> {
  final _nodes = <String, FocusNode>{};

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(CarpenterNavigationPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  void _syncNodes() {
    final ids = widget.destinations.map((d) => d.id).toSet();
    assert(
      ids.length == widget.destinations.length,
      'Destination IDs must be unique.',
    );
    for (final id in _nodes.keys.where((id) => !ids.contains(id)).toList()) {
      _nodes.remove(id)!.dispose();
    }
    for (final destination in widget.destinations) {
      _nodes.putIfAbsent(
        destination.id,
        () => FocusNode(debugLabel: 'Destination ${destination.id}'),
      );
    }
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        (event.logicalKey != LogicalKeyboardKey.arrowDown &&
            event.logicalKey != LogicalKeyboardKey.arrowUp)) {
      return KeyEventResult.ignored;
    }
    final enabled = widget.destinations.where((d) => d.enabled).toList();
    if (enabled.isEmpty) return KeyEventResult.handled;
    final index = enabled.indexWhere((d) => _nodes[d.id]!.hasFocus);
    final forwards = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final next = index < 0
        ? (forwards ? 0 : enabled.length - 1)
        : (index + (forwards ? 1 : -1) + enabled.length) % enabled.length;
    final target = _nodes[enabled[next].id]!;
    target.requestFocus();
    if (target.context case final context?) {
      Scrollable.ensureVisible(context);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final loading =
        widget.loadPhase == CollectionLoadPhase.initialLoading ||
        widget.loadPhase == CollectionLoadPhase.refreshing;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Focus(
        onKeyEvent: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterInput(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              placeholder: widget.placeholder,
              semanticLabel: widget.placeholder,
              leadingIcon: GravityIcons.magnifier,
              onChanged: widget.onQueryChanged,
              onSubmitted: (_) {
                final first = widget.destinations
                    .where((d) => d.enabled)
                    .firstOrNull;
                if (first != null) widget.onSelected(first.id);
              },
            ),
            SizedBox(height: gap),
            if (loading) ...[
              const CarpenterProgress(semanticLabel: 'Загружаем переходы'),
              SizedBox(height: gap),
            ],
            if (widget.errorMessage case final message?) ...[
              CarpenterText.feedback(
                message,
                feedbackRole: FeedbackColorRole.danger,
              ),
              if (widget.onRetry != null)
                CarpenterButton(
                  label: 'Повторить',
                  onPressed: widget.onRetry,
                  icon: GravityIcons.arrowRotateRight,
                  prominence: ActionProminence.ghost,
                ),
            ],
            if (widget.destinations.isEmpty &&
                !loading &&
                widget.errorMessage == null)
              Padding(
                padding: EdgeInsets.all(gap),
                child: Column(
                  children: [
                    CarpenterText.label(widget.emptyLabel),
                    SizedBox(height: gap),
                    CarpenterText.caption(
                      widget.emptyDescription,
                      colorRole: ContentColorRole.secondary,
                    ),
                  ],
                ),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.destinations.length,
                itemBuilder: (context, index) =>
                    _destination(context, widget.destinations[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destination(
    BuildContext context,
    CarpenterNavigationDestination destination,
  ) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final selected = widget.selectedId == destination.id;
    return Semantics(
      key: ValueKey(destination.id),
      button: true,
      enabled: destination.enabled,
      selected: selected,
      label: destination.label,
      hint: destination.disabledReason ?? destination.description,
      child: InteractiveRegion(
        focusNode: _nodes[destination.id],
        onActivate: destination.enabled
            ? () => widget.onSelected(destination.id)
            : null,
        builder: (context, states, showFocus) {
          final radius = BorderRadius.circular(
            context.units(theme.shapes.radius(ShapeRole.rounded)),
          );
          return FocusRing(
            visible: showFocus && states.contains(WidgetState.focused),
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: selected || states.contains(WidgetState.pressed)
                    ? theme.overlay.selected
                    : states.contains(WidgetState.hovered)
                    ? theme.overlay.hovered
                    : theme.actions.transparent,
              ),
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: Row(
                  children: [
                    CarpenterIcon(
                      destination.icon,
                      colorRole: destination.enabled
                          ? ContentColorRole.primary
                          : ContentColorRole.disabled,
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CarpenterText.label(
                            destination.label,
                            colorRole: destination.enabled
                                ? ContentColorRole.primary
                                : ContentColorRole.disabled,
                          ),
                          if ((destination.disabledReason ??
                                  destination.description)
                              case final description?)
                            CarpenterText.caption(
                              description,
                              colorRole: ContentColorRole.secondary,
                            ),
                        ],
                      ),
                    ),
                    if (selected) const CarpenterIcon(GravityIcons.check),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
