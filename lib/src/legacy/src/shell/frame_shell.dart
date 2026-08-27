import 'package:carpenter/src/legacy/src/component/app_frame/carpenter_app_frame.dart';
import 'package:carpenter/src/legacy/src/runtime/runtime.dart';
import 'package:carpenter/src/legacy/src/shell/shell.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Runtime capability app-frame shell-а.
class CarpenterFrameRuntime {
  /// Создает frame runtime.
  const CarpenterFrameRuntime({required this.platform});

  /// Target platform frame-а.
  final TargetPlatform platform;
}

/// Typed access к frame capability.
extension CarpenterFrameRuntimeAccess on CarpenterRuntime {
  /// Frame runtime.
  CarpenterFrameRuntime get frame => read<CarpenterFrameRuntime>();
}

/// Shell, который подключает `CarpenterAppFrame`.
class CarpenterFrameShell extends CarpenterShellBase {
  /// Создает frame shell.
  const CarpenterFrameShell({
    this.topPanelBuilder,
    this.desktopTopPanelBuilder,
    this.targetPlatform,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
  });

  /// Верхняя панель по умолчанию.
  final CarpenterTopPanelBuilder? topPanelBuilder;

  /// Desktop-override верхней панели.
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;

  /// Platform override.
  final TargetPlatform? targetPlatform;

  /// Использовать SafeArea.
  final bool useSafeArea;

  /// Отступ frame.
  final EdgeInsetsGeometry? padding;

  /// Фон frame.
  final Color? backgroundColor;

  @override
  String get id => 'carpenter.frame';

  @override
  Set<Type> get provides => const {CarpenterFrameRuntime};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    return context.runtime.extend(
      CarpenterFrameRuntime(platform: targetPlatform ?? defaultTargetPlatform),
    );
  }

  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) {
    return CarpenterAppFrame(
      topPanelBuilder: topPanelBuilder,
      desktopTopPanelBuilder: desktopTopPanelBuilder,
      targetPlatform: targetPlatform,
      useSafeArea: useSafeArea,
      padding: padding,
      backgroundColor: backgroundColor,
      child: child,
    );
  }
}
