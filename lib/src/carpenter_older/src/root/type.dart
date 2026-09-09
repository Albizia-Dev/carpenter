import 'package:flutter/widgets.dart';

/// Настройка typography runtime.
///
/// Типографика Carpenter является dynamic registry: роли текста могут иметь
/// любые имена, а дефолтная шкала может быть расширена partial overrides.
class CarpenterTypeConfig {
  /// Создает настройку typography runtime.
  const CarpenterTypeConfig({
    this.fontFamily,
    this.fontFamilyFallback,
    this.package,
    this.secondaryFontFamily,
    this.secondaryFontFamilyFallback,
    this.secondaryPackage,
    this.baseSize,
    this.scaleRatio = 1.125,
    this.tokens = const {},
  });

  /// Основной font family.
  final String? fontFamily;

  /// Fallback font families.
  final List<String>? fontFamilyFallback;

  /// Package, если шрифт поставляется пакетом Flutter.
  final String? package;

  /// Вторичный font family для мостов и альтернативной типографики.
  final String? secondaryFontFamily;

  /// Fallback font families вторичного шрифта.
  final List<String>? secondaryFontFamilyFallback;

  /// Package вторичного шрифта, если он поставляется пакетом Flutter.
  final String? secondaryPackage;

  /// Базовый размер. Если не задан, берется из dimension runtime.
  final double? baseSize;

  /// Ratio generated typography scale.
  final double scaleRatio;

  /// Явные роли или partial overrides.
  final Map<String, TextStyle> tokens;
}

/// Dynamic typography visual runtime.
class CarpenterType {
  /// Создает typography registry.
  const CarpenterType(this.tokens, {this.secondaryTokens = const {}});

  /// Создает typography runtime из config.
  factory CarpenterType.fromConfig({
    required CarpenterTypeConfig config,
    required double baseSize,
  }) {
    final base = config.baseSize ?? baseSize;
    final family = config.fontFamily;
    final fallback = config.fontFamilyFallback;
    final package = config.package;

    TextStyle style({
      required double size,
      required double height,
      FontWeight? weight,
    }) {
      return TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        package: package,
        fontSize: size,
        height: height,
        fontWeight: weight,
      );
    }

    final ratio = config.scaleRatio;
    final tokens = <String, TextStyle>{
      'body': style(size: base, height: 1.5),
      'body.strong': style(size: base, height: 1.5, weight: FontWeight.w600),
      'label': style(size: base / ratio, height: 1.25),
      'label.strong': style(
        size: base / ratio,
        height: 1.25,
        weight: FontWeight.w600,
      ),
      'caption': style(size: base / ratio / ratio, height: 1.25),
      'label.primary': style(size: base / ratio, height: 1.25),
      'label.primary.strong': style(
        size: base / ratio,
        height: 1.25,
        weight: FontWeight.w600,
      ),
      'caption.primary': style(size: base / ratio / ratio, height: 1.25),
      'title': style(
        size: base * ratio * ratio,
        height: 1.25,
        weight: FontWeight.w600,
      ),
      'subtitle': style(
        size: base * ratio,
        height: 1.25,
        weight: FontWeight.w600,
      ),
    };

    tokens.addAll(config.tokens);
    final secondaryFamily = config.secondaryFontFamily;
    final secondaryTokens = secondaryFamily == null
        ? const <String, TextStyle>{}
        : {
            for (final entry in tokens.entries)
              entry.key: entry.value.copyWith(
                fontFamily: secondaryFamily,
                fontFamilyFallback:
                    config.secondaryFontFamilyFallback ?? fallback,
                package: config.secondaryPackage,
              ),
          };
    return CarpenterType(tokens, secondaryTokens: secondaryTokens);
  }

  /// Dynamic registry текстовых ролей.
  final Map<String, TextStyle> tokens;

  /// Вторичные текстовые роли. Пусты, если secondary family не настроен.
  final Map<String, TextStyle> secondaryTokens;

  /// Настроен ли отдельный вторичный font family.
  bool get hasSecondary => secondaryTokens.isNotEmpty;

  /// Возвращает TextStyle по роли.
  TextStyle call(String role) {
    final style = tokens[role];
    if (style == null) {
      throw ArgumentError.value(
        role,
        'role',
        'Типографическая роль не найдена.',
      );
    }
    return style;
  }

  /// Возвращает TextStyle по роли.
  TextStyle operator [](String role) => call(role);

  /// Возвращает вторичный TextStyle или основной, если он не настроен.
  TextStyle secondary(String role) {
    final style = secondaryTokens[role] ?? tokens[role];
    if (style == null) {
      throw ArgumentError.value(
        role,
        'role',
        'Типографическая роль не найдена.',
      );
    }
    return style;
  }
}
