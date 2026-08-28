from pathlib import Path


def replace_action_theme() -> None:
    theme = Path('lib/src/foundation/theme.dart')
    source = theme.read_text()
    start = source.index('  CarpenterActionStyle resolve(\n    ActionColorRole role,')
    end = source.index('\n}\n\n@immutable\nfinal class CarpenterFieldStyle', start)
    method = '''  CarpenterActionStyle resolve(
    ActionColorRole role,
    ActionProminence prominence,
    Set<WidgetState> states,
  ) {
    if (states.contains(WidgetState.disabled)) {
      final background = switch (prominence) {
        ActionProminence.filled => disabledBackground,
        ActionProminence.high =>
          Color.lerp(transparent, disabledBackground, .72)!,
        ActionProminence.normal =>
          Color.lerp(transparent, disabledBackground, .48)!,
        ActionProminence.ghost ||
        ActionProminence.outlined ||
        ActionProminence.low => transparent,
      };
      return CarpenterActionStyle(
        background: background,
        foreground: disabledForeground,
        icon: disabledForeground,
        border: prominence == ActionProminence.outlined
            ? disabledForeground
            : transparent,
        loadingAccent: disabledForeground,
      );
    }

    final palette = switch (role) {
      ActionColorRole.neutral => neutral,
      ActionColorRole.primary => primary,
      ActionColorRole.utility => utility,
      ActionColorRole.danger => danger,
      ActionColorRole.warning => warning,
      ActionColorRole.success => success,
      ActionColorRole.info => info,
    };
    final semantic = palette.resolve(states);
    final active =
        states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.pressed);
    final lowBackground = Color.lerp(transparent, palette.state, .55)!;
    final highBackground =
        Color.lerp(palette.state, palette.strongState, .60)!;

    return switch (prominence) {
      ActionProminence.filled => CarpenterActionStyle(
        background: semantic,
        foreground: inverse,
        icon: inverse,
        border: semantic,
        loadingAccent: palette.hovered,
      ),
      ActionProminence.high => CarpenterActionStyle(
        background: active ? palette.strongState : highBackground,
        foreground: semantic,
        icon: semantic,
        border: transparent,
        loadingAccent: palette.strongState,
      ),
      ActionProminence.normal => CarpenterActionStyle(
        background: active ? palette.strongState : palette.state,
        foreground: semantic,
        icon: semantic,
        border: transparent,
        loadingAccent: palette.strongState,
      ),
      ActionProminence.low => CarpenterActionStyle(
        background: active ? palette.state : lowBackground,
        foreground: semantic,
        icon: semantic,
        border: transparent,
        loadingAccent: palette.state,
      ),
      ActionProminence.outlined => CarpenterActionStyle(
        background: active ? palette.state : transparent,
        foreground: semantic,
        icon: semantic,
        border: semantic,
        loadingAccent: palette.state,
      ),
      ActionProminence.ghost => CarpenterActionStyle(
        background: active ? palette.state : transparent,
        foreground: semantic,
        icon: semantic,
        border: transparent,
        loadingAccent: palette.state,
      ),
    };
  }'''
    theme.write_text(source[:start] + method + source[end:])


def replace_font_tokens() -> None:
    tokens = Path('lib/src/foundation/tokens/components.mordant.part.yaml')
    source = tokens.read_text()
    action_old = '''    font:
      size:
        xsmall: "${font.size.label}"
        small: "${font.size.label}"
        medium: "${font.size.label}"
        large: "${font.size.label}"
        xlarge: "${font.size.label}"

      lineHeight:
        xsmall: "${font.lineHeight.label}"
        small: "${font.lineHeight.label}"
        medium: "${font.lineHeight.label}"
        large: "${font.lineHeight.label}"
        xlarge: "${font.lineHeight.label}"
'''
    action_new = '''    font:
      size:
        xsmall: 0.75rem
        small: 0.8125rem
        medium: 0.875rem
        large: 0.9375rem
        xlarge: 1rem

      lineHeight:
        xsmall: 1rem
        small: 1.125rem
        medium: 1.25rem
        large: 1.375rem
        xlarge: 1.5rem
'''
    if action_old not in source:
        raise SystemExit('action font token block not found')
    source = source.replace(action_old, action_new, 1)

    input_old = '''    inputFont:
      size:
        xsmall: "${component.action.font.size.xsmall}"
        small: "${component.action.font.size.small}"
        medium: "${component.action.font.size.medium}"
        large: "${component.action.font.size.large}"
        xlarge: "${component.action.font.size.xlarge}"

      lineHeight:
        xsmall: "${component.action.font.lineHeight.xsmall}"
        small: "${component.action.font.lineHeight.small}"
        medium: "${component.action.font.lineHeight.medium}"
        large: "${component.action.font.lineHeight.large}"
        xlarge: "${component.action.font.lineHeight.xlarge}"
'''
    input_new = '''    inputFont:
      size:
        xsmall: 0.8125rem
        small: 0.875rem
        medium: 0.9375rem
        large: 1rem
        xlarge: 1.0625rem

      lineHeight:
        xsmall: 1.125rem
        small: 1.25rem
        medium: 1.375rem
        large: 1.5rem
        xlarge: 1.625rem
'''
    if input_old not in source:
        raise SystemExit('field input font token block not found')
    tokens.write_text(source.replace(input_old, input_new, 1))


def replace_avatar_playground() -> None:
    avatar = Path('widgetbook/lib/use_cases/basic/migrated_primitives.dart')
    source = avatar.read_text()
    source = source.replace(
        'enum _AvatarContent { initials, icon }',
        'enum _AvatarContent { initials, icon, image }',
        1,
    )
    initials = '''  final initials = context.knobs.string(
    label: 'Content · Initials',
    initialValue: 'NC',
  );
'''
    if initials not in source:
        raise SystemExit('avatar initials knob not found')
    source = source.replace(
        initials,
        initials
        + '''  final imageUrl = context.knobs.string(
    label: 'Content · Image URL',
    initialValue: 'https://avatars.githubusercontent.com/u/9919?v=4',
  );
''',
        1,
    )
    old = '''    CarpenterAvatar(
      initials: content == _AvatarContent.initials ? initials : null,
      size: size,
      semanticLabel: semanticLabel,
      child: content == _AvatarContent.icon
          ? const Icon(CarpenterIcons.account)
          : null,
    ),
'''
    new = '''    CarpenterAvatar(
      initials: content == _AvatarContent.icon ? null : initials,
      foregroundImage:
          content == _AvatarContent.image && imageUrl.trim().isNotEmpty
          ? NetworkImage(imageUrl.trim())
          : null,
      size: size,
      semanticLabel: semanticLabel,
      child: content == _AvatarContent.icon
          ? const Icon(CarpenterIcons.account)
          : null,
    ),
'''
    if old not in source:
        raise SystemExit('avatar playground body not found')
    avatar.write_text(source.replace(old, new, 1))


replace_action_theme()
replace_font_tokens()
replace_avatar_playground()
