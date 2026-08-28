import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

final class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.toaster});

  final CarpenterToasterController toaster;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _DensityPreference { comfortable, compact }

final class _SettingsPageState extends State<SettingsPage> {
  final _nameController = TextEditingController(text: 'Demo operator');
  final _notesController = TextEditingController(
    text: 'Carpenter example workspace',
  );
  var _notifications = true;
  var _includeArchived = CheckboxValue.unchecked;
  var _density = _DensityPreference.comfortable;
  var _dirty = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
  }

  void _markDirty() {
    if (_dirty || !mounted) return;
    setState(() => _dirty = true);
  }

  Future<void> _save() async {
    await context.loading.track(
      () => Future<void>.delayed(const Duration(milliseconds: 1250)),
      id: 'settings-save',
    );
    if (!mounted) return;
    setState(() => _dirty = false);
    widget.toaster.show(
      const CarpenterToastDescriptor(
        id: 'settings-saved',
        title: 'Settings saved',
        message: 'The form used the nearest application LoadingBoundary.',
        role: FeedbackColorRole.success,
      ),
    );
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_markDirty)
      ..dispose();
    _notesController
      ..removeListener(_markDirty)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      CarpenterPageHeader(
        title: 'Settings',
        subtitle:
            'A controlled form composed from Carpenter fields and value controls.',
        status: CarpenterPageStatus(
          label: _dirty ? 'Unsaved changes' : 'Saved',
          role: _dirty ? FeedbackColorRole.warning : FeedbackColorRole.success,
        ),
        primaryActions: [
          CarpenterActionDescriptor(
            id: 'settings.save',
            label: 'Save changes',
            icon: Icons.save_outlined,
            onInvoke: _dirty ? _save : null,
          ),
        ],
      ),
      const SizedBox(height: 24),
      if (_dirty) ...[
        const CarpenterNotice(
          title: 'Unsaved changes',
          message:
              'The page owns form state. Loading presentation still belongs to the application boundary.',
          tone: CarpenterNoticeTone.warning,
        ),
        const SizedBox(height: 16),
      ],
      CarpenterCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CarpenterText.title('Profile'),
            const SizedBox(height: 16),
            CarpenterInput(
              controller: _nameController,
              label: 'Display name',
              description: 'Shown in the navigation footer.',
              leadingIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            CarpenterTextArea(
              controller: _notesController,
              label: 'Workspace note',
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      CarpenterCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CarpenterText.title('Preferences'),
            const SizedBox(height: 16),
            CarpenterSwitch(
              value: _notifications,
              label: 'Enable notifications',
              onChanged: (value) => setState(() {
                _notifications = value;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 12),
            CarpenterCheckbox(
              value: _includeArchived,
              label: 'Include archived items by default',
              onChanged: (value) => setState(() {
                _includeArchived = value;
                _dirty = true;
              }),
            ),
            const SizedBox(height: 16),
            const CarpenterText.label(
              'Interface density',
              emphasis: TypographyEmphasis.strong,
            ),
            const SizedBox(height: 8),
            CarpenterRadioGroup<_DensityPreference>(
              value: _density,
              onChanged: (value) => setState(() {
                _density = value;
                _dirty = true;
              }),
              children: const [
                CarpenterRadio(
                  value: _DensityPreference.comfortable,
                  label: 'Comfortable',
                ),
                CarpenterRadio(
                  value: _DensityPreference.compact,
                  label: 'Compact',
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: CarpenterButton.filled(
          label: 'Save changes',
          icon: Icons.save_outlined,
          onPressed: _dirty ? _save : null,
        ),
      ),
    ],
  );
}
