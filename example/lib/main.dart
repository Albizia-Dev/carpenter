import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const CoreComponentsExample());

final class CoreComponentsExample extends StatelessWidget {
  const CoreComponentsExample({super.key});

  @override
  Widget build(BuildContext context) {
    final carpenterTheme = CarpenterThemeData.light();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UnitsRoot(
        rem: const Px(16),
        child: CarpenterTheme(
          data: carpenterTheme,
          child: Builder(
            builder: (context) => Scaffold(
              backgroundColor: carpenterTheme.surface.base,
              body: const SafeArea(child: _CoreComponentsScreen()),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ExamplePlan { starter, team, enterprise }

final class _CoreComponentsScreen extends StatefulWidget {
  const _CoreComponentsScreen();

  @override
  State<_CoreComponentsScreen> createState() => _CoreComponentsScreenState();
}

final class _CoreComponentsScreenState extends State<_CoreComponentsScreen> {
  final _nameController = TextEditingController(text: 'Carpenter');
  final _notesController = TextEditingController(
    text: 'Semantic controls\nControlled state',
  );
  var _checkbox = CheckboxValue.mixed;
  var _plan = _ExamplePlan.team;
  var _notifications = true;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CarpenterText('Core components', role: TypographyRole.display),
          const SizedBox(height: 32),
          const _Section(
            title: 'Typography',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CarpenterText.title('Semantic title'),
                CarpenterText.body('Body text follows inherited scaling.'),
                CarpenterText.caption(
                  'Muted supporting text',
                  colorRole: ContentColorRole.muted,
                ),
              ],
            ),
          ),
          const _Section(
            title: 'Icons',
            child: Row(
              children: [
                CarpenterIcon(Icons.home, semanticLabel: 'Home'),
                CarpenterIcon(
                  Icons.star,
                  colorRole: ContentColorRole.secondary,
                ),
                CarpenterIcon(Icons.info, size: IconSize.large),
              ],
            ),
          ),
          const _Section(
            title: 'Statuses',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CarpenterStatusIndicator(
                  label: 'Ready',
                  role: FeedbackColorRole.success,
                ),
                CarpenterStatusIndicator(
                  label: 'Needs attention',
                  role: FeedbackColorRole.warning,
                ),
                CarpenterStatusIndicator(
                  label: 'Failed',
                  role: FeedbackColorRole.danger,
                ),
              ],
            ),
          ),
          const _Section(
            title: 'Buttons',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CarpenterButton(
                  label: 'Save',
                  icon: Icons.save,
                  colorRole: ActionColorRole.primary,
                  prominence: ActionProminence.high,
                  onInvoke: _noop,
                ),
                CarpenterButton(label: 'Disabled'),
                CarpenterButton(
                  label: 'Synchronizing',
                  executionPhase: ActionExecutionPhase.running,
                  onInvoke: _noop,
                ),
              ],
            ),
          ),
          _Section(
            title: 'Fields',
            child: Column(
              children: [
                CarpenterInput(
                  controller: _nameController,
                  label: 'Project name',
                  description: 'Uses the shared semantic field contract',
                  leadingIcon: Icons.edit,
                ),
                const SizedBox(height: 12),
                CarpenterTextArea(
                  controller: _notesController,
                  label: 'Notes',
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          _Section(
            title: 'Value controls',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CarpenterCheckbox(
                  value: _checkbox,
                  label: 'Include archived records',
                  onChanged: (value) => setState(() => _checkbox = value),
                ),
                CarpenterRadioGroup<_ExamplePlan>(
                  value: _plan,
                  onChanged: (value) => setState(() => _plan = value),
                  children: const [
                    CarpenterRadio(
                      value: _ExamplePlan.starter,
                      label: 'Starter',
                    ),
                    CarpenterRadio(value: _ExamplePlan.team, label: 'Team'),
                    CarpenterRadio(
                      value: _ExamplePlan.enterprise,
                      label: 'Enterprise',
                    ),
                  ],
                ),
                CarpenterSwitch(
                  value: _notifications,
                  label: 'Notifications',
                  onChanged: (value) => setState(() => _notifications = value),
                ),
              ],
            ),
          ),
          const _Section(
            title: 'Icon buttons',
            child: Row(
              children: [
                CarpenterIconButton(
                  icon: Icons.add,
                  semanticLabel: 'Add',
                  onInvoke: _noop,
                ),
                CarpenterIconButton(
                  icon: Icons.delete,
                  semanticLabel: 'Delete',
                  colorRole: ActionColorRole.danger,
                  onInvoke: _noop,
                ),
                CarpenterIconButton(
                  icon: Icons.sync,
                  semanticLabel: 'Synchronizing',
                  executionPhase: ActionExecutionPhase.running,
                  onInvoke: _noop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarpenterText.title(title, emphasis: TypographyEmphasis.strong),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

void _noop() {}
