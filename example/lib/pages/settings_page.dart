import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:carpenter_units/carpenter_units.dart';

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
    padding: EdgeInsets.all(context.units(context.units(.09375.rem).rem)),
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
      SizedBox(height: context.units(1.5.rem)),
      if (_dirty) ...[
        const CarpenterNotice(
          title: 'Unsaved changes',
          message:
              'The page owns form state. Loading presentation still belongs to the application boundary.',
          tone: CarpenterNoticeTone.warning,
        ),
        SizedBox(height: context.units(1.rem)),
      ],
      CarpenterCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CarpenterText.title('Profile'),
            SizedBox(height: context.units(1.rem)),
            CarpenterInput(
              controller: _nameController,
              label: 'Display name',
              description: 'Shown in the navigation footer.',
              leadingIcon: Icons.person_outline,
            ),
            SizedBox(height: context.units(1.rem)),
            CarpenterTextArea(
              controller: _notesController,
              label: 'Workspace note',
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
      ),
      SizedBox(height: context.units(1.rem)),
      CarpenterCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CarpenterText.title('Preferences'),
            SizedBox(height: context.units(1.rem)),
            CarpenterSwitch(
              value: _notifications,
              label: 'Enable notifications',
              onChanged: (value) => setState(() {
                _notifications = value;
                _dirty = true;
              }),
            ),
            SizedBox(height: context.units(.75.rem)),
            CarpenterCheckbox(
              value: _includeArchived,
              label: 'Include archived items by default',
              onChanged: (value) => setState(() {
                _includeArchived = value;
                _dirty = true;
              }),
            ),
            SizedBox(height: context.units(1.rem)),
            const CarpenterText.label(
              'Interface density',
              emphasis: TypographyEmphasis.strong,
            ),
            SizedBox(height: context.units(.5.rem)),
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
      SizedBox(height: context.units(1.rem)),
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
