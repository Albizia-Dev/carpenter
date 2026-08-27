import 'dart:ui';

import 'package:carpenter/src/legacy/src/root/dimension.dart';
import 'package:carpenter/src/legacy/src/root/type.dart';
import 'package:carpenter/src/legacy/src/style/color.dart';
import 'package:flutter/foundation.dart';

/// Декларация входных параметров визуального runtime Carpenter.
///
/// `CarpenterConfig` ничего не вычисляет сам. Он только описывает исходные
/// данные приложения: базовые цвета, размерную сетку, плотность интерфейса и
/// окружение. Все производные токены собирает `Carpenter`.
class CarpenterConfig {
  /// Создает декларацию visual runtime.
  const CarpenterConfig({
    this.primary = const Color(0xFF0072CE),
    this.accent = const Color(0xFF7C5CFF),
    this.rem = 16,
    this.density = 1,
    this.brightness = Brightness.light,
    this.platform,
    this.locale,
    this.color,
    this.type,
    this.dimension,
  });

  /// Главный брендовый цвет, из которого runtime строит primary-шкалу.
  final Color primary;

  /// Дополнительный акцентный цвет, из которого runtime строит accent-шкалу.
  final Color accent;

  /// Базовая единица размера.
  ///
  /// Компоненты не должны использовать голые пиксели. Все отступы, размеры,
  /// радиусы и подобные значения должны проходить через `Face`.
  final double rem;

  /// Коэффициент плотности интерфейса.
  ///
  /// Значение меньше `1` делает интерфейс компактнее, больше `1` - свободнее.
  final double density;

  /// Светлая или темная визуальная среда.
  final Brightness brightness;

  /// Платформа, если runtime должен учитывать платформенные различия.
  final TargetPlatform? platform;

  /// Локаль приложения, если визуальный язык зависит от локализации.
  final Locale? locale;

  /// Настройки цветового runtime.
  ///
  /// Если не переданы, Carpenter строит дефолтную dynamic palette из
  /// `primary`, `accent` и `brightness`.
  final CarpenterColorConfig? color;

  /// Настройки типографического runtime.
  ///
  /// Поддерживает произвольные имена ролей, основной и вторичный font family,
  /// fallback/package и partial overrides.
  final CarpenterTypeConfig? type;

  /// Настройки размерного runtime.
  ///
  /// Содержит произвольные scale и named tokens для space, radius, size и
  /// любых других измерений.
  final CarpenterDimensionConfig? dimension;
}
