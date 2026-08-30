import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

final fileInputComponent = WidgetbookComponent(
  name: 'File input',
  useCases: [
    WidgetbookUseCase(name: 'Input + linked drop zone', builder: _linked),
    WidgetbookUseCase(name: 'Attachments', builder: _attachments),
  ],
);

Widget _linked(BuildContext context) => const _FileInputPreview();

final class _FileInputPreview extends StatefulWidget {
  const _FileInputPreview();

  @override
  State<_FileInputPreview> createState() => _FileInputPreviewState();
}

final class _FileInputPreviewState extends State<_FileInputPreview> {
  final CarpenterFileIntakeController<String> _intake =
      CarpenterFileIntakeController<String>();
  List<CarpenterFileCandidate<String>> _files = const [];

  static const _invoice = CarpenterFileCandidate<String>(
    id: 'invoice.pdf',
    value: 'invoice.pdf',
    name: 'invoice.pdf',
    sizeBytes: 482304,
    mimeType: 'application/pdf',
  );
  static const _photo = CarpenterFileCandidate<String>(
    id: 'photo.jpg',
    value: 'photo.jpg',
    name: 'site-photo.jpg',
    sizeBytes: 1920048,
    mimeType: 'image/jpeg',
  );

  @override
  void dispose() {
    _intake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterDragScope(
    child: SizedBox(
      width: context.units(34.rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterFileInput<String>(
            value: _files,
            intakeController: _intake,
            label: 'Documents',
            description: 'The input itself accepts drops.',
            onChanged: (files) => setState(() => _files = files),
            onBrowseRequested: () => _intake.accept(const [_invoice]),
          ),
          SizedBox(height: context.units(1.rem)),
          CarpenterFileDropZone<String>(
            intakeController: _intake,
            title: 'Linked drop zone',
            description: 'Drops are forwarded to the input above',
          ),
          SizedBox(height: context.units(1.rem)),
          CarpenterDraggable<CarpenterFileDropData<String>>(
            operation: CarpenterDragOperation.copy,
            payload: carpenterFileDragPayload<String>(
              id: 'demo-files',
              files: const [_invoice, _photo],
              allowedOperations: const {CarpenterDragOperation.copy},
            ),
            child: const CarpenterCard(
              child: CarpenterText.caption(
                'Drag this sample file bundle onto the input or drop zone',
              ),
            ),
          ),
          if (_files.isNotEmpty) ...[
            SizedBox(height: context.units(1.rem)),
            CarpenterText.caption(
              'Controlled value: ${_files.map((file) => file.name).join(', ')}',
              colorRole: ContentColorRole.secondary,
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _attachments(BuildContext context) => SizedBox(
  width: context.units(34.rem),
  child: CarpenterAttachmentList<String>(
    items: const [
      CarpenterAttachment<String>(
        id: 'contract',
        value: 'contract.pdf',
        name: 'contract.pdf',
        sizeBytes: 582103,
        mimeType: 'application/pdf',
        phase: CarpenterAttachmentPhase.complete,
      ),
      CarpenterAttachment<String>(
        id: 'scan',
        value: 'scan.zip',
        name: 'scans.zip',
        sizeBytes: 4824012,
        mimeType: 'application/zip',
        phase: CarpenterAttachmentPhase.uploading,
        progress: .62,
      ),
      CarpenterAttachment<String>(
        id: 'failed',
        value: 'broken.csv',
        name: 'broken.csv',
        phase: CarpenterAttachmentPhase.failed,
        errorText: 'Network error',
      ),
    ],
    onOpen: (_) {},
    onRemove: (_) {},
    onRetry: (_) {},
  ),
);
