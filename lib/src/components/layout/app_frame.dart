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

typedef CarpenterTopPanelBuilder = Widget Function(
  BuildContext context,
  CarpenterTopPanelContext panel,
);

/// Lightweight cross-platform frame retained for apps that do not need ApplicationShell regions.
final class CarpenterAppFrame extends StatelessWidget {
  const CarpenterAppFrame({
    super.key,
    required this.child,
    this.topPanelBuilder,
    this.desktopTopPanelBuilder,
    this.targetPlatform,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
  });

  final Widget child;
  final CarpenterTopPanelBuilder? topPanelBuilder;
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;
  final TargetPlatform? targetPlatform;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final platform = targetPlatform ?? defaultTargetPlatform;
    final panelContext = CarpenterTopPanelContext(
      targetPlatform: platform,
      framePlatform: _isDesktop(platform)
          ? CarpenterFramePlatform.desktop
          : CarpenterFramePlatform.touch,
    );
    final panelBuilder = panelContext.isDesktop
        ? desktopTopPanelBuilder ?? topPanelBuilder
        : topPanelBuilder;
    final panel = panelBuilder?.call(context, panelContext);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (panel != null) panel,
        Expanded(child: child),
      ],
    );
    if (padding != null) content = Padding(padding: padding!, child: content);
    if (useSafeArea) content = SafeArea(child: content);
    return ColoredBox(
      color: backgroundColor ?? theme.surface.base,
      child: content,
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
            for (final action in actions) ...[SizedBox(width: gap / 2), action],
          ],
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface.subtle,
        border: Border(
          bottom: BorderSide(
            color: theme.overlay.border,
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

bool _isDesktop(TargetPlatform platform) => switch (platform) {
  TargetPlatform.macOS ||
  TargetPlatform.windows ||
  TargetPlatform.linux => true,
  _ => false,
};
