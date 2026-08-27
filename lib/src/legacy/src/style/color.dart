import 'dart:ui';

import 'package:carpenter/src/legacy/src/style/palette.dart';

/// Resolver semantic color registry из primitive palette.
typedef CarpenterSemanticColorResolver =
    Map<String, Color> Function(
      CarpenterPalette palette,
      Brightness brightness,
    );

/// Настройка color runtime.
///
/// Цвета Carpenter полностью dynamic: palette scales, palette steps и semantic
/// roles расширяемы без изменения классов Carpenter.
class CarpenterColorConfig {
  /// Создает настройку color runtime.
  const CarpenterColorConfig({
    this.palette,
    this.semantic = const {},
    this.semanticResolver,
  });

  /// Настройка primitive palette.
  final CarpenterPaletteConfig? palette;

  /// Явные semantic colors или partial overrides.
  final Map<String, Color> semantic;

  /// Resolver semantic roles из palette.
  final CarpenterSemanticColorResolver? semanticResolver;
}

/// Dynamic semantic colors visual runtime.
class CarpenterColor {
  /// Создает semantic color registry.
  const CarpenterColor({required this.palette, required this.tokens});

  /// Собирает color runtime из config.
  factory CarpenterColor.fromConfig({
    required CarpenterColorConfig config,
    required CarpenterPaletteConfig fallbackPalette,
    required Brightness brightness,
  }) {
    final palette = CarpenterPalette.fromConfig(
      config.palette ?? fallbackPalette,
    );
    final resolver = config.semanticResolver ?? _defaultSemanticColors;
    final tokens = <String, Color>{
      ..._defaultSemanticColors(palette, brightness),
      ...resolver(palette, brightness),
      ...config.semantic,
    };

    return CarpenterColor(palette: palette, tokens: tokens);
  }

  /// Primitive palette runtime.
  ///
  /// Компоненты Carpenter обычно не должны читать palette напрямую, но runtime
  /// оставляет ее доступной для кастомных компонентов и диагностики.
  final CarpenterPalette palette;

  /// Dynamic semantic registry.
  final Map<String, Color> tokens;

  /// Возвращает semantic color по роли.
  Color call(String role) {
    final color = tokens[role];
    if (color == null) {
      throw ArgumentError.value(role, 'role', 'Semantic color не найден.');
    }
    return color;
  }

  /// Возвращает semantic color по роли.
  Color operator [](String role) => call(role);
}

Map<String, Color> _defaultSemanticColors(
  CarpenterPalette palette,
  Brightness brightness,
) {
  final primary = palette('primary');
  final neutral = palette('neutral');
  final success = palette('success');
  final warning = palette('warning');
  final danger = palette('danger');
  final info = palette('info');

  return switch (brightness) {
    Brightness.dark => {
      'surface.base': neutral('950'),
      'surface.raised': neutral('900'),
      'surface.muted': neutral('800'),
      'surface.inverse': neutral('50'),
      'surface.overlay': neutral('900'),
      'surface.scrim': const Color(0x99000000),
      'text.primary': neutral('50'),
      'text.secondary': neutral('100'),
      'text.muted': neutral('400'),
      'text.inverse': neutral('950'),
      'text.disabled': neutral('600'),
      'border.subtle': neutral('800'),
      'border.normal': neutral('700'),
      'border.strong': neutral('500'),
      'border.focus': primary('400'),
      'action.primary': primary('500'),
      'action.primary.hover': primary('400'),
      'action.primary.pressed': primary('300'),
      'action.primary.text': neutral('950'),
      'action.secondary': neutral('800'),
      'action.secondary.hover': neutral('700'),
      'action.secondary.pressed': neutral('600'),
      'action.secondary.text': neutral('50'),
      'action.disabled': neutral('800'),
      'action.disabled.text': neutral('500'),
      'status.success': success('400'),
      'status.success.surface': success('950'),
      'status.warning': warning('300'),
      'status.warning.surface': warning('950'),
      'status.danger': danger('400'),
      'status.danger.surface': danger('950'),
      'status.info': info('400'),
      'status.info.surface': info('950'),
    },
    Brightness.light => {
      'surface.base': neutral('50'),
      'surface.raised': const Color(0xFFFFFFFF),
      'surface.muted': neutral('100'),
      'surface.inverse': neutral('950'),
      'surface.overlay': const Color(0xFFFFFFFF),
      'surface.scrim': const Color(0x99000000),
      'text.primary': neutral('950'),
      'text.secondary': neutral('800'),
      'text.muted': neutral('500'),
      'text.inverse': const Color(0xFFFFFFFF),
      'text.disabled': neutral('400'),
      'border.subtle': neutral('200'),
      'border.normal': neutral('300'),
      'border.strong': neutral('500'),
      'border.focus': primary('600'),
      'action.primary': primary('500'),
      'action.primary.hover': primary('700'),
      'action.primary.pressed': primary('800'),
      'action.primary.text': const Color(0xFFFFFFFF),
      'action.secondary': neutral('100'),
      'action.secondary.hover': neutral('200'),
      'action.secondary.pressed': neutral('300'),
      'action.secondary.text': neutral('950'),
      'action.disabled': neutral('200'),
      'action.disabled.text': neutral('500'),
      'status.success': success('600'),
      'status.success.surface': success('100'),
      'status.warning': warning('700'),
      'status.warning.surface': warning('100'),
      'status.danger': danger('600'),
      'status.danger.surface': danger('100'),
      'status.info': info('600'),
      'status.info.surface': info('100'),
    },
  };
}
