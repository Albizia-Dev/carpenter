// ignore_for_file: carpenter_lints/use_carpenter_text

import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart' as widgets;

/// Роль текста в визуальном языке Carpenter.
enum CarpenterTextVariant {
  /// Заголовок первого уровня.
  title,

  /// Заголовок второго уровня.
  subtitle,

  /// Основной текст.
  body,

  /// Основной текст с усиленной важностью.
  bodyStrong,

  /// Подпись control или компактного элемента.
  label,

  /// Усиленная подпись control или компактного элемента.
  labelStrong,

  /// Подпись control в основном шрифте.
  labelPrimary,

  /// Усиленная подпись control в основном шрифте.
  labelPrimaryStrong,

  /// Второстепенный мелкий текст.
  caption,

  /// Второстепенный мелкий текст в основном шрифте.
  captionPrimary,
}

/// Семантический цвет текста Carpenter.
enum CarpenterTextTone {
  /// Основной текст.
  primary,

  /// Второстепенный текст.
  secondary,

  /// Приглушенный текст.
  muted,

  /// Текст на темной или насыщенной поверхности.
  inverse,

  /// Текст недоступного состояния.
  disabled,

  /// Текст успешного состояния.
  success,

  /// Текст предупреждения.
  warning,

  /// Текст ошибки или опасного состояния.
  danger,

  /// Информационный текст.
  info,
}

/// Текстовый primitive Carpenter.
///
/// Полностью совместим с Flutter [widgets.Text], но дополнительно позволяет
/// выбирать типографическую роль через [variant] и семантический цвет
/// через [tone].
///
/// Если [style] не указан, используется стиль Carpenter.
///
/// Если [style] указан, он накладывается поверх стиля Carpenter и может
/// переопределить отдельные его свойства.
class CarpenterText extends widgets.Text {
  /// Создает текстовый primitive из строки.
  const CarpenterText(
    super.data, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming '
      'nonlinear text scaling support.',
    )
    super.textScaleFactor,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
    this.variant = CarpenterTextVariant.body,
    this.tone = CarpenterTextTone.primary,
  });

  /// Создает текстовый primitive из [widgets.InlineSpan].
  const CarpenterText.rich(
    super.textSpan, {
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap,
    super.overflow,
    @Deprecated(
      'Use textScaler instead. '
      'Use of textScaleFactor was deprecated in preparation for the upcoming '
      'nonlinear text scaling support.',
    )
    super.textScaleFactor,
    super.textScaler,
    super.maxLines,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
    this.variant = CarpenterTextVariant.body,
    this.tone = CarpenterTextTone.primary,
  }) : super.rich();

  /// Типографическая роль текста.
  final CarpenterTextVariant variant;

  /// Семантический цвет текста.
  final CarpenterTextTone tone;

  @override
  widgets.Widget build(widgets.BuildContext context) {
    final carpenterStyle = _resolveStyle(context);
    final effectiveStyle = carpenterStyle.merge(style);

    if (textSpan case final textSpan?) {
      return widgets.Text.rich(
        textSpan,
        style: effectiveStyle,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaleFactor: textScaleFactor,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: semanticsLabel,
        semanticsIdentifier: semanticsIdentifier,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }

    return widgets.Text(
      data!,
      style: effectiveStyle,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }

  widgets.TextStyle _resolveStyle(widgets.BuildContext context) {
    final face = context.face;

    final style = switch (variant) {
      CarpenterTextVariant.title => face.type.secondary('title'),
      CarpenterTextVariant.subtitle => face.type.secondary('subtitle'),
      CarpenterTextVariant.body => face.type.secondary('body'),
      CarpenterTextVariant.bodyStrong => face.type.secondary('body.strong'),
      CarpenterTextVariant.label => face.type.secondary('label'),
      CarpenterTextVariant.labelStrong => face.type.secondary('label.strong'),
      CarpenterTextVariant.labelPrimary => face.type('label.primary'),
      CarpenterTextVariant.labelPrimaryStrong => face.type(
        'label.primary.strong',
      ),
      CarpenterTextVariant.caption => face.type.secondary('caption'),
      CarpenterTextVariant.captionPrimary => face.type('caption.primary'),
    };

    final color = switch (tone) {
      CarpenterTextTone.primary => face.color('text.primary'),
      CarpenterTextTone.secondary => face.color('text.secondary'),
      CarpenterTextTone.muted => face.color('text.muted'),
      CarpenterTextTone.inverse => face.color('text.inverse'),
      CarpenterTextTone.disabled => face.color('text.disabled'),
      CarpenterTextTone.success => face.color('status.success'),
      CarpenterTextTone.warning => face.color('status.warning'),
      CarpenterTextTone.danger => face.color('status.danger'),
      CarpenterTextTone.info => face.color('status.info'),
    };

    return style.copyWith(color: color);
  }
}
