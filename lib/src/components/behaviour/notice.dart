import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/card.dart';
import '../basic/text.dart';

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
    return Semantics(
      container: true,
      liveRegion:
          tone == CarpenterNoticeTone.danger ||
          tone == CarpenterNoticeTone.warning,
      child: CarpenterCard.feedback(
        role: _role,
        padded: false,
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final details = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarpenterText.feedback(
                    title,
                    feedbackRole: _role,
                    role: TypographyRole.label,
                    emphasis: TypographyEmphasis.strong,
                  ),
                  if (message != null) ...[
                    SizedBox(height: gap / 2),
                    CarpenterText.feedback(message!, feedbackRole: _role),
                  ],
                ],
              );
              final actions = <Widget>[
                if (action != null) CarpenterButton.fromAction(action!),
                if (onClose != null)
                  CarpenterButton(
                    label: 'Close',
                    size: ControlSize.small,
                    prominence: ActionProminence.ghost,
                    onInvoke: onClose,
                  ),
              ];
              if (actions.isEmpty) return details;
              if (constraints.maxWidth < context.units(32.5.rem)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    SizedBox(height: gap),
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: details),
                  SizedBox(width: gap),
                  ...actions,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
