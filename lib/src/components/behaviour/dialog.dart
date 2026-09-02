import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/overlay/overlay_lifecycle_host.dart';
import '../../internal/overlay/overlay_surface.dart';
import '../basic/button/button.dart';

typedef CarpenterDialogClose<T> = void Function([T? result]);
typedef CarpenterDialogActionsBuilder<T> =
    List<CarpenterActionDescriptor> Function(CarpenterDialogClose<T> close);

/// Opens a typed Carpenter modal route and completes with the value supplied
/// to an action's [CarpenterDialogClose].
///
/// The route captures the nearest Carpenter theme and root `rem` value before
/// entering the Navigator overlay. This keeps locally hosted Carpenter
/// subtrees working even when the application root belongs to another UI
/// system during an incremental migration.
Future<T?> showCarpenterDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required CarpenterDialogActionsBuilder<T> actionsBuilder,
  DialogDismissPolicy dismissPolicy = DialogDismissPolicy.escapeOnly,
  String? semanticLabel,
  FocusNode? initialFocusNode,
}) {
  final theme = CarpenterTheme.of(context);
  final rem = Px(context.units(const Rem(1)));

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: semanticLabel ?? title,
    barrierColor: const Color(0x00000000),
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, _) {
      void close([T? result]) {
        final navigator = Navigator.of(dialogContext);
        if (navigator.canPop()) navigator.pop<T>(result);
      }

      return UnitsRoot(
        rem: rem,
        child: CarpenterTheme(
          data: theme,
          child: CarpenterDialog(
            open: true,
            onOpenChanged: (open) {
              if (!open) close();
            },
            title: title,
            content: content,
            actions: actionsBuilder(close),
            dismissPolicy: dismissPolicy,
            initialFocusNode: initialFocusNode,
            semanticLabel: semanticLabel,
            child: const SizedBox.shrink(),
          ),
        ),
      );
    },
  );
}

/// A controlled modal composition container with trapped keyboard focus.
final class CarpenterDialog extends StatelessWidget {
  const CarpenterDialog({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.child,
    required this.title,
    required this.content,
    this.actions = const [],
    this.dismissPolicy = DialogDismissPolicy.escapeOnly,
    this.initialFocusNode,
    this.semanticLabel,
  });

  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final Widget child;
  final String title;
  final Widget content;
  final List<CarpenterActionDescriptor> actions;
  final DialogDismissPolicy dismissPolicy;
  final FocusNode? initialFocusNode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final dismissOutside =
        dismissPolicy == DialogDismissPolicy.outsideAndEscape;
    final dismissEscape = dismissPolicy != DialogDismissPolicy.explicitOnly;
    return OverlayLifecycleHost(
      open: open,
      onOpenChanged: onOpenChanged,
      modal: true,
      dismissOnOutside: dismissOutside,
      dismissOnEscape: dismissEscape,
      trapFocus: true,
      initialFocusNode: initialFocusNode,
      scrimColor: theme.overlay.scrim,
      overlayBuilder: (context, info, dismiss) {
        final inset = context.units(theme.spacing.overlayDialogViewportInset);
        return Center(
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.units(theme.sizes.overlayDialogMaxWidth),
                maxHeight: (info.overlaySize.height - inset * 2)
                    .clamp(0, info.overlaySize.height)
                    .toDouble(),
              ),
              child: Semantics(
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: semanticLabel ?? title,
                explicitChildNodes: true,
                child: OverlaySurface(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.typography
                              .dialogTitle(context, TypographyEmphasis.strong)
                              .copyWith(color: theme.overlay.foreground),
                        ),
                        SizedBox(
                          height: context.units(
                            theme.spacing.overlayDialogContentGap,
                          ),
                        ),
                        content,
                        if (actions.isNotEmpty) ...[
                          SizedBox(
                            height: context.units(
                              theme.spacing.overlayDialogContentGap,
                            ),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Wrap(
                              spacing: context.units(
                                theme.spacing.overlayDialogActionGap,
                              ),
                              runSpacing: context.units(
                                theme.spacing.overlayDialogActionGap,
                              ),
                              children: [
                                for (final action in actions)
                                  CarpenterButton.fromAction(action),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}
