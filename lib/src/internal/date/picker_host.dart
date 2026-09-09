import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../overlay/anchored_overlay_host.dart';
import '../overlay/overlay_surface.dart';

/// Date/time fields keep ordinary text editing and never own a modal route.
/// Touch platforms expand within the form; desktop uses a dismissible anchor.
final class PickerHost extends StatelessWidget {
  const PickerHost({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.field,
    required this.picker,
  });
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final Widget field;
  final Widget picker;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final inline =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
    final panel = Padding(
      padding: EdgeInsets.all(context.units(theme.spacing.medium)),
      child: picker,
    );
    if (inline) {
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              onOpenChanged(false),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field,
            if (open) ...[
              SizedBox(height: context.units(theme.spacing.small)),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.surface.base,
                  border: Border.all(color: theme.fields.border),
                  borderRadius: BorderRadius.circular(
                    context.units(theme.shapes.overlaySurfaceRadius),
                  ),
                ),
                child: panel,
              ),
            ],
          ],
        ),
      );
    }
    return AnchoredOverlayHost(
      open: open,
      onOpenChanged: onOpenChanged,
      anchor: field,
      allowAnchorInteraction: true,
      placement: OverlayPlacement.bottomStart,
      fallbackPlacements: const [OverlayPlacement.topStart],
      overlayBuilder: (_) => OverlaySurface(
        child: SizedBox(
          width: context.units(21.rem),
          child: SingleChildScrollView(child: panel),
        ),
      ),
    );
  }
}
