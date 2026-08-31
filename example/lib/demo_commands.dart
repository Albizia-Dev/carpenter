import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show SingleActivator;

import 'demo_routes.dart';

final class DemoCommands {
  DemoCommands({
    required DemoNavigator navigator,
    required CarpenterToasterController toaster,
  }) : dashboard = CarpenterCommandController<void>(
         id: 'navigation.dashboard',
         title: 'Overview',
         group: 'Navigation',
         description: 'Open the overview dashboard.',
         shortcuts: const [
           SingleActivator(LogicalKeyboardKey.digit1, control: true),
         ],
         execute: (_) {
           navigator.dashboard();
           return const CarpenterCommandResult();
         },
       ),
       projects = CarpenterCommandController<void>(
         id: 'navigation.projects',
         title: 'Projects',
         group: 'Navigation',
         description: 'Open the projects collection.',
         shortcuts: const [
           SingleActivator(LogicalKeyboardKey.digit2, control: true),
         ],
         execute: (_) {
           navigator.projects();
           return const CarpenterCommandResult();
         },
       ),
       operations = CarpenterCommandController<void>(
         id: 'navigation.operations',
         title: 'Operations',
         group: 'Navigation',
         description: 'Open loading, feedback and hotkey examples.',
         shortcuts: const [
           SingleActivator(LogicalKeyboardKey.digit3, control: true),
         ],
         execute: (_) {
           navigator.operations();
           return const CarpenterCommandResult();
         },
       ),
       planning = CarpenterCommandController<void>(
         id: 'navigation.planning',
         title: 'Planning',
         group: 'Navigation',
         description: 'Open the live drag-and-drop planning board.',
         shortcuts: const [
           SingleActivator(LogicalKeyboardKey.digit4, control: true),
         ],
         execute: (_) {
           navigator.planning();
           return const CarpenterCommandResult();
         },
       ),
       explorer = CarpenterCommandController<void>(
         id: 'navigation.explorer',
         title: 'Explorer',
         group: 'Navigation',
         description: 'Open the keyboard-friendly resource tree.',
         shortcuts: const [
           SingleActivator(LogicalKeyboardKey.digit5, control: true),
         ],
         execute: (_) {
           navigator.explorer();
           return const CarpenterCommandResult();
         },
       ),
       settings = CarpenterCommandController<void>(
         id: 'navigation.settings',
         title: 'Settings',
         group: 'Navigation',
         description: 'Open the settings form.',
         shortcuts: const [
           SingleActivator(LogicalKeyboardKey.comma, control: true),
         ],
         execute: (_) {
           navigator.settings();
           return const CarpenterCommandResult();
         },
       ),
       notify = CarpenterCommandController<void>(
         id: 'feedback.notify',
         title: 'Show notification',
         group: 'Feedback',
         description: 'Show a toast notification from a global command.',
         shortcuts: const [
           SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true),
         ],
         execute: (_) {
           toaster.show(
             const CarpenterToastDescriptor(
               id: 'command-notification',
               title: 'Global command',
               message:
                   'This toast was triggered by a Carpenter hotkey command.',
               role: FeedbackColorRole.info,
             ),
           );
           return const CarpenterCommandResult();
         },
       );

  final CarpenterCommandController<void> dashboard;
  final CarpenterCommandController<void> projects;
  final CarpenterCommandController<void> operations;
  final CarpenterCommandController<void> planning;
  final CarpenterCommandController<void> explorer;
  final CarpenterCommandController<void> settings;
  final CarpenterCommandController<void> notify;

  List<CarpenterCommand<void>> get all => <CarpenterCommand<void>>[
    dashboard,
    projects,
    operations,
    planning,
    explorer,
    settings,
    notify,
  ];

  void dispose() {
    dashboard.dispose();
    projects.dispose();
    operations.dispose();
    planning.dispose();
    explorer.dispose();
    settings.dispose();
    notify.dispose();
  }
}
