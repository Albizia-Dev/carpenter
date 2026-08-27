import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/status_indicator.dart';
import '../../../basic/text.dart';

enum CarpenterPageStateKind { initialLoading, zero, emptyResult, initialError }

final class CarpenterPageStatePresentation extends StatelessWidget {
  const CarpenterPageStatePresentation({
    super.key,
    required this.kind,
    required this.title,
    this.description,
    this.action,
    this.semanticLabel,
  });

  const CarpenterPageStatePresentation.loading({
    super.key,
    this.title = 'Loading',
    this.description,
    this.semanticLabel,
  }) : kind = CarpenterPageStateKind.initialLoading,
       action = null;

  final CarpenterPageStateKind kind;
  final String title;
  final String? description;
  final CarpenterActionDescriptor? action;
  final String? semanticLabel;

  FeedbackColorRole get _role => switch (kind) {
    CarpenterPageStateKind.initialError => FeedbackColorRole.danger,
    CarpenterPageStateKind.initialLoading => FeedbackColorRole.info,
    CarpenterPageStateKind.zero ||
    CarpenterPageStateKind.emptyResult => FeedbackColorRole.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutSection);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel ?? title,
      liveRegion: kind == CarpenterPageStateKind.initialLoading,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarpenterStatusIndicator(label: title, role: _role),
            if (description != null) ...[
              SizedBox(height: gap),
              CarpenterText.body(
                description!,
                colorRole: ContentColorRole.secondary,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              SizedBox(height: gap),
              CarpenterButton.fromAction(action!),
            ],
          ],
        ),
      ),
    );
  }
}
