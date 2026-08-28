import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import 'status_indicator.dart';

/// Semantic tag tone retained from the previous Carpenter API.
enum CarpenterTagTone { neutral, success, warning, danger, info }

/// Compact semantic tag backed by the current status-indicator primitive.
final class CarpenterTag extends StatelessWidget {
  const CarpenterTag({
    super.key,
    required this.label,
    this.tone = CarpenterTagTone.neutral,
  });

  final String label;
  final CarpenterTagTone tone;

  @override
  Widget build(BuildContext context) => CarpenterStatusIndicator(
    label: label,
    role: switch (tone) {
      CarpenterTagTone.neutral => FeedbackColorRole.neutral,
      CarpenterTagTone.success => FeedbackColorRole.success,
      CarpenterTagTone.warning => FeedbackColorRole.warning,
      CarpenterTagTone.danger => FeedbackColorRole.danger,
      CarpenterTagTone.info => FeedbackColorRole.info,
    },
  );
}
