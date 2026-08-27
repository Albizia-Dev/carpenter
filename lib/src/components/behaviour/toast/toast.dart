import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/button/button.dart';

@immutable
final class CarpenterToastDescriptor {
  const CarpenterToastDescriptor({
    required this.id,
    required this.message,
    this.title,
    this.role = FeedbackColorRole.info,
    this.action,
    this.duration = ToastDuration.short,
    this.dismissLabel = 'Dismiss notification',
  });

  final Object id;
  final String? title;
  final String message;
  final FeedbackColorRole role;
  final CarpenterActionDescriptor? action;
  final ToastDuration duration;
  final String dismissLabel;
}

/// The semantic visual representation of one toast notification.
final class CarpenterToast extends StatelessWidget {
  const CarpenterToast({
    super.key,
    required this.descriptor,
    required this.onDismiss,
  });

  final CarpenterToastDescriptor descriptor;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final style = theme.feedback.resolve(descriptor.role);
    final action = descriptor.action;
    final radius = BorderRadius.circular(
      context.units(theme.shapes.toastRadius),
    );
    return Semantics(
      container: true,
      liveRegion: true,
      label: [descriptor.title, descriptor.message].nonNulls.join('. '),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.units(theme.sizes.overlayToastMaxWidth),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: radius,
            border: Border.all(
              color: style.foreground,
              width: context.units(theme.shapes.overlayBorderWidth),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(
              context.units(theme.spacing.overlaySurfacePadding),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (descriptor.title != null)
                  Text(
                    descriptor.title!,
                    style: theme.typography
                        .toastTitle(context, TypographyEmphasis.strong)
                        .copyWith(color: style.foreground),
                  ),
                if (descriptor.title != null)
                  SizedBox(
                    height: context.units(theme.spacing.overlayToastContentGap),
                  ),
                Text(
                  descriptor.message,
                  style: theme.typography
                      .toastMessage(context, TypographyEmphasis.regular)
                      .copyWith(color: style.foreground),
                ),
                SizedBox(
                  height: context.units(theme.spacing.overlayToastContentGap),
                ),
                Wrap(
                  spacing: context.units(theme.spacing.overlayDialogActionGap),
                  runSpacing: context.units(
                    theme.spacing.overlayDialogActionGap,
                  ),
                  children: [
                    if (action != null)
                      CarpenterButton.fromAction(
                        CarpenterActionDescriptor(
                          id: action.id,
                          label: action.label,
                          icon: action.icon,
                          semanticLabel: action.semanticLabel,
                          colorRole: action.colorRole,
                          onInvoke: action.onInvoke == null
                              ? null
                              : () {
                                  action.onInvoke!();
                                  onDismiss();
                                },
                        ),
                        prominence: ActionProminence.ghost,
                        size: ControlSize.small,
                      ),
                    CarpenterButton(
                      label: descriptor.dismissLabel,
                      prominence: ActionProminence.ghost,
                      size: ControlSize.small,
                      onInvoke: onDismiss,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
