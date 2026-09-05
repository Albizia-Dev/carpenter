import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/icon_data.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/icon_renderer.dart';

final class CarpenterIcon extends StatelessWidget {
  const CarpenterIcon(
    this.icon, {
    super.key,
    this.size = IconSize.medium,
    this.colorRole = ContentColorRole.primary,
    this.semanticLabel,
  }) : feedbackRole = null;

  const CarpenterIcon.feedback(
    this.icon, {
    super.key,
    required this.feedbackRole,
    this.size = IconSize.medium,
    this.semanticLabel,
  }) : colorRole = ContentColorRole.primary;

  final CarpenterIconSource icon;
  final IconSize size;
  final ContentColorRole colorRole;
  final FeedbackColorRole? feedbackRole;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final color = feedbackRole == null
        ? theme.content.resolve(colorRole)
        : theme.feedback.resolve(feedbackRole!).foreground;
    return IconRenderer(
      icon: icon,
      size: context.units(theme.sizes.icon(size)),
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
