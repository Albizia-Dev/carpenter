import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

final class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key, required this.toaster});

  final CarpenterToasterController toaster;

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

final class _OperationsPageState extends State<OperationsPage> {
  var _dialogOpen = false;

  void _runConcurrent(BuildContext context) {
    unawaited(
      context.loading.track(
        () => Future<void>.delayed(const Duration(milliseconds: 1200)),
        id: 'operations-a',
      ),
    );
    unawaited(
      context.loading.track(
        () => Future<void>.delayed(const Duration(milliseconds: 2200)),
        id: 'operations-b',
      ),
    );
  }

  void _runSameId(BuildContext context) {
    unawaited(
      context.loading.track(
        () => Future<void>.delayed(const Duration(milliseconds: 1000)),
        id: 'same-operation',
      ),
    );
    unawaited(
      context.loading.track(
        () => Future<void>.delayed(const Duration(milliseconds: 1900)),
        id: 'same-operation',
      ),
    );
  }

  void _toast(FeedbackColorRole role, String title) {
    widget.toaster.show(
      CarpenterToastDescriptor(
        id: 'toast-${role.name}',
        title: title,
        message: 'ToastRegion owns transient presentation, not application state.',
        role: role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    open: _dialogOpen,
    onOpenChanged: (value) => setState(() => _dialogOpen = value),
    title: 'Controlled Carpenter dialog',
    content: const CarpenterText.body(
      'The dialog traps focus, supports Escape dismissal and uses the same semantic theme as the rest of the application.',
    ),
    actions: [
      CarpenterActionDescriptor(
        id: 'dialog.close',
        label: 'Done',
        onInvoke: () => setState(() => _dialogOpen = false),
      ),
    ],
    dismissPolicy: DialogDismissPolicy.outsideAndEscape,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CarpenterPageHeader(
          title: 'Operations lab',
          subtitle:
              'Loading aggregation, nested boundaries, global hotkeys, transient feedback and controlled overlays in one page.',
          status: const CarpenterPageStatus(
            label: 'Interactive',
            role: FeedbackColorRole.info,
          ),
          primaryActions: [
            CarpenterActionDescriptor(
              id: 'operations.dialog',
              label: 'Open dialog',
              icon: Icons.open_in_new,
              onInvoke: () => setState(() => _dialogOpen = true),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const CarpenterHotkeyDisplay(
          title: 'Global command hotkeys',
          showCommands: true,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 430,
              child: CarpenterCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CarpenterText.title('Aggregated loading'),
                    const SizedBox(height: 8),
                    const CarpenterText.body(
                      'Start two operations. The global header remains loading until both finish.',
                      colorRole: ContentColorRole.secondary,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        CarpenterButton.filled(
                          label: 'Run A + B',
                          icon: Icons.play_arrow,
                          onPressed: () => _runConcurrent(context),
                        ),
                        CarpenterButton(
                          label: 'Same ID twice',
                          onPressed: () => _runSameId(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 430,
              child: LoadingBoundary(
                child: const _BlockedRegion(),
                builder: (context, state, child) => CarpenterCard(
                  child: Stack(
                    children: [
                      child,
                      if (state.isLoading)
                        Positioned.fill(
                          child: ColoredBox(
                            color: CarpenterTheme.of(context).overlay.scrim,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CarpenterLoader(),
                                  const SizedBox(height: 8),
                                  CarpenterText.body(
                                    '${state.activeCount} local operation(s)',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        CarpenterCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CarpenterText.title('Transient feedback'),
              const SizedBox(height: 8),
              const CarpenterText.body(
                'Toast stacking, semantic roles and controlled dialog presentation.',
                colorRole: ContentColorRole.secondary,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CarpenterButton(
                    label: 'Success toast',
                    onPressed: () => _toast(
                      FeedbackColorRole.success,
                      'Operation completed',
                    ),
                  ),
                  CarpenterButton(
                    label: 'Warning toast',
                    colorRole: ActionColorRole.warning,
                    onPressed: () => _toast(
                      FeedbackColorRole.warning,
                      'Review required',
                    ),
                  ),
                  CarpenterButton(
                    label: 'Danger toast',
                    colorRole: ActionColorRole.danger,
                    onPressed: () => _toast(
                      FeedbackColorRole.danger,
                      'Operation failed',
                    ),
                  ),
                  CarpenterButton(
                    label: 'Open dialog',
                    icon: Icons.open_in_new,
                    onPressed: () => setState(() => _dialogOpen = true),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const CarpenterNotice(
          title: 'Nearest scope wins',
          message:
              'The local blocked region below has its own LoadingBoundary, so its work never reaches the progress indicator in the application header.',
          tone: CarpenterNoticeTone.info,
        ),
      ],
    ),
  );
}

final class _BlockedRegion extends StatelessWidget {
  const _BlockedRegion();

  Future<void> _run(BuildContext context) => context.loading.track(
    () => Future<void>.delayed(const Duration(milliseconds: 1500)),
    id: 'local-blocked-region',
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CarpenterText.title('Locally blocked region'),
      const SizedBox(height: 8),
      const CarpenterText.body(
        'This child does not know that its boundary renders an overlay.',
        colorRole: ContentColorRole.secondary,
      ),
      const SizedBox(height: 16),
      CarpenterButton(
        label: 'Run local task',
        icon: Icons.lock_clock,
        onPressed: () => _run(context),
      ),
    ],
  );
}
