import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/avatar.dart';
import '../basic/text.dart';

enum CarpenterFramePlatform { desktop, touch }

final class CarpenterTopPanelContext {
  const CarpenterTopPanelContext({
    required this.targetPlatform,
    required this.framePlatform,
  });
  final TargetPlatform targetPlatform;
  final CarpenterFramePlatform framePlatform;
  bool get isDesktop => framePlatform == CarpenterFramePlatform.desktop;
}

typedef CarpenterTopPanelBuilder =
    Widget Function(BuildContext context, CarpenterTopPanelContext frame);

final class CarpenterAppFrame extends StatelessWidget {
  const CarpenterAppFrame({
    super.key,
    required this.body,
    this.topPanel,
    this.sidebar,
    this.bottomBar,
  });

  final Widget body;
  final CarpenterTopPanelBuilder? topPanel;
  final Widget? sidebar;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final frame = CarpenterTopPanelContext(
      targetPlatform: defaultTargetPlatform,
      framePlatform: switch (defaultTargetPlatform) {
        TargetPlatform.android || TargetPlatform.iOS =>
          CarpenterFramePlatform.touch,
        _ => CarpenterFramePlatform.desktop,
      },
    );
    final header = topPanel?.call(context, frame);
    final main = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sidebar != null) sidebar!,
        Expanded(child: body),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null) header,
        Expanded(child: main),
        if (bottomBar != null) bottomBar!,
      ],
    );
  }
}

final class CarpenterTopPanel extends StatelessWidget {
  const CarpenterTopPanel({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.child,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final content =
        child ??
        Row(
          children: [
            leading ?? const CarpenterAvatar(initials: 'C', size: Rem(2)),
            SizedBox(width: gap),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    CarpenterText.label(
                      title!,
                      emphasis: TypographyEmphasis.strong,
                    ),
                  if (subtitle != null)
                    CarpenterText.caption(
                      subtitle!,
                      colorRole: ContentColorRole.secondary,
                    ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              SizedBox(width: gap),
              Wrap(spacing: gap / 2, runSpacing: gap / 2, children: actions),
            ],
          ],
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface.base,
        border: Border(
          bottom: BorderSide(
            color: theme.surface.border,
            width: context.units(theme.shapes.borderWidth),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gap, vertical: gap * .75),
        child: content,
      ),
    );
  }
}
