import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/card.dart';
import '../basic/text.dart';
import '../basic/button/icon_button.dart';
import '../basic/gravity_icons.g.dart';
import '../../internal/rendering/icon_renderer.dart';

/// Semantic feedback surface for page and action-level messages.
enum CarpenterNoticeTone { neutral, info, success, warning, danger }

final class CarpenterNotice extends StatelessWidget {
  const CarpenterNotice({
    super.key,
    required this.title,
    this.message,
    this.tone = CarpenterNoticeTone.info,
    this.action,
    this.onClose,
  });

  final String title;
  final String? message;
  final CarpenterNoticeTone tone;
  final CarpenterActionDescriptor? action;
  final VoidCallback? onClose;

  FeedbackColorRole get _role => switch (tone) {
    CarpenterNoticeTone.neutral => FeedbackColorRole.neutral,
    CarpenterNoticeTone.info => FeedbackColorRole.info,
    CarpenterNoticeTone.success => FeedbackColorRole.success,
    CarpenterNoticeTone.warning => FeedbackColorRole.warning,
    CarpenterNoticeTone.danger => FeedbackColorRole.danger,
  };

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final style = theme.feedback.resolve(_role);
    final iconSize = context.units(theme.sizes.actionIcon(ControlSize.medium));
    return Semantics(
      container: true,
      liveRegion:
          tone == CarpenterNoticeTone.danger ||
          tone == CarpenterNoticeTone.warning,
      child: CarpenterCard(
        padded: false,
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final indent = constraints.maxWidth >= context.units(28.rem)
                  ? iconSize + gap
                  : 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: context.units(.125.rem)),
                        child: IconRenderer(
                          icon: switch (tone) {
                            CarpenterNoticeTone.neutral ||
                            CarpenterNoticeTone.info => GravityIcons.circleInfo,
                            CarpenterNoticeTone.success =>
                              GravityIcons.circleCheck,
                            CarpenterNoticeTone.warning =>
                              GravityIcons.triangleExclamation,
                            CarpenterNoticeTone.danger =>
                              GravityIcons.circleExclamation,
                          },
                          size: iconSize,
                          color: style.foreground,
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: CarpenterText.feedback(
                          title,
                          feedbackRole: _role,
                          role: TypographyRole.label,
                          emphasis: TypographyEmphasis.strong,
                        ),
                      ),
                      if (onClose != null) ...[
                        SizedBox(width: gap / 2),
                        CarpenterIconButton(
                          icon: GravityIcons.xmark,
                          semanticLabel: 'Close notice',
                          size: ControlSize.small,
                          prominence: ActionProminence.ghost,
                          onInvoke: onClose,
                        ),
                      ],
                    ],
                  ),
                  if (message != null && message!.isNotEmpty) ...[
                    SizedBox(height: gap / 2),
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: indent),
                      child: CarpenterText(
                        message!,
                        colorRole: ContentColorRole.secondary,
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    SizedBox(height: gap),
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: indent),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: CarpenterButton.fromAction(
                          action!,
                          size: ControlSize.small,
                          prominence: ActionProminence.outlined,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
