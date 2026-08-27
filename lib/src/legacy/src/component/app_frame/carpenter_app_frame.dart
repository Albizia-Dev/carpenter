import 'package:carpenter/src/legacy/src/component/avatar/carpenter_avatar.dart';
import 'package:carpenter/src/components/basic/text.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Text;

/// Класс платформы для app-frame Carpenter.
enum CarpenterFramePlatform {
  /// Desktop-платформа: macOS, Windows или Linux.
  desktop,

  /// Touch-платформа: iOS, Android, Fuchsia или web/touch окружение.
  touch,
}

/// Контекст сборки верхней панели app-frame.
class CarpenterTopPanelContext {
  /// Создает контекст верхней панели.
  const CarpenterTopPanelContext({
    required this.targetPlatform,
    required this.framePlatform,
  });

  /// Реальная Flutter-платформа.
  final TargetPlatform targetPlatform;

  /// Укрупненный класс платформы для выбора панели.
  final CarpenterFramePlatform framePlatform;

  /// `true`, если приложение запущено в desktop-окружении.
  bool get isDesktop => framePlatform == CarpenterFramePlatform.desktop;
}

/// Builder верхней панели app-frame.
typedef CarpenterTopPanelBuilder =
    Widget Function(BuildContext context, CarpenterTopPanelContext panel);

/// Кроссплатформенный каркас приложения Carpenter.
///
/// `CarpenterAppFrame` позволяет заменить верхнюю панель на desktop через
/// `desktopTopPanelBuilder`, сохранив обычную cross-platform сборку на остальных
/// платформах. Компонент не управляет нативным window chrome напрямую: скрытие
/// системной рамки, если оно нужно, остается задачей runner или window-plugin.
class CarpenterAppFrame extends StatelessWidget {
  /// Создает app-frame.
  const CarpenterAppFrame({
    super.key,
    required this.child,
    this.topPanelBuilder,
    this.desktopTopPanelBuilder,
    this.targetPlatform,
    this.useSafeArea = true,
    this.padding,
    this.backgroundColor,
  });

  /// Основное содержимое приложения.
  final Widget child;

  /// Панель по умолчанию для всех платформ.
  final CarpenterTopPanelBuilder? topPanelBuilder;

  /// Desktop-панель, которая переопределяет `topPanelBuilder` на desktop.
  final CarpenterTopPanelBuilder? desktopTopPanelBuilder;

  /// Platform override для тестов и preview.
  final TargetPlatform? targetPlatform;

  /// Оборачивать содержимое в `SafeArea`.
  final bool useSafeArea;

  /// Отступ вокруг всего app-frame.
  final EdgeInsetsGeometry? padding;

  /// Фон app-frame. Если не задан, берется `face.color('surface.base')`.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final platform = targetPlatform ?? defaultTargetPlatform;
    final panelContext = CarpenterTopPanelContext(
      targetPlatform: platform,
      framePlatform: _isDesktop(platform)
          ? CarpenterFramePlatform.desktop
          : CarpenterFramePlatform.touch,
    );
    final panelBuilder = panelContext.isDesktop
        ? desktopTopPanelBuilder ?? topPanelBuilder
        : topPanelBuilder;
    final panel = panelBuilder?.call(context, panelContext);
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (panel != null) panel,
        Expanded(child: child),
      ],
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return ColoredBox(
      color: backgroundColor ?? face.color('surface.base'),
      child: content,
    );
  }
}

/// Верхняя панель приложения Carpenter.
///
/// Это обычный `widgets.dart` компонент: его можно использовать как дефолтную
/// панель или как основу для desktop override внутри `CarpenterAppFrame`.
class CarpenterTopPanel extends StatelessWidget {
  /// Создает верхнюю панель.
  const CarpenterTopPanel({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.child,
    this.height,
    this.padding,
    this.showDivider = true,
  });

  /// Заголовок панели.
  final String? title;

  /// Второстепенный текст под заголовком.
  final String? subtitle;

  /// Виджет слева от заголовка.
  final Widget? leading;

  /// Виджеты справа.
  final List<Widget> actions;

  /// Полностью кастомное содержимое панели.
  final Widget? child;

  /// Высота панели.
  final double? height;

  /// Внутренние отступы панели.
  final EdgeInsetsGeometry? padding;

  /// Показывать нижний divider.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final content =
        child ??
        Row(
          children: [
            leading ?? const CarpenterAvatar(initials: 'C', size: 32),
            SizedBox(width: face.space('0.75')),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    CarpenterText(title!, role: .label, emphasis: .strong),
                  if (subtitle != null)
                    CarpenterText(
                      subtitle!,
                      role: .caption,
                      colorRole: .secondary,
                    ),
                ],
              ),
            ),
            for (final action in actions) ...[
              SizedBox(width: face.space('0.5')),
              action,
            ],
          ],
        );

    return AnimatedContainer(
      duration: face.motion.fast,
      curve: face.motion.curve,
      height: height,
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: face.space('1'),
            vertical: face.space('0.75'),
          ),
      decoration: BoxDecoration(
        color: face.color('surface.raised'),
        border: Border(
          bottom: BorderSide(
            color: showDivider
                ? face.color('border.subtle')
                : const Color(0x00000000),
          ),
        ),
      ),
      child: content,
    );
  }
}

bool _isDesktop(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => true,
    _ => false,
  };
}
