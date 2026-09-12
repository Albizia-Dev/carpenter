import 'package:flutter/widgets.dart';
import 'package:carpenter_units/carpenter_units.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/text.dart';
import '../../../basic/button/button.dart';

/// Whole-version choice, including a deliberately deleted draft.
enum CarpenterDraftChoice {
  /// Keep the unsaved version on this device.
  local,

  /// Keep the version already stored by another session.
  stored,
}

/// Display-only alternatives. Null means deletion; empty text is an empty draft.
class CarpenterDraftConflict {
  /// Labels must be authorized by the host; IDs are never rendered as titles.
  const CarpenterDraftConflict({
    required this.id,
    required this.title,
    required this.base,
    required this.local,
    required this.stored,
  });

  /// Stable opaque selection key.
  final String id;

  /// Human-readable conversation title.
  final String title;

  /// Shared baseline, with host-formatted reply and answer metadata.
  final String? base;

  /// Unsaved whole draft, or null for deletion.
  final String? local;

  /// Persisted whole draft, or null for deletion.
  final String? stored;
}

/// Experimental controlled recovery page in the messenger pattern layer.
/// The host owns choices, proposal freshness and persistence. This widget never
/// defaults a conflict choice or combines versions. Tab/Enter/Space use standard
/// Carpenter buttons; cancel is explicit. Content scrolls at narrow widths and
/// large text scales. No storage or application-domain types cross this API.
class CarpenterMessengerRecovery extends StatelessWidget {
  /// Use inside a bounded workspace. Null [onApply] disables persistence.
  const CarpenterMessengerRecovery({
    super.key,
    required this.conflicts,
    required this.choices,
    required this.onChoiceChanged,
    required this.onApply,
    required this.onCancel,
  });

  /// Authorized alternatives for this proposal, in display order.
  final List<CarpenterDraftConflict> conflicts;

  /// Host-owned selections; stale/unknown keys do not enable apply.
  final Map<String, CarpenterDraftChoice> choices;

  /// Requests selection of a whole version by stable conflict ID.
  final void Function(String, CarpenterDraftChoice) onChoiceChanged;

  /// Persists only after every conflict has an explicit choice.
  final VoidCallback? onApply;

  /// Leaves recovery without changing drafts.
  final VoidCallback onCancel;

  /// Builds a scrollable review with readable selected-state labels.
  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.medium);
    final complete = conflicts.every((item) => choices.containsKey(item.id));
    String version(String? value) => value == null
        ? 'Черновик удалён'
        : value.isEmpty
        ? 'Пустой черновик'
        : value;
    return ColoredBox(
      color: CarpenterTheme.of(context).surface.base,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CarpenterText.title('Восстановление черновиков'),
              SizedBox(height: gap),
              const CarpenterText(
                'Выберите версию для каждого конфликта. Сообщения не будут отправлены.',
              ),
              if (conflicts.isEmpty) ...[
                SizedBox(height: gap),
                const CarpenterText(
                  'Конфликтов нет. Независимые изменения будут сохранены вместе.',
                ),
              ],
              for (final item in conflicts)
                Padding(
                  key: ValueKey(item.id),
                  padding: EdgeInsets.symmetric(vertical: gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CarpenterText.title(item.title),
                      SizedBox(height: gap),
                      const CarpenterText('До изменений'),
                      CarpenterText(version(item.base)),
                      SizedBox(height: gap),
                      const CarpenterText('На этом устройстве'),
                      CarpenterText(version(item.local)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CarpenterButton.text(
                          label: choices[item.id] == CarpenterDraftChoice.local
                              ? 'Выбрано: на устройстве'
                              : 'Оставить с устройства',
                          semanticLabel: 'Оставить с устройства: ${item.title}',
                          toggled:
                              choices[item.id] == CarpenterDraftChoice.local,
                          onPressed: () => onChoiceChanged(
                            item.id,
                            CarpenterDraftChoice.local,
                          ),
                        ),
                      ),
                      SizedBox(height: gap),
                      const CarpenterText('Из другой сессии'),
                      CarpenterText(version(item.stored)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CarpenterButton.text(
                          label: choices[item.id] == CarpenterDraftChoice.stored
                              ? 'Выбрано: другая сессия'
                              : 'Оставить из другой сессии',
                          semanticLabel:
                              'Оставить из другой сессии: ${item.title}',
                          toggled:
                              choices[item.id] == CarpenterDraftChoice.stored,
                          onPressed: () => onChoiceChanged(
                            item.id,
                            CarpenterDraftChoice.stored,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: gap),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  CarpenterButton.filled(
                    label: 'Сохранить выбранное',
                    onPressed: complete ? onApply : null,
                  ),
                  CarpenterButton.text(label: 'Отмена', onPressed: onCancel),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
