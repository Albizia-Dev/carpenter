/// Настройка размерного runtime.
///
/// Размерности Carpenter являются dynamic registry. Можно задавать любые роли
/// для `space`, `radius`, `size` и произвольных `tokens`.
class CarpenterDimensionConfig {
  /// Создает настройку размерного runtime.
  const CarpenterDimensionConfig({
    this.rem = 16,
    this.density = 1,
    this.space = const {},
    this.radius = const {},
    this.size = const {},
    this.tokens = const {},
  });

  /// Базовая единица размера.
  final double rem;

  /// Плотность интерфейса.
  final double density;

  /// Отступы и интервалы.
  final Map<String, double> space;

  /// Радиусы.
  final Map<String, double> radius;

  /// Размеры controls, icons, avatars и других элементов.
  final Map<String, double> size;

  /// Произвольные размерные токены.
  final Map<String, double> tokens;
}

/// Dynamic dimension visual runtime.
class CarpenterDimension {
  /// Создает dimension registry.
  const CarpenterDimension({
    required this.remBase,
    required this.density,
    required this.spaceTokens,
    required this.radiusTokens,
    required this.sizeTokens,
    required this.tokens,
  });

  /// Создает dimension runtime из config.
  factory CarpenterDimension.fromConfig(CarpenterDimensionConfig config) {
    final unit = config.rem * config.density;
    final space = <String, double>{
      '0': 0,
      '0.125': unit * 0.125,
      '0.1875': unit * 0.1875,
      '0.25': unit * 0.25,
      '0.375': unit * 0.375,
      '0.5': unit * 0.5,
      '0.625': unit * 0.625,
      '0.75': unit * 0.75,
      '1': unit,
      '1.25': unit * 1.25,
      '1.5': unit * 1.5,
      '2': unit * 2,
      ...config.space,
    };
    final radius = <String, double>{
      'none': 0,
      'xs': unit * 0.25,
      'sm': unit * 0.375,
      'md': unit * 0.5,
      'control': unit * 0.5,
      'lg': unit * 0.75,
      'xl': unit,
      'pill': unit * 999,
      ...config.radius,
    };
    final size = <String, double>{
      'icon': unit,
      'avatar': unit * 2.5,
      'loader': unit * 1.5,
      'control.mark': unit,
      'control.switch.width': unit * 2.25,
      'control.switch.height': unit * 1.25,
      'progress.height': unit * 0.5,
      ...config.size,
    };

    return CarpenterDimension(
      remBase: config.rem,
      density: config.density,
      spaceTokens: space,
      radiusTokens: radius,
      sizeTokens: size,
      tokens: config.tokens,
    );
  }

  /// Базовая rem-единица.
  final double remBase;

  /// Плотность интерфейса.
  final double density;

  /// Dynamic space registry.
  final Map<String, double> spaceTokens;

  /// Dynamic radius registry.
  final Map<String, double> radiusTokens;

  /// Dynamic size registry.
  final Map<String, double> sizeTokens;

  /// Dynamic arbitrary dimension registry.
  final Map<String, double> tokens;

  /// Возвращает размер из rem-единиц.
  double rem(double value) => value * remBase * density;

  /// Возвращает space token.
  double space(String role) => _lookup(spaceTokens, role, 'space');

  /// Возвращает radius token.
  double radius(String role) => _lookup(radiusTokens, role, 'radius');

  /// Возвращает size token.
  double size(String role) => _lookup(sizeTokens, role, 'size');

  /// Возвращает произвольный dimension token.
  double call(String role) => _lookup(tokens, role, 'dimension');
}

double _lookup(Map<String, double> tokens, String role, String kind) {
  final value = tokens[role];
  if (value == null) {
    throw ArgumentError.value(role, 'role', '$kind token не найден.');
  }
  return value;
}
