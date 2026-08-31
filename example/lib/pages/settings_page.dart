import 'package:carpenter/carpenter.dart';
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
  final _codeController = TextEditingController(text: 'CP-1042');
  final _ownerController = TextEditingController(text: 'Finance platform');
  final _tagController = TextEditingController();

  var _notifications = true;
  var _includeArchived = CheckboxValue.unchecked;
  var _density = _DensityPreference.comfortable;
  var _timezone = 'Asia/Tashkent';
  String? _owner = 'Finance platform';
  num? _defaultBudget = 250000;
  DateTime? _reviewDate = DateTime(2026, 9, 15);
  CarpenterTime? _syncTime = const CarpenterTime(hour: 9, minute: 30);
  CarpenterDateRange? _reportingWindow = CarpenterDateRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 30),
  );
  List<CarpenterFileCandidate<String>> _files = const [];
  var _browseRevision = 0;
  var _dirty = false;

  static const _owners = <CarpenterOption<String>>[
    CarpenterOption(
      id: 'finance',
      value: 'Finance platform',
      label: 'Finance platform',
    ),
    CarpenterOption(
      id: 'delivery',
      value: 'Delivery',
      label: 'Delivery',
    ),
    CarpenterOption(
      id: 'platform',
      value: 'Client platform',
      label: 'Client platform',
    ),
    CarpenterOption(
      id: 'operations',
      value: 'Operations',
      label: 'Operations',
    ),
  ];

  static const _tags = <CarpenterOption<String>>[
    CarpenterOption(id: 'critical', value: 'critical', label: 'critical'),
    CarpenterOption(id: 'migration', value: 'migration', label: 'migration'),
    CarpenterOption(id: 'finance', value: 'finance', label: 'finance'),
    CarpenterOption(id: 'mobile', value: 'mobile', label: 'mobile'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_markDirty);
    _notesController.addListener(_markDirty);
    _codeController.addListener(_markDirty);
  }

  void _markDirty() {
    if (_dirty || !mounted) return;
    setState(() => _dirty = true);
  }

  void _change(VoidCallback change) {
    setState(() {
      change();
      _dirty = true;
    });
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
        message: 'Typed values stayed caller-owned while transient UI stayed local.',
        role: FeedbackColorRole.success,
      ),
    );
  }

  void _fakeBrowse() {
    final revision = ++_browseRevision;
    final next = CarpenterFileCandidate<String>(
      id: 'attachment-$revision',
      value: 'attachment-$revision.pdf',
      name: 'approval-$revision.pdf',
      sizeBytes: 84000 + revision * 1200,
      mimeType: 'application/pdf',
    );
    _change(() => _files = [..._files, next]);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_markDirty)
      ..dispose();
    _notesController
      ..removeListener(_markDirty)
      ..dispose();
    _codeController
      ..removeListener(_markDirty)
      ..dispose();
    _ownerController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterPageBody(
    semanticLabel: 'Workspace settings',
    children: [
      CarpenterPageHeader(
        title: 'Settings',
        subtitle:
            'A production-shaped controlled form using plain, masked, typed, selectable and file fields.',
        status: CarpenterPageStatus(
          label: _dirty ? 'Unsaved changes' : 'Saved',
          role: _dirty ? FeedbackColorRole.warning : FeedbackColorRole.success,
        ),
        primaryActions: [
          CarpenterActionDescriptor(
            id: 'settings.save',
            label: 'Save changes',
            icon: GravityIcons.floppyDisk,
            onInvoke: _dirty ? _save : null,
          ),
        ],
      ),
      if (_dirty)
        const CarpenterNotice(
          title: 'Unsaved changes',
          message:
              'Business values are controlled by this page. Picker and dropdown visibility are intentionally transient Carpenter state.',
          tone: CarpenterNoticeTone.warning,
        ),
      CarpenterPageSection(
        id: const CarpenterPageSectionId('profile'),
        title: 'Profile and workspace',
        description: 'Text, mask and free-form content.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterInput(
              controller: _nameController,
              label: 'Display name',
              description: 'Shown in the navigation footer.',
              leadingIcon: GravityIcons.person,
            ),
            SizedBox(height: context.units(1.rem)),
            CarpenterMaskedInput(
              controller: _codeController,
              mask: const CarpenterInputMask('AA-####'),
              label: 'Workspace code',
              description: 'Two letters followed by four digits.',
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
      CarpenterPageSection(
        id: const CarpenterPageSectionId('defaults'),
        title: 'Operational defaults',
        description:
            'Typed fields keep domain values controlled while Carpenter owns picker/dropdown visibility.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: context.units(1.rem),
              runSpacing: context.units(1.rem),
              children: [
                SizedBox(
                  width: context.units(18.rem),
                  child: CarpenterSelect<String>(
                    value: _timezone,
                    onChanged: (value) => _change(() => _timezone = value),
                    label: 'Timezone',
                    options: const [
                      CarpenterOption(
                        id: 'tashkent',
                        value: 'Asia/Tashkent',
                        label: 'Asia/Tashkent',
                      ),
                      CarpenterOption(
                        id: 'moscow',
                        value: 'Europe/Moscow',
                        label: 'Europe/Moscow',
                      ),
                      CarpenterOption(
                        id: 'helsinki',
                        value: 'Europe/Helsinki',
                        label: 'Europe/Helsinki',
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: context.units(18.rem),
                  child: CarpenterNumberInput(
                    value: _defaultBudget,
                    onChanged: (value) => _change(() => _defaultBudget = value),
                    label: 'Default budget',
                    min: 0,
                    allowNegative: false,
                  ),
                ),
                SizedBox(
                  width: context.units(18.rem),
                  child: CarpenterDateInput(
                    value: _reviewDate,
                    onChanged: (value) => _change(() => _reviewDate = value),
                    label: 'Next review',
                  ),
                ),
                SizedBox(
                  width: context.units(18.rem),
                  child: CarpenterTimeInput(
                    value: _syncTime,
                    onChanged: (value) => _change(() => _syncTime = value),
                    label: 'Daily sync time',
                  ),
                ),
                SizedBox(
                  width: context.units(24.rem),
                  child: CarpenterDateRangeInput(
                    value: _reportingWindow,
                    onChanged: (value) =>
                        _change(() => _reportingWindow = value),
                    label: 'Reporting window',
                  ),
                ),
              ],
            ),
            SizedBox(height: context.units(1.rem)),
            CarpenterComboBox<String>(
              controller: _ownerController,
              value: _owner,
              onChanged: (value) => _change(() => _owner = value),
              onQueryChanged: (_) => _markDirty(),
              options: _owners,
              label: 'Default owner',
              placeholder: 'Search owner',
            ),
            SizedBox(height: context.units(1.rem)),
            CarpenterAutosuggest<String>(
              controller: _tagController,
              onQueryChanged: (_) => _markDirty(),
              onSuggestionSelected: (_) => _markDirty(),
              suggestions: _tags,
              label: 'Default label',
              placeholder: 'Type or choose a suggestion',
            ),
          ],
        ),
      ),
      CarpenterPageSection(
        id: const CarpenterPageSectionId('files'),
        title: 'Attachments',
        description:
            'The core field stays backend-neutral. A real application connects its platform file picker here.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterFileInput<String>(
              value: _files,
              onChanged: (value) => _change(() => _files = value),
              onBrowseRequested: _fakeBrowse,
              label: 'Approval documents',
              description: 'This example simulates the platform browse adapter.',
              accepts: (file) => file.mimeType == 'application/pdf',
            ),
            if (_files.isNotEmpty) ...[
              SizedBox(height: context.units(.75.rem)),
              CarpenterText.caption(
                '${_files.length} PDF attachment(s) selected',
                colorRole: ContentColorRole.secondary,
              ),
            ],
          ],
        ),
      ),
      CarpenterPageSection(
        id: const CarpenterPageSectionId('preferences'),
        title: 'Preferences',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarpenterSwitch(
              value: _notifications,
              label: 'Enable notifications',
              onChanged: (value) => _change(() => _notifications = value),
            ),
            SizedBox(height: context.units(.75.rem)),
            CarpenterCheckbox(
              value: _includeArchived,
              label: 'Include archived items by default',
              onChanged: (value) => _change(() => _includeArchived = value),
            ),
            SizedBox(height: context.units(1.rem)),
            const CarpenterText.label(
              'Interface density',
              emphasis: TypographyEmphasis.strong,
            ),
            SizedBox(height: context.units(.5.rem)),
            CarpenterRadioGroup<_DensityPreference>(
              value: _density,
              onChanged: (value) => _change(() => _density = value),
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
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: CarpenterButton.filled(
          label: 'Save changes',
          icon: GravityIcons.floppyDisk,
          onPressed: _dirty ? _save : null,
        ),
      ),
    ],
  );
}
