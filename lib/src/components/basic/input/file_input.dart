import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../behaviour/drag_and_drop/drag_operation.dart';
import '../../behaviour/drag_and_drop/drag_payload.dart';
import '../../behaviour/drag_and_drop/drop_target.dart';
import '../button/icon_button.dart';
import '../card.dart';
import '../icon.dart';
import '../icons.dart';
import '../progress.dart';
import '../text.dart';
import 'input.dart';

@immutable
final class CarpenterFileCandidate<T> {
  const CarpenterFileCandidate({
    required this.id,
    required this.value,
    required this.name,
    this.sizeBytes,
    this.mimeType,
    this.semanticLabel,
  });

  final Object id;
  final T value;
  final String name;
  final int? sizeBytes;
  final String? mimeType;
  final String? semanticLabel;

  String get effectiveSemanticLabel => semanticLabel ?? name;
}

@immutable
final class CarpenterFileDropData<T> {
  CarpenterFileDropData(Iterable<CarpenterFileCandidate<T>> files)
    : files = List.unmodifiable(files);

  final List<CarpenterFileCandidate<T>> files;
}

typedef CarpenterFileAcceptance<T> = bool Function(CarpenterFileCandidate<T> file);
typedef CarpenterFilesChanged<T> =
    void Function(List<CarpenterFileCandidate<T>> files);

/// Event bridge used by platform adapters and linked drop zones.
///
/// The controller intentionally does not own selected files. Selection remains
/// controlled by [CarpenterFileInput.value].
final class CarpenterFileIntakeController<T> extends ChangeNotifier {
  int _revision = 0;
  List<CarpenterFileCandidate<T>> _files = const [];

  int get revision => _revision;
  List<CarpenterFileCandidate<T>> get files => _files;

  void accept(Iterable<CarpenterFileCandidate<T>> files) {
    _files = List.unmodifiable(files);
    _revision += 1;
    notifyListeners();
  }
}

/// Input-shaped file selector that is also a typed Carpenter drop target.
final class CarpenterFileInput<T> extends StatefulWidget {
  const CarpenterFileInput({
    super.key,
    required this.value,
    this.onChanged,
    this.onBrowseRequested,
    this.intakeController,
    this.accepts,
    this.multiple = true,
    this.label,
    this.placeholder = 'Choose or drop files',
    this.description,
    this.errorText,
    this.semanticLabel,
    this.required = false,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
  });

  final List<CarpenterFileCandidate<T>> value;
  final CarpenterFilesChanged<T>? onChanged;
  final VoidCallback? onBrowseRequested;
  final CarpenterFileIntakeController<T>? intakeController;
  final CarpenterFileAcceptance<T>? accepts;
  final bool multiple;
  final String? label;
  final String placeholder;
  final String? description;
  final String? errorText;
  final String? semanticLabel;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;

  @override
  State<CarpenterFileInput<T>> createState() => _CarpenterFileInputState<T>();
}

final class _CarpenterFileInputState<T> extends State<CarpenterFileInput<T>> {
  final TextEditingController _textController = TextEditingController();
  int _seenRevision = -1;

  @override
  void initState() {
    super.initState();
    _syncText();
    _attach(widget.intakeController);
  }

  @override
  void didUpdateWidget(CarpenterFileInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intakeController != widget.intakeController) {
      _detach(oldWidget.intakeController);
      _seenRevision = -1;
      _attach(widget.intakeController);
    }
    if (!listEquals(oldWidget.value, widget.value)) _syncText();
  }

  @override
  void dispose() {
    _detach(widget.intakeController);
    _textController.dispose();
    super.dispose();
  }

  void _attach(CarpenterFileIntakeController<T>? controller) {
    controller?.addListener(_consumeIntake);
  }

  void _detach(CarpenterFileIntakeController<T>? controller) {
    controller?.removeListener(_consumeIntake);
  }

  void _consumeIntake() {
    final controller = widget.intakeController;
    if (controller == null || controller.revision == _seenRevision) return;
    _seenRevision = controller.revision;
    _accept(controller.files);
  }

  bool _acceptsFile(CarpenterFileCandidate<T> file) =>
      widget.accepts?.call(file) ?? true;

  void _accept(Iterable<CarpenterFileCandidate<T>> incoming) {
    final accepted = incoming.where(_acceptsFile).toList(growable: false);
    if (accepted.isEmpty || widget.onChanged == null) return;
    if (!widget.multiple) {
      widget.onChanged!([accepted.first]);
      return;
    }
    final merged = <Object, CarpenterFileCandidate<T>>{
      for (final file in widget.value) file.id: file,
      for (final file in accepted) file.id: file,
    };
    widget.onChanged!(List.unmodifiable(merged.values));
  }

  void _syncText() {
    _textController.text = switch (widget.value.length) {
      0 => '',
      1 => widget.value.first.name,
      _ => '${widget.value.first.name} +${widget.value.length - 1}',
    };
  }

  @override
  Widget build(BuildContext context) => CarpenterDropTarget<CarpenterFileDropData<T>>(
    targetId: widget.key ?? this,
    fixedPosition: CarpenterDropPosition.inside,
    canAccept: (details) =>
        widget.availability == FieldAvailability.enabled &&
        details.payload.data.files.any(_acceptsFile),
    onDrop: (details) => _accept(details.payload.data.files),
    builder: (context, dropState) => Semantics(
      liveRegion: dropState.hovering,
      value: dropState.hovering
          ? dropState.accepts
                ? 'Drop files here'
                : 'Files not accepted'
          : null,
      child: CarpenterInput(
        controller: _textController,
        label: widget.label,
        placeholder: dropState.hovering && dropState.accepts
            ? 'Drop files here'
            : widget.placeholder,
        description: widget.description,
        errorText: widget.errorText,
        semanticLabel: widget.semanticLabel,
        required: widget.required,
        availability: widget.availability == FieldAvailability.disabled
            ? FieldAvailability.disabled
            : FieldAvailability.readOnly,
        size: widget.size,
        shape: widget.shape,
        leadingIcon: CarpenterIcons.file,
        trailingAction: CarpenterActionDescriptor(
          id: 'file.browse',
          label: 'Choose files',
          semanticLabel: 'Choose files',
          icon: CarpenterIcons.openFile,
          onInvoke: widget.availability == FieldAvailability.enabled
              ? widget.onBrowseRequested
              : null,
        ),
      ),
    ),
  );
}

/// Standalone file drop surface. Link it to a [CarpenterFileInput] by giving
/// both widgets the same [CarpenterFileIntakeController].
final class CarpenterFileDropZone<T> extends StatelessWidget {
  const CarpenterFileDropZone({
    super.key,
    this.onAccepted,
    this.intakeController,
    this.accepts,
    this.title = 'Drop files here',
    this.description = 'Drag files onto this area',
    this.semanticLabel = 'File drop zone',
  }) : assert(onAccepted != null || intakeController != null);

  final CarpenterFilesChanged<T>? onAccepted;
  final CarpenterFileIntakeController<T>? intakeController;
  final CarpenterFileAcceptance<T>? accepts;
  final String title;
  final String description;
  final String semanticLabel;

  bool _acceptsFile(CarpenterFileCandidate<T> file) => accepts?.call(file) ?? true;

  void _submit(List<CarpenterFileCandidate<T>> files) {
    final accepted = files.where(_acceptsFile).toList(growable: false);
    if (accepted.isEmpty) return;
    intakeController?.accept(accepted);
    onAccepted?.call(accepted);
  }

  @override
  Widget build(BuildContext context) => CarpenterDropTarget<CarpenterFileDropData<T>>(
    targetId: key ?? this,
    fixedPosition: CarpenterDropPosition.inside,
    canAccept: (details) => details.payload.data.files.any(_acceptsFile),
    onDrop: (details) => _submit(details.payload.data.files),
    builder: (context, state) {
      final theme = CarpenterTheme.of(context);
      final role = !state.hovering
          ? FeedbackColorRole.neutral
          : state.accepts
          ? FeedbackColorRole.success
          : FeedbackColorRole.danger;
      final colors = theme.feedback.resolve(role);
      return CarpenterCard(
        semanticLabel: semanticLabel,
        borderColor: state.hovering ? colors.foreground : null,
        backgroundColor: state.hovering ? colors.background : null,
        child: SizedBox(
          height: context.units(7.rem),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CarpenterIcon(
                CarpenterIcons.upload,
                colorRole: state.hovering && state.accepts
                    ? ContentColorRole.primary
                    : ContentColorRole.secondary,
              ),
              SizedBox(height: context.units(.5.rem)),
              CarpenterText.label(
                title,
                emphasis: TypographyEmphasis.strong,
                textAlign: TextAlign.center,
              ),
              CarpenterText.caption(
                state.hovering
                    ? state.accepts
                          ? 'Release to add files'
                          : 'These files are not accepted'
                    : description,
                colorRole: ContentColorRole.secondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    },
  );
}

enum CarpenterAttachmentPhase { idle, uploading, complete, failed }

@immutable
final class CarpenterAttachment<T> {
  const CarpenterAttachment({
    required this.id,
    required this.value,
    required this.name,
    this.sizeBytes,
    this.mimeType,
    this.phase = CarpenterAttachmentPhase.idle,
    this.progress,
    this.errorText,
    this.semanticLabel,
  }) : assert(progress == null || (progress >= 0 && progress <= 1));

  final Object id;
  final T value;
  final String name;
  final int? sizeBytes;
  final String? mimeType;
  final CarpenterAttachmentPhase phase;
  final double? progress;
  final String? errorText;
  final String? semanticLabel;
}

final class CarpenterUploadProgress extends StatelessWidget {
  const CarpenterUploadProgress({
    super.key,
    required this.value,
    this.semanticLabel = 'Upload progress',
  });

  final double value;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => CarpenterProgress(
    value: value,
    semanticLabel: semanticLabel,
  );
}

final class CarpenterAttachmentList<T> extends StatelessWidget {
  const CarpenterAttachmentList({
    super.key,
    required this.items,
    this.onOpen,
    this.onRemove,
    this.onRetry,
    this.semanticLabel = 'Attachments',
  });

  final List<CarpenterAttachment<T>> items;
  final ValueChanged<CarpenterAttachment<T>>? onOpen;
  final ValueChanged<CarpenterAttachment<T>>? onRemove;
  final ValueChanged<CarpenterAttachment<T>>? onRetry;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) SizedBox(height: gap),
            _AttachmentRow<T>(
              item: items[index],
              onOpen: onOpen,
              onRemove: onRemove,
              onRetry: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

final class _AttachmentRow<T> extends StatelessWidget {
  const _AttachmentRow({
    required this.item,
    this.onOpen,
    this.onRemove,
    this.onRetry,
  });

  final CarpenterAttachment<T> item;
  final ValueChanged<CarpenterAttachment<T>>? onOpen;
  final ValueChanged<CarpenterAttachment<T>>? onRemove;
  final ValueChanged<CarpenterAttachment<T>>? onRetry;

  String? get _meta {
    final parts = <String>[];
    if (item.sizeBytes != null) parts.add(_formatBytes(item.sizeBytes!));
    if (item.mimeType != null) parts.add(item.mimeType!);
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return CarpenterCard(
      padded: false,
      semanticLabel: item.semanticLabel ?? item.name,
      child: Padding(
        padding: EdgeInsets.all(context.units(theme.spacing.medium)),
        child: Column(
          children: [
            Row(
              children: [
                const CarpenterIcon(
                  CarpenterIcons.file,
                  colorRole: ContentColorRole.secondary,
                ),
                SizedBox(width: gap),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpen == null ? null : () => onOpen!(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarpenterText.label(
                          item.name,
                          emphasis: TypographyEmphasis.medium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_meta != null)
                          CarpenterText.caption(
                            _meta!,
                            colorRole: ContentColorRole.secondary,
                          ),
                        if (item.phase == CarpenterAttachmentPhase.failed)
                          CarpenterText.caption(
                            item.errorText ?? 'Upload failed',
                            colorRole: ContentColorRole.primary,
                          ),
                      ],
                    ),
                  ),
                ),
                if (item.phase == CarpenterAttachmentPhase.failed &&
                    onRetry != null)
                  CarpenterIconButton(
                    icon: CarpenterIcons.refresh,
                    semanticLabel: 'Retry ${item.name}',
                    prominence: ActionProminence.ghost,
                    size: ControlSize.xsmall,
                    onPressed: () => onRetry!(item),
                  ),
                if (onRemove != null)
                  CarpenterIconButton(
                    icon: CarpenterIcons.clear,
                    semanticLabel: 'Remove ${item.name}',
                    colorRole: ActionColorRole.danger,
                    prominence: ActionProminence.ghost,
                    size: ControlSize.xsmall,
                    onPressed: () => onRemove!(item),
                  ),
              ],
            ),
            if (item.phase == CarpenterAttachmentPhase.uploading) ...[
              SizedBox(height: gap),
              CarpenterUploadProgress(
                value: item.progress ?? 0,
                semanticLabel: 'Upload ${item.name}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
}

CarpenterDragPayload<CarpenterFileDropData<T>> carpenterFileDragPayload<T>({
  required Iterable<CarpenterFileCandidate<T>> files,
  Object? id,
  Set<CarpenterDragOperation> allowedOperations = const {
    CarpenterDragOperation.copy,
    CarpenterDragOperation.move,
  },
}) => CarpenterDragPayload<CarpenterFileDropData<T>>(
  id: id,
  data: CarpenterFileDropData<T>(files),
  allowedOperations: allowedOperations,
);
