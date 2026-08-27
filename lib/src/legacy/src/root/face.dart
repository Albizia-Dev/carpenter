import 'package:carpenter/src/legacy/src/root/config.dart';
import 'package:carpenter/src/legacy/src/root/dimension.dart';
import 'package:carpenter/src/legacy/src/root/motion.dart';
import 'package:carpenter/src/legacy/src/root/type.dart';
import 'package:carpenter/src/legacy/src/style/color.dart';
import 'package:carpenter/src/legacy/src/style/palette.dart';

/// Публичное лицо visual runtime для компонентов.
///
/// Компоненты Carpenter должны читать визуальный язык только через
/// `CarpenterFace`: semantic colors, типографику, размеры, motion и `rem`.
/// Primitive palette, OKLCH и алгоритмы генерации остаются внутренностями
/// runtime и не становятся частью компонентного API.
class CarpenterFace {
  /// Собирает фасад из готовых семантических токенов.
  const CarpenterFace({
    required this.config,
    required this.color,
    required this.type,
    required this.dimension,
    required this.motion,
  });

  /// Создает фасад из декларативного конфига.
  factory CarpenterFace.fromConfig(CarpenterConfig config) {
    final dimensionConfig =
        config.dimension ??
        CarpenterDimensionConfig(rem: config.rem, density: config.density);
    final dimension = CarpenterDimension.fromConfig(dimensionConfig);
    final colorConfig = config.color ?? const CarpenterColorConfig();

    return CarpenterFace(
      config: config,
      color: CarpenterColor.fromConfig(
        config: colorConfig,
        fallbackPalette: CarpenterPaletteConfig.defaults(
          primary: config.primary,
          accent: config.accent,
        ),
        brightness: config.brightness,
      ),
      type: CarpenterType.fromConfig(
        config: config.type ?? const CarpenterTypeConfig(),
        baseSize: dimension.rem(1),
      ),
      dimension: dimension,
      motion: CarpenterMotion.fromConfig(config),
    );
  }

  /// Исходная декларация, из которой собран runtime.
  final CarpenterConfig config;

  /// Семантические цвета, разрешенные для использования компонентами.
  final CarpenterColor color;

  /// Dynamic typography registry.
  final CarpenterType type;

  /// Dynamic dimension registry.
  final CarpenterDimension dimension;

  /// Длительности и кривые движения.
  final CarpenterMotion motion;

  /// Возвращает размер в физических пикселях из rem-единиц.
  double rem(double value) => dimension.rem(value);

  /// Короткий псевдоним для `rem`, удобный в плотной верстке компонентов.
  double r(double value) => rem(value);

  /// Возвращает space token.
  double space(String role) => dimension.space(role);

  /// Возвращает radius token.
  double radius(String role) => dimension.radius(role);

  /// Возвращает size token.
  double size(String role) => dimension.size(role);
}
