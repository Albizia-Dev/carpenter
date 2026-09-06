import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../components/layout/app_frame.dart';
import 'runtime/runtime.dart';
import 'shell/shell.dart';

/// Runtime capability published by [CarpenterFrameShell] so descendants can
/// observe the frame target platform without depending on the visual frame widget.
final class CarpenterFrameRuntime {
  /// Creates frame runtime capability for the effective target platform.
  const CarpenterFrameRuntime({required this.platform});

  /// Platform used by the frame integration for platform-sensitive presentation.
  final TargetPlatform platform;
}

/// Typed access to frame capability registered in a [CarpenterRuntime].
extension CarpenterFrameRuntimeAccess on CarpenterRuntime {
  /// Mandatory frame runtime capability; throws when no frame shell registered it.
  CarpenterFrameRuntime get frame => read<CarpenterFrameRuntime>();
}

/// Application shell that contributes frame capability and visual frame wrapping.
final class CarpenterFrameShell extends CarpenterShellBase {
  /// Creates a shell that publishes frame runtime capability and wraps hosted
  /// content in [CarpenterAppFrame].
  const CarpenterFrameShell({
    this.topPanelBuilder,
    this.desktopTopPanelBuilder,
    this.targetPlatform,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
  });

  /// General top-panel builder forwarded to [CarpenterAppFrame].
  final CarpenterTopPanelBuilder? topPanelBuilder;

  /// Desktop-specific top-panel builder forwarded to [CarpenterAppFrame].
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;

  /// Optional frame platform override; otherwise the core runtime platform is used.
  final TargetPlatform? targetPlatform;

  /// Whether the frame keeps hosted content inside platform safe-area insets.
  final bool useSafeArea;

  /// Optional frame content padding.
  final EdgeInsetsGeometry? padding;

  /// Optional frame background color override.
  final Color? backgroundColor;

  /// Stable shell identifier used for diagnostics and capability-composition
  /// errors.
  @override
  String get id => 'carpenter.frame';

  /// Declares that successful configuration registers [CarpenterFrameRuntime].
  @override
  Set<Type> get provides => const {CarpenterFrameRuntime};

  /// Extends the incoming runtime with frame metadata using [targetPlatform] or
  /// the core runtime platform.
  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) =>
      context.runtime.extend(
        CarpenterFrameRuntime(
          platform: targetPlatform ?? context.runtime.core.platform,
        ),
      );

  /// Wraps hosted content in [CarpenterAppFrame] with this shell's visual options.
  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) =>
      CarpenterAppFrame(
        topPanelBuilder: topPanelBuilder,
        desktopTopPanelBuilder: desktopTopPanelBuilder,
        targetPlatform: targetPlatform,
        useSafeArea: useSafeArea,
        padding: padding,
        backgroundColor: backgroundColor,
        child: child,
      );
}
