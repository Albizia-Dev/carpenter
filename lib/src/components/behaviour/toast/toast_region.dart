import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import 'toast.dart';
import 'toaster_controller.dart';

/// Hosts a bounded visible toast stack and queues the controller remainder.
final class CarpenterToastRegion extends StatefulWidget {
  const CarpenterToastRegion({
    super.key,
    required this.controller,
    required this.child,
    this.maxVisible = 3,
  }) : assert(maxVisible > 0);

  final CarpenterToasterController controller;
  final Widget child;
  final int maxVisible;

  @override
  State<CarpenterToastRegion> createState() => _CarpenterToastRegionState();
}

final class _CarpenterToastRegionState extends State<CarpenterToastRegion> {
  final Map<Object, _ToastLifetime> _lifetimes = {};
  final Map<Object, CarpenterToastDescriptor> _lifetimeDescriptors = {};

  List<CarpenterToastDescriptor> get _visible =>
      widget.controller.toasts.take(widget.maxVisible).toList(growable: false);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(CarpenterToastRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleChanged);
      for (final lifetime in _lifetimes.values) {
        lifetime.dispose();
      }
      _lifetimes.clear();
      _lifetimeDescriptors.clear();
      widget.controller.addListener(_handleChanged);
    }
  }

  void _handleChanged() {
    if (mounted) setState(() {});
  }

  void _syncLifetimes(
    BuildContext context,
    List<CarpenterToastDescriptor> visible,
  ) {
    final visibleIds = visible.map((toast) => toast.id).toSet();
    for (final removed
        in _lifetimes.keys.where((id) => !visibleIds.contains(id)).toList()) {
      _lifetimes.remove(removed)?.dispose();
      _lifetimeDescriptors.remove(removed);
    }
    final theme = CarpenterTheme.of(context);
    for (final toast in visible) {
      if (!identical(_lifetimeDescriptors[toast.id], toast)) {
        _lifetimes.remove(toast.id)?.dispose();
        _lifetimeDescriptors[toast.id] = toast;
      }
      _lifetimes.putIfAbsent(
        toast.id,
        () => _ToastLifetime(
          duration: toast.duration == ToastDuration.persistent
              ? null
              : theme.motion.toastDuration(toast.duration).toDuration(),
          onElapsed: () => widget.controller.dismiss(toast.id),
        ),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    for (final lifetime in _lifetimes.values) {
      lifetime.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final visible = _visible;
    _syncLifetimes(context, visible);
    final inset = context.units(theme.spacing.overlayToastRegionInset);
    return Stack(
      children: [
        widget.child,
        PositionedDirectional(
          top: inset,
          end: inset,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < visible.length; index++) ...[
                  _TimedToast(
                    key: ValueKey(visible[index].id),
                    descriptor: visible[index],
                    lifetime: _lifetimes[visible[index].id]!,
                    onDismiss: () =>
                        widget.controller.dismiss(visible[index].id),
                  ),
                  if (index != visible.length - 1)
                    SizedBox(
                      height: context.units(theme.spacing.overlayToastGap),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

final class _TimedToast extends StatefulWidget {
  const _TimedToast({
    super.key,
    required this.descriptor,
    required this.lifetime,
    required this.onDismiss,
  });

  final CarpenterToastDescriptor descriptor;
  final _ToastLifetime lifetime;
  final VoidCallback onDismiss;

  @override
  State<_TimedToast> createState() => _TimedToastState();
}

final class _TimedToastState extends State<_TimedToast> {
  var _hovered = false;
  var _focused = false;

  void _syncPause() {
    if (_hovered || _focused) {
      widget.lifetime.pause();
    } else {
      widget.lifetime.resume();
    }
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (value) {
      _focused = value;
      _syncPause();
    },
    child: MouseRegion(
      onEnter: (_) {
        _hovered = true;
        _syncPause();
      },
      onExit: (_) {
        _hovered = false;
        _syncPause();
      },
      child: CarpenterToast(
        descriptor: widget.descriptor,
        onDismiss: widget.onDismiss,
      ),
    ),
  );
}

final class _ToastLifetime {
  _ToastLifetime({required Duration? duration, required this.onElapsed})
    : _remaining = duration {
    resume();
  }

  Duration? _remaining;
  final VoidCallback onElapsed;
  Timer? _timer;
  DateTime? _startedAt;

  void pause() {
    final remaining = _remaining;
    final startedAt = _startedAt;
    if (_timer == null || remaining == null || startedAt == null) return;
    _timer!.cancel();
    _timer = null;
    _remaining = remaining - DateTime.now().difference(startedAt);
    _startedAt = null;
  }

  void resume() {
    final remaining = _remaining;
    if (remaining == null || _timer != null) return;
    if (remaining <= Duration.zero) {
      onElapsed();
      return;
    }
    _startedAt = DateTime.now();
    _timer = Timer(remaining, onElapsed);
  }

  void dispose() => _timer?.cancel();
}
