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
/// The route captures the nearest Carpenter theme, default text style, and root
/// `rem` value before
/// entering the Navigator overlay. This keeps locally hosted Carpenter
/// subtrees working even when the application root belongs to another UI
/// system during an incremental migration.
///
/// Supply either [title], [content] and [actionsBuilder], or [builder]. The
/// builder runs inside the captured scopes and may create a stateful form that
/// owns a [CarpenterDialog] with `open: true`. That form handles dismissal through
/// `Navigator.pop`, including its `onOpenChanged` callback, and may return a typed
/// result. Do not combine the builder with the static presentation arguments.
Future<T?> showCarpenterDialog<T>({
  required BuildContext context,
  String? title,
  Widget? content,
  CarpenterDialogActionsBuilder<T>? actionsBuilder,
  WidgetBuilder? builder,
  DialogDismissPolicy dismissPolicy = DialogDismissPolicy.escapeOnly,
  String? semanticLabel,
  FocusNode? initialFocusNode,
}) {
  assert(
    builder != null
        ? title == null && content == null && actionsBuilder == null
        : title != null && content != null && actionsBuilder != null,
    'Provide either a dialog builder or title, content and actionsBuilder.',
  );
  final theme = CarpenterTheme.of(context);
  final rem = Px(context.units(const Rem(1)));
  final textStyle = DefaultTextStyle.of(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: semanticLabel ?? title ?? 'Dialog',
    barrierColor: const Color(0x00000000),
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, _) {
      void close([T? result]) {
        if (!dialogContext.mounted) return;
        final route = ModalRoute.of(dialogContext);
        if (route?.isCurrent != true) return;
        final navigator = Navigator.of(dialogContext);
        if (navigator.canPop()) navigator.pop<T>(result);
      }

      return UnitsRoot(
        rem: rem,
        child: CarpenterTheme(
          data: theme,
          child: textStyle.wrap(
            dialogContext,
            builder != null
                ? Builder(builder: builder)
                : CarpenterDialog(
                    open: true,
                    onOpenChanged: (open) {
                      if (!open) close();
                    },
                    title: title!,
                    content: content!,
                    actions: actionsBuilder!(close),
                    dismissPolicy: dismissPolicy,
                    initialFocusNode: initialFocusNode,
                    semanticLabel: semanticLabel,
                    child: const SizedBox.shrink(),
                  ),
          ),
        ),
      );
    },
  );
}

/// Modal geometry: forms occupy a trailing panel on wide viewports and a
/// full page on compact viewports. Dismissal and focus behavior stay identical.
enum CarpenterDialogPresentation {
  /// Standard centered confirmation or short interaction.
  centered,

  /// Trailing full-height form, occupying the viewport on compact screens.
  editor,
}

/// A controlled modal composition container with trapped keyboard focus.
final class CarpenterDialog extends StatelessWidget {
  /// Creates a controlled modal. [presentation] selects form geometry without
  /// changing the caller-owned open state, validation content, or actions.
  const CarpenterDialog({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.child,
    required this.title,
    required this.content,
    this.actions = const [],
    this.actionExecutionPhases = const {},
    this.dismissPolicy = DialogDismissPolicy.escapeOnly,
    this.initialFocusNode,
    this.semanticLabel,
    this.presentation = CarpenterDialogPresentation.centered,
  });

  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final Widget child;
  final String title;
  final Widget content;
  final List<CarpenterActionDescriptor> actions;

  /// Controlled execution phases keyed by action id. Missing ids are idle;
  /// callers own requests and rebuild this map as operations start and finish.
  final Map<String, ActionExecutionPhase> actionExecutionPhases;
  final DialogDismissPolicy dismissPolicy;
  final FocusNode? initialFocusNode;
  final String? semanticLabel;

  /// Form geometry; focus trapping and dismissal policy are unchanged.
  final CarpenterDialogPresentation presentation;

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
        final editor = presentation == CarpenterDialogPresentation.editor;
        final compact =
            info.overlaySize.width < context.units(theme.sizes.layoutNarrowEnd);
        final inset = editor
            ? 0.0
            : context.units(theme.spacing.overlayDialogViewportInset);
        return Align(
          alignment: editor ? AlignmentDirectional.centerEnd : Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(inset),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: editor
                    ? (compact
                          ? info.overlaySize.width
                          : context.units(theme.sizes.layoutNarrowEnd))
                    : context.units(theme.sizes.overlayDialogMaxWidth),
                minHeight: editor ? info.overlaySize.height : 0,
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
                                  CarpenterButton.fromAction(
                                    action,
                                    executionPhase:
                                        actionExecutionPhases[action.id] ??
                                        ActionExecutionPhase.idle,
                                    prominence: !editor
                                        ? ActionProminence.normal
                                        : action.colorRole ==
                                              ActionColorRole.primary
                                        ? ActionProminence.filled
                                        : ActionProminence.ghost,
                                  ),
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
