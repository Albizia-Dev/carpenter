import 'dart:async';

import 'package:carpenter/src/legacy/src/component/button/carpenter_button.dart';
import 'package:carpenter/src/legacy/src/component/control/carpenter_control.dart';
import 'package:carpenter/src/legacy/src/component/loader/carpenter_loader.dart';
import 'package:carpenter/src/legacy/src/page/capability.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/controller.dart';
import 'package:carpenter/src/legacy/src/page/descriptor.dart';
import 'package:carpenter/src/legacy/src/page/scope.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:carpenter/src/legacy/src/page/state_boundary.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Legacy loading presentation used by the compatibility API.
enum CarpenterPageLoadingPresentation { topBar, overlay }

/// Infrastructure host shared by every Carpenter page pattern.
///
/// New pages should provide [descriptor], [state] or [controller], and [body].
/// The legacy [content]/[loading] API remains available during migration.
class CarpenterPage extends StatelessWidget {
  const CarpenterPage({
    super.key,
    this.descriptor,
    this.controller,
    this.state,
    this.commands = const [],
    this.commandBindings = const [],
    this.capabilities = const [],
    this.header,
    this.body,
    this.content,
    this.footer,
    this.aside,
    this.overlay,
    this.loading = false,
    this.loadingPresentation = CarpenterPageLoadingPresentation.topBar,
  }) : assert(body != null || content != null),
       assert(body == null || content == null);

  final CarpenterPageDescriptor? descriptor;
  final CarpenterPageController? controller;
  final CarpenterPageState? state;
  final List<CarpenterCommand<dynamic>> commands;
  final List<CarpenterCommandBinding<dynamic>> commandBindings;
  final List<CarpenterPageCapability> capabilities;
  final Widget? header;
  final Widget? body;

  /// Compatibility alias for [body].
  final Widget? content;
  final Widget? footer;
  final Widget? aside;
  final Widget? overlay;

  /// Compatibility input mapped to a typed page state.
  final bool loading;

  /// Compatibility presentation for [loading].
  final CarpenterPageLoadingPresentation loadingPresentation;

  @override
  Widget build(BuildContext context) {
    final pageController = controller;
    if (pageController != null && state == null) {
      return ValueListenableBuilder<CarpenterPageState>(
        valueListenable: pageController,
        builder: (context, controllerState, _) =>
            _buildHost(context, controllerState),
      );
    }
    return _buildHost(context, _effectiveState);
  }

  CarpenterPageState get _effectiveState {
    final explicit = state;
    if (explicit != null) return explicit;
    if (!loading) return const CarpenterPageReady();
    return loadingPresentation == CarpenterPageLoadingPresentation.overlay
        ? const CarpenterPageBlocking()
        : const CarpenterPageRefreshing();
  }

  Widget _buildHost(BuildContext context, CarpenterPageState pageState) {
    final face = context.face;
    final pageDescriptor =
        descriptor ??
        const CarpenterPageDescriptor(
          id: CarpenterPageId('legacy-page'),
          title: 'Page',
          kind: CarpenterPageKind.custom,
        );
    final permission = pageDescriptor.permission;
    final resolvedState = permission != null && !permission.granted
        ? CarpenterPageForbidden(reason: permission.reason)
        : pageState;
    final pageCommands = <CarpenterCommand<dynamic>>[
      ...?controller?.pageCommands,
      ...commands,
      for (final binding in commandBindings) binding.command,
    ];
    final pageBody = body ?? content!;

    Widget result = ColoredBox(
      color: face.color('surface.base'),
      child: SafeArea(
        child: DefaultTextStyle.merge(
          style: face.type('body').copyWith(color: face.color('text.primary')),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(face.space('1')),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (header != null) ...[
                        header!,
                        SizedBox(height: face.space('1')),
                      ],
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: CarpenterPageStateBoundary(
                                state: resolvedState,
                                child: pageBody,
                              ),
                            ),
                            if (aside != null) ...[
                              SizedBox(width: face.space('1')),
                              aside!,
                            ],
                          ],
                        ),
                      ),
                      if (footer != null) ...[
                        SizedBox(height: face.space('1')),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
              if (overlay != null) Positioned.fill(child: overlay!),
            ],
          ),
        ),
      ),
    );

    result = CarpenterCommandScope(commands: pageCommands, child: result);
    if (commandBindings.isNotEmpty) {
      result = CarpenterCommandShortcutScope(
        bindings: commandBindings,
        child: result,
      );
    }
    return CarpenterPageScope(
      descriptor: pageDescriptor,
      controller: controller,
      commands: pageCommands,
      capabilities: capabilities,
      child: result,
    );
  }
}

class CarpenterPageLoadingBar extends StatefulWidget {
  const CarpenterPageLoadingBar({super.key});

  @override
  State<CarpenterPageLoadingBar> createState() =>
      _CarpenterPageLoadingBarState();
}

class _CarpenterPageLoadingBarState extends State<CarpenterPageLoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    return Semantics(
      label: 'Загрузка',
      liveRegion: true,
      child: SizedBox(
        height: face.size('progress.height'),
        child: ClipRect(
          child: DecoratedBox(
            decoration: BoxDecoration(color: face.color('surface.muted')),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => FractionalTranslation(
                translation: Offset(_controller.value * 4 - 1, 0),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.28,
                  child: ColoredBox(color: face.color('action.primary')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CarpenterPageHeader extends StatelessWidget {
  const CarpenterPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.commandBar,
    this.breadcrumbs = const [],
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? commandBar;
  final List<Widget> breadcrumbs;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          style: face.type('title').copyWith(color: face.color('text.primary')),
          child: title,
        ),
        if (subtitle != null) ...[
          SizedBox(height: face.space('0.25')),
          DefaultTextStyle.merge(
            style: face
                .type('body')
                .copyWith(color: face.color('text.secondary')),
            child: subtitle!,
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (breadcrumbs.isNotEmpty) ...[
              DefaultTextStyle.merge(
                style: face
                    .type('caption')
                    .copyWith(color: face.color('text.secondary')),
                child: Wrap(
                  spacing: face.space('0.375'),
                  runSpacing: face.space('0.25'),
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: breadcrumbs,
                ),
              ),
              SizedBox(height: face.space('0.5')),
            ],
            if (compact) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: face.space('0.625')),
                  ],
                  Expanded(child: heading),
                ],
              ),
              if (commandBar != null) ...[
                SizedBox(height: face.space('0.75')),
                commandBar!,
              ],
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: face.space('0.625')),
                  ],
                  Expanded(child: heading),
                  if (commandBar != null) ...[
                    SizedBox(width: face.space('1')),
                    commandBar!,
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

/// Interactive item for page breadcrumbs.
class CarpenterBreadcrumb extends StatelessWidget {
  const CarpenterBreadcrumb({super.key, required this.child, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    if (onPressed == null) {
      return DefaultTextStyle.merge(
        style: face
            .type('caption')
            .copyWith(color: face.color('text.secondary')),
        child: child,
      );
    }
    return CarpenterControl(
      onTap: onPressed,
      semanticButton: false,
      semanticLink: true,
      builder: (context, state) => DefaultTextStyle.merge(
        style: face
            .type('caption')
            .copyWith(
              color: state.hovered || state.focused
                  ? face.color('action.primary')
                  : face.color('text.secondary'),
              decoration: state.hovered
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
        child: child,
      ),
    );
  }
}

enum CarpenterNoticeTone { info, success, warning, danger }

class CarpenterNotice extends StatelessWidget {
  const CarpenterNotice({
    super.key,
    required this.title,
    this.content,
    this.tone = CarpenterNoticeTone.info,
    this.severity,
    this.action,
    this.onClose,
  });

  final Widget title;
  final Widget? content;
  final CarpenterNoticeTone tone;
  final CarpenterNoticeTone? severity;
  final Widget? action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final effectiveTone = severity ?? tone;
    final (background, foreground) = switch (effectiveTone) {
      CarpenterNoticeTone.info => (
        face.color('status.info.surface'),
        face.color('status.info'),
      ),
      CarpenterNoticeTone.success => (
        face.color('status.success.surface'),
        face.color('status.success'),
      ),
      CarpenterNoticeTone.warning => (
        face.color('status.warning.surface'),
        face.color('status.warning'),
      ),
      CarpenterNoticeTone.danger => (
        face.color('status.danger.surface'),
        face.color('status.danger'),
      ),
    };
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          style: face.type('label.strong').copyWith(color: foreground),
          child: title,
        ),
        if (content != null) ...[
          SizedBox(height: face.space('0.25')),
          DefaultTextStyle.merge(
            style: face
                .type('body')
                .copyWith(color: face.color('text.primary')),
            child: content!,
          ),
        ],
      ],
    );
    final actions = <Widget>[
      if (action != null) action!,
      if (onClose != null)
        CarpenterIconButton(
          icon: const Text('×'),
          semanticLabel: 'Закрыть',
          onPressed: onClose,
        ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(face.radius('lg')),
      ),
      child: Padding(
        padding: EdgeInsets.all(face.space('0.75')),
        child: LayoutBuilder(
          builder: (context, constraints) =>
              constraints.maxWidth < 520 && actions.isNotEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    SizedBox(height: face.space('0.75')),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: face.space('0.5'),
                      runSpacing: face.space('0.5'),
                      children: actions,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    if (actions.isNotEmpty) ...[
                      SizedBox(width: face.space('0.75')),
                      ...actions,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class CarpenterIconButton extends StatelessWidget {
  const CarpenterIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.semanticLabel,
    this.compact = false,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CarpenterControl(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, state) {
        final face = context.face;
        return AnimatedContainer(
          duration: face.motion.fast,
          curve: face.motion.curve,
          constraints: BoxConstraints.tightFor(
            width: face.rem(compact ? 1.75 : 2),
            height: face.rem(compact ? 1.75 : 2),
          ),
          decoration: BoxDecoration(
            color: state.pressed
                ? face.color('surface.muted')
                : state.hovered || state.focused
                ? Color.lerp(
                    const Color(0x00000000),
                    face.color('text.primary'),
                    0.08,
                  )
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(face.radius('control')),
          ),
          padding: EdgeInsets.all(face.space(compact ? '0.25' : '0.5')),
          child: Opacity(
            opacity: state.enabled ? 1 : 0.45,
            child: IconTheme.merge(
              data: IconThemeData(
                color: face.color('text.primary'),
                size: face.rem(compact ? 0.875 : 1),
              ),
              child: icon,
            ),
          ),
        );
      },
    );
  }
}

class CarpenterToggleButton extends StatelessWidget {
  const CarpenterToggleButton({
    super.key,
    required this.checked,
    required this.child,
    this.onChanged,
    this.compact = false,
  });

  final bool checked;
  final Widget child;
  final ValueChanged<bool>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CarpenterControl(
      onTap: onChanged == null ? null : () => onChanged!(!checked),
      semanticToggled: checked,
      builder: (context, state) {
        final face = context.face;
        return AnimatedContainer(
          duration: face.motion.fast,
          curve: face.motion.curve,
          constraints: BoxConstraints(minHeight: face.rem(compact ? 1.75 : 2)),
          decoration: BoxDecoration(
            color: !state.enabled
                ? face.color('action.disabled')
                : checked
                ? face.color('action.primary')
                : state.pressed
                ? Color.lerp(
                    face.color('surface.raised'),
                    face.color('action.primary'),
                    0.12,
                  )
                : state.hovered || state.focused
                ? Color.lerp(
                    face.color('surface.raised'),
                    face.color('action.primary'),
                    0.07,
                  )
                : face.color('surface.raised'),
            border: Border.all(color: face.color('border.normal')),
            borderRadius: BorderRadius.circular(face.radius('lg')),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: face.space(compact ? '0.375' : '0.75'),
            vertical: face.space(compact ? '0.25' : '0.375'),
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              size: face.rem(compact ? 0.875 : 1),
              color: checked
                  ? state.enabled
                        ? face.color('action.primary.text')
                        : face.color('action.disabled.text')
                  : state.enabled
                  ? face.color('text.primary')
                  : face.color('action.disabled.text'),
            ),
            child: DefaultTextStyle.merge(
              style: face
                  .type(compact ? 'caption' : 'label')
                  .copyWith(
                    color: checked
                        ? state.enabled
                              ? face.color('action.primary.text')
                              : face.color('action.disabled.text')
                        : state.enabled
                        ? face.color('text.primary')
                        : face.color('action.disabled.text'),
                  ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class CarpenterTab<T> {
  const CarpenterTab({required this.value, required this.child});

  final T value;
  final Widget child;
}

class CarpenterTabs<T> extends StatelessWidget {
  const CarpenterTabs({
    super.key,
    required this.value,
    required this.tabs,
    required this.onChanged,
  });

  final T value;
  final List<CarpenterTab<T>> tabs;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.face.space('0.25'),
    children: [
      for (final tab in tabs)
        _CarpenterTabButton(
          selected: tab.value == value,
          onPressed: () => onChanged(tab.value),
          child: tab.child,
        ),
    ],
  );
}

class _CarpenterTabButton extends StatelessWidget {
  const _CarpenterTabButton({
    required this.selected,
    required this.onPressed,
    required this.child,
  });

  final bool selected;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => CarpenterControl(
    onTap: onPressed,
    semanticButton: false,
    semanticSelected: selected,
    builder: (context, state) {
      final face = context.face;
      return AnimatedContainer(
        duration: face.motion.fast,
        padding: EdgeInsets.symmetric(
          horizontal: face.space('0.75'),
          vertical: face.space('0.5'),
        ),
        decoration: BoxDecoration(
          color: state.pressed
              ? Color.lerp(
                  const Color(0x00000000),
                  face.color('action.primary'),
                  0.12,
                )
              : state.hovered || state.focused
              ? Color.lerp(
                  const Color(0x00000000),
                  face.color('action.primary'),
                  0.07,
                )
              : const Color(0x00000000),
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: selected
                  ? face.color('action.primary')
                  : const Color(0x00000000),
            ),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: face
              .type(selected ? 'label.strong' : 'label')
              .copyWith(color: face.color('text.primary')),
          child: child,
        ),
      );
    },
  );
}

class CarpenterFieldLabel extends StatelessWidget {
  const CarpenterFieldLabel({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: face
              .type('label.strong')
              .copyWith(color: face.color('text.primary')),
        ),
        SizedBox(height: face.space('0.375')),
        child,
      ],
    );
  }
}

class CarpenterListTile extends StatelessWidget {
  const CarpenterListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onPressed,
  });

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CarpenterControl(
      onTap: onPressed,
      builder: (context, state) {
        final face = context.face;
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DefaultTextStyle.merge(
              style: face
                  .type('label.strong')
                  .copyWith(color: face.color('text.primary')),
              child: title,
            ),
            if (subtitle != null) ...[
              SizedBox(height: face.space('0.25')),
              DefaultTextStyle.merge(
                style: face
                    .type('body')
                    .copyWith(color: face.color('text.secondary')),
                child: subtitle!,
              ),
            ],
          ],
        );
        return AnimatedContainer(
          duration: face.motion.normal,
          curve: face.motion.curve,
          decoration: BoxDecoration(
            color: state.pressed
                ? Color.lerp(
                    const Color(0x00000000),
                    face.color('text.primary'),
                    0.12,
                  )
                : state.hovered || state.focused
                ? Color.lerp(
                    const Color(0x00000000),
                    face.color('text.primary'),
                    0.07,
                  )
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(face.radius('lg')),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: face.space('0.75'),
            vertical: face.space('0.625'),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = trailing != null && constraints.maxWidth < 480;
              final main = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: face.space('0.75')),
                  ],
                  Expanded(child: details),
                  if (!compact && trailing != null) ...[
                    SizedBox(width: face.space('0.75')),
                    trailing!,
                  ],
                ],
              );
              if (!compact) return main;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  main,
                  SizedBox(height: face.space('0.75')),
                  Align(alignment: Alignment.centerRight, child: trailing!),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class CarpenterExpander extends StatefulWidget {
  const CarpenterExpander({
    super.key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.onChanged,
  });

  final Widget header;
  final Widget content;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onChanged;

  @override
  State<CarpenterExpander> createState() => _CarpenterExpanderState();
}

class _CarpenterExpanderState extends State<CarpenterExpander> {
  late bool expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant CarpenterExpander oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: face.color('surface.raised'),
        border: Border.all(color: face.color('border.subtle')),
        borderRadius: BorderRadius.circular(face.radius('lg')),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(face.radius('lg')),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterListTile(
              title: widget.header,
              trailing: Text(expanded ? '⌃' : '⌄'),
              onPressed: () {
                setState(() => expanded = !expanded);
                widget.onChanged?.call(expanded);
              },
            ),
            AnimatedSize(
              duration: face.motion.normal,
              curve: face.motion.curve,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: EdgeInsets.all(face.space('0.75')),
                      child: widget.content,
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

class CarpenterSelectItem<T> {
  const CarpenterSelectItem({required this.value, required this.child});

  final T value;
  final Widget child;
}

class CarpenterSelect<T> extends StatelessWidget {
  const CarpenterSelect({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.isExpanded = false,
    this.compact = false,
    this.placeholder,
  });

  final T? value;
  final List<CarpenterSelectItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded;
  final bool compact;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    CarpenterSelectItem<T>? selected;
    for (final item in items) {
      if (item.value == value) selected = item;
    }
    final selectedChild =
        selected?.child ?? placeholder ?? const Text('Выберите');
    final button = CarpenterButton(
      type: .outlined,
      color: .secondary,
      compact: compact,
      onPressed: onChanged == null
          ? null
          : () async {
              final result =
                  await showCarpenterDialog<_CarpenterSelectResult<T>>(
                    context: context,
                    builder: (dialogContext) => CarpenterDialog(
                      title: const Text('Выберите значение'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final item in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: CarpenterButton(
                                type: .outlined,
                                color: .secondary,
                                onPressed: () => Navigator.pop(
                                  dialogContext,
                                  _CarpenterSelectResult(item.value),
                                ),
                                child: item.child,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
              if (result != null) onChanged?.call(result.value);
            },
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (isExpanded)
            Expanded(
              child: DefaultTextStyle.merge(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: selectedChild,
              ),
            )
          else
            DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: selectedChild,
            ),
          const SizedBox(width: 8),
          const Text('⌄'),
        ],
      ),
    );
    return isExpanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

class _CarpenterSelectResult<T> {
  const _CarpenterSelectResult(this.value);

  final T value;
}

class CarpenterDialog extends StatelessWidget {
  const CarpenterDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.constraints = const BoxConstraints(maxWidth: 720, maxHeight: 760),
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    return Center(
      child: ConstrainedBox(
        constraints: constraints,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: face.color('surface.raised'),
            border: Border.all(color: face.color('border.normal')),
            borderRadius: BorderRadius.circular(face.radius('lg')),
          ),
          child: Padding(
            padding: EdgeInsets.all(face.space('1')),
            child: DefaultTextStyle(
              style: face
                  .type('body')
                  .copyWith(color: face.color('text.primary')),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DefaultTextStyle.merge(
                    style: face
                        .type('title')
                        .copyWith(color: face.color('text.primary')),
                    child: title,
                  ),
                  SizedBox(height: face.space('1')),
                  Flexible(child: content),
                  if (actions.isNotEmpty) ...[
                    SizedBox(height: face.space('1')),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: face.space('0.5'),
                      runSpacing: face.space('0.5'),
                      children: actions,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showCarpenterDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: barrierDismissible,
      barrierColor: context.face.color('surface.scrim'),
      pageBuilder: (context, animation, secondaryAnimation) => Directionality(
        textDirection: Directionality.of(context),
        child: builder(context),
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class CarpenterIndeterminateProgress extends StatelessWidget {
  const CarpenterIndeterminateProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: face.size('loader'),
        height: face.size('loader'),
        child: const CarpenterLoader(),
      ),
    );
  }
}

/// Минимальный нейтральный набор glyph ids. Приложение может заменить его
/// собственным icon font через отдельный компонентный adapter.
abstract final class CarpenterIcons {
  static const accept = IconData(0x2713);
  static const search = IconData(0x2315);
  static const list = IconData(0x2637);
  static const tree = IconData(0x2442);
  static const branchFork = tree;
  static const refresh = IconData(0x21BB);
  static const clear = IconData(0x00D7);
  static const back = IconData(0x2190);
  static const next = IconData(0x2192);
  static const chevronLeft = back;
  static const chevronRight = next;
  static const add = IconData(0x002B);
  static const edit = IconData(0x270E);
  static const archive = IconData(0x25A3);
  static const restore = IconData(0x21B6);
  static const lock = IconData(0x26BF);
  static const account = IconData(0x25A4);
  static const paymentCard = account;
  static const bank = IconData(0x25B1);
  static const bankSolid = bank;
  static const file = IconData(0x25A7);
  static const openFile = file;
  static const warning = IconData(0x26A0);
  static const errorBadge = warning;
  static const info = IconData(0x24D8);
  static const download = IconData(0x21E9);
  static const upload = IconData(0x21E7);
  static const arrowDownFilled = IconData(0x2B07);
  static const arrowUpRight = IconData(0x2197);
  static const more = IconData(0x2026);
  static const save = IconData(0x25A9);
  static const copy = IconData(0x29C9);
  static const calendar = IconData(0x25A6);
  static const code = IconData(0x2328);
  static const completedSolid = accept;
  static const removeLink = IconData(0x29C0);
  static const sortDown = IconData(0x2193);
  static const sortUp = IconData(0x2191);
}
