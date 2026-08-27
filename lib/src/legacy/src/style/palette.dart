import 'dart:math' as math;
import 'dart:ui';

import 'package:okcolor/models/oklch.dart';

/// Дефолтные шаги generated palette.
const carpenterDefaultColorSteps = [
  '50',
  '100',
  '200',
  '300',
  '400',
  '500',
  '600',
  '700',
  '800',
  '900',
  '950',
];

/// Настройка primitive palette.
///
/// Палитра Carpenter является dynamic registry: названия шкал и шагов ничем не
/// ограничены. Шкалу можно передать целиком, частично переопределить или
/// сгенерировать из seed через OKLCH.
class CarpenterPaletteConfig {
  /// Создает настройку primitive palette.
  const CarpenterPaletteConfig({this.scales = const {}});

  /// Дефолтная palette config из legacy primary/accent.
  factory CarpenterPaletteConfig.defaults({
    required Color primary,
    required Color accent,
  }) {
    return CarpenterPaletteConfig(
      scales: {
        'primary': CarpenterColorScaleConfig.seed(primary),
        'accent': CarpenterColorScaleConfig.seed(accent),
        'neutral': CarpenterColorScaleConfig.seed(primary, neutral: true),
        'success': CarpenterColorScaleConfig.seed(const Color(0xFF12A150)),
        'warning': CarpenterColorScaleConfig.seed(const Color(0xFFE6A700)),
        'danger': CarpenterColorScaleConfig.seed(const Color(0xFFD92D20)),
        'info': CarpenterColorScaleConfig.seed(const Color(0xFF2563EB)),
      },
    );
  }

  /// Dynamic registry шкал.
  final Map<String, CarpenterColorScaleConfig> scales;
}

/// Настройка одной цветовой шкалы.
class CarpenterColorScaleConfig {
  /// Создает настройку шкалы.
  const CarpenterColorScaleConfig({
    this.seed,
    this.steps = carpenterDefaultColorSteps,
    this.colors = const {},
    this.neutral = false,
    this.chroma,
  });

  /// Полностью явная шкала.
  const CarpenterColorScaleConfig.explicit(Map<String, Color> colors)
    : this(seed: null, colors: colors, steps: const []);

  /// Шкала, сгенерированная из seed через OKLCH.
  const CarpenterColorScaleConfig.seed(
    Color seed, {
    Iterable<String> steps = carpenterDefaultColorSteps,
    Map<String, Color> overrides = const {},
    bool neutral = false,
    double? chroma,
  }) : this(
         seed: seed,
         steps: steps,
         colors: overrides,
         neutral: neutral,
         chroma: chroma,
       );

  /// Seed-цвет для генерации.
  final Color? seed;

  /// Любые шаги шкалы в нужном порядке.
  final Iterable<String> steps;

  /// Явные значения или partial overrides.
  final Map<String, Color> colors;

  /// Делает шкалу почти нейтральной, сохраняя легкую привязку к hue seed.
  final bool neutral;

  /// Chroma override для generated шкалы.
  final double? chroma;
}

/// Dynamic primitive palette visual runtime.
class CarpenterPalette {
  /// Создает primitive palette из dynamic registry шкал.
  const CarpenterPalette(this.scales);

  /// Создает palette из config.
  factory CarpenterPalette.fromConfig(CarpenterPaletteConfig config) {
    return CarpenterPalette({
      for (final entry in config.scales.entries)
        entry.key: CarpenterColorScale.fromConfig(entry.value),
    });
  }

  /// Dynamic registry шкал.
  final Map<String, CarpenterColorScale> scales;

  /// Возвращает шкалу по имени.
  CarpenterColorScale call(String name) {
    final scale = scales[name];
    if (scale == null) {
      throw ArgumentError.value(name, 'name', 'Цветовая шкала не найдена.');
    }
    return scale;
  }

  /// Возвращает шкалу по имени.
  CarpenterColorScale operator [](String name) => call(name);
}

/// Dynamic цветовая шкала с произвольными шагами.
class CarpenterColorScale {
  /// Создает шкалу из dynamic registry цветов.
  const CarpenterColorScale(this.colors);

  /// Создает шкалу из config.
  factory CarpenterColorScale.fromConfig(CarpenterColorScaleConfig config) {
    final seed = config.seed;
    final explicit = Map<String, Color>.of(config.colors);

    if (seed == null) {
      return CarpenterColorScale(explicit);
    }

    final lch = OkLch.fromColor(seed);
    final chroma = config.chroma ?? (config.neutral ? 0.014 : lch.c);
    final steps = config.steps.toList();
    final colors = <String, Color>{};

    for (var index = 0; index < steps.length; index += 1) {
      final key = steps[index];
      final t = steps.length <= 1 ? 0.5 : index / (steps.length - 1);
      final lightness = _lerpDouble(0.98, 0.18, t);
      final chromaFactor = config.neutral
          ? 1.0
          : _lerpDouble(0.18, 0.42, (t - 0.5).abs() * 2);
      final c = config.neutral
          ? chroma
          : math.min(chroma.clamp(0.04, 0.2) * (1.2 - chromaFactor), 0.22);

      colors[key] = OkLch(lightness, c, lch.h).toColor();
    }

    colors.addAll(explicit);
    return CarpenterColorScale(colors);
  }

  /// Dynamic registry цветов.
  final Map<String, Color> colors;

  /// Возвращает цвет по любому шагу.
  Color call(Object step) {
    final key = step.toString();
    final color = colors[key];
    if (color == null) {
      throw ArgumentError.value(step, 'step', 'Цветовой шаг не найден.');
    }
    return color;
  }

  /// Возвращает цвет по любому шагу.
  Color operator [](Object step) => call(step);
}

double _lerpDouble(double a, double b, double t) {
  return a + (b - a) * t;
}
