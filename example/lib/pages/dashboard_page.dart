import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

import '../demo_commands.dart';
import '../demo_routes.dart';

final class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.navigator,
    required this.commands,
    required this.toaster,
  });

  final DemoNavigator navigator;
  final DemoCommands commands;
  final CarpenterToasterController toaster;

  Future<void> _sync(BuildContext context) async {
    await context.loading.track(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
      id: 'dashboard-sync',
    );
    if (!context.mounted) return;
    toaster.show(
      const CarpenterToastDescriptor(
        id: 'dashboard-synced',
        title: 'Workspace synchronized',
        message: 'The app-level LoadingBoundary tracked the operation.',
        role: FeedbackColorRole.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CarpenterPageBody(
    semanticLabel: 'Workspace overview',
    children: [
      CarpenterPageHeader(
        title: 'Overview',
        subtitle:
            'A connected application example: navigation, loading, commands, collections, drag-and-drop and adaptive layout.',
        status: const CarpenterPageStatus(
          label: 'All systems nominal',
          role: FeedbackColorRole.success,
        ),
        primaryActions: [
          CarpenterActionDescriptor(
            id: 'dashboard.sync',
            label: 'Synchronize',
            icon: GravityIcons.arrows3RotateLeft,
            onInvoke: () => _sync(context),
          ),
        ],
        secondaryActions: [
          CarpenterActionDescriptor(
            id: 'dashboard.projects',
            label: 'Open projects',
            icon: GravityIcons.layoutList,
            onInvoke: navigator.projects,
          ),
        ],
      ),
      const CarpenterRecordSummary(
        children: [
          CarpenterRecordMetric(
            label: 'Active projects',
            value: CarpenterText.title('12'),
            description: '3 require attention',
          ),
          CarpenterRecordMetric(
            label: 'Open approvals',
            value: CarpenterText.title('7'),
            description: '2 due today',
          ),
          CarpenterRecordMetric(
            label: 'Monthly volume',
            value: CarpenterText.title('1.94M'),
            description: '+8.2% from last month',
          ),
          CarpenterRecordMetric(
            label: 'Automation health',
            value: CarpenterText.title('98.7%'),
            description: 'Last 24 hours',
          ),
        ],
      ),
      CarpenterNotice(
        title: 'The example is intentionally interconnected',
        message:
            'Use Ctrl+1 through Ctrl+5 (Cmd on macOS) to navigate. Global hotkeys and sidebar items execute the same CarpenterCommand instances.',
        tone: CarpenterNoticeTone.info,
        action: CarpenterActionDescriptor(
          id: 'dashboard.hotkeys',
          label: 'Inspect hotkeys',
          onInvoke: navigator.operations,
        ),
      ),
      Wrap(
        spacing: context.units(1.rem),
        runSpacing: context.units(1.rem),
        children: [
          SizedBox(
            width: context.units(26.25.rem),
            child: CarpenterCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CarpenterText.title('App-level loading'),
                  SizedBox(height: context.units(.5.rem)),
                  const CarpenterText.body(
                    'This operation bubbles to the nearest application LoadingBoundary and appears in the global header.',
                    colorRole: ContentColorRole.secondary,
                  ),
                  SizedBox(height: context.units(1.rem)),
                  CarpenterButton.filled(
                    label: 'Run synchronization',
                    icon: GravityIcons.arrows3RotateLeft,
                    onPressed: () => _sync(context),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: context.units(26.25.rem),
            child: LoadingBoundary(
              child: _LocalOperation(toaster: toaster),
              builder: (context, state, child) => CarpenterCard(
                child: Stack(
                  children: [
                    child,
                    if (state.isLoading)
                      Positioned.fill(
                        child: ColoredBox(
                          color: CarpenterTheme.of(context).overlay.scrim,
                          child: const Center(child: CarpenterLoader()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      CarpenterPageSection(
        id: const CarpenterPageSectionId('alerts'),
        title: 'Persistent notifications',
        description:
            'Toasts are transient; notification state is an ordinary caller-owned collection.',
        child: CarpenterNotificationList(
          items: [
            CarpenterNotification(
              id: 'approval',
              title: 'Two approvals are due today',
              message: 'Expense approvals need review before 17:00.',
              tone: FeedbackColorRole.warning,
              unread: true,
              action: CarpenterActionDescriptor(
                id: 'dashboard.approval.open',
                label: 'Open operations',
                onInvoke: navigator.operations,
              ),
            ),
            const CarpenterNotification(
              id: 'sync',
              title: 'Bank synchronization healthy',
              message: 'All configured integrations completed their last run.',
              tone: FeedbackColorRole.success,
            ),
          ],
        ),
      ),
      CarpenterExpander(
        initiallyExpanded: true,
        header: const CarpenterText.title('Command-driven navigation'),
        content: Wrap(
          spacing: context.units(.75.rem),
          runSpacing: context.units(.75.rem),
          children: [
            CarpenterCommandButton<void>(command: commands.dashboard, input: null),
            CarpenterCommandButton<void>(command: commands.projects, input: null),
            CarpenterCommandButton<void>(command: commands.planning, input: null),
            CarpenterCommandButton<void>(command: commands.explorer, input: null),
            CarpenterCommandButton<void>(command: commands.operations, input: null),
            CarpenterCommandButton<void>(command: commands.settings, input: null),
          ],
        ),
      ),
    ],
  );
}

final class _LocalOperation extends StatelessWidget {
  const _LocalOperation({required this.toaster});

  final CarpenterToasterController toaster;

  Future<void> _run(BuildContext context) async {
    await context.loading.track(
      () => Future<void>.delayed(const Duration(milliseconds: 900)),
      id: 'local-card-operation',
    );
    if (!context.mounted) return;
    toaster.show(
      const CarpenterToastDescriptor(
        id: 'local-operation-done',
        title: 'Local boundary completed',
        message: 'The global header never saw this operation.',
        role: FeedbackColorRole.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CarpenterText.title('Nested LoadingBoundary'),
      SizedBox(height: context.units(.5.rem)),
      const CarpenterText.body(
        'The inner boundary intercepts loading and renders its own overlay instead of touching the application header.',
        colorRole: ContentColorRole.secondary,
      ),
      SizedBox(height: context.units(1.rem)),
      CarpenterButton(
        label: 'Run local operation',
        icon: GravityIcons.hourglass,
        onPressed: () => _run(context),
      ),
    ],
  );
}
