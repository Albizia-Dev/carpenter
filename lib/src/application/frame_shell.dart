import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../components/layout/app_frame.dart';
import 'runtime/runtime.dart';
import 'shell/shell.dart';

final class CarpenterFrameRuntime {
  const CarpenterFrameRuntime({required this.platform});
  final TargetPlatform platform;
}

extension CarpenterFrameRuntimeAccess on CarpenterRuntime {
  CarpenterFrameRuntime get frame => read<CarpenterFrameRuntime>();
}

/// Application shell that contributes frame capability and visual frame wrapping.
final class CarpenterFrameShell extends CarpenterShellBase {
  const CarpenterFrameShell({
    this.topPanelBuilder,
    this.desktopTopPanelBuilder,
    this.targetPlatform,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
  });

  final CarpenterTopPanelBuilder? topPanelBuilder;
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;
  final TargetPlatform? targetPlatform;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  String get id => 'carpenter.frame';
  @override
  Set<Type> get provides => const {CarpenterFrameRuntime};
  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) => context.runtime.extend(CarpenterFrameRuntime(platform: targetPlatform ?? context.runtime.core.platform));
  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) => CarpenterAppFrame(
    topPanelBuilder: topPanelBuilder,
    desktopTopPanelBuilder: desktopTopPanelBuilder,
    targetPlatform: targetPlatform,
    useSafeArea: useSafeArea,
    padding: padding,
    backgroundColor: backgroundColor,
    child: child,
  );
}
