import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final breadcrumbsComponent = WidgetbookComponent(
  name: 'Breadcrumbs',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _breadcrumbs),
    WidgetbookUseCase(name: 'Long path', builder: _breadcrumbsLong),
  ],
);

final notificationListComponent = WidgetbookComponent(
  name: 'Notification List',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _notifications),
    WidgetbookUseCase(name: 'Empty', builder: _notificationsEmpty),
  ],
);

Widget _breadcrumbs(BuildContext context) {
  final maxVisible = context.knobs.double.slider(
    label: 'Behaviour · Visible items',
    initialValue: 4,
    min: 2,
    max: 6,
    divisions: 4,
  ).round();
  final includeDeepPath = context.knobs.boolean(
    label: 'Content · Deep path',
    initialValue: true,
  );

  final items = <CarpenterBreadcrumb>[
    CarpenterBreadcrumb(label: 'Home', onInvoke: () {}),
    CarpenterBreadcrumb(label: 'Treasury', onInvoke: () {}),
    if (includeDeepPath) ...[
      CarpenterBreadcrumb(label: 'Legal entities', onInvoke: () {}),
      CarpenterBreadcrumb(label: 'Albizia Dev LLC', onInvoke: () {}),
      CarpenterBreadcrumb(label: 'Bank accounts', onInvoke: () {}),
    ],
    const CarpenterBreadcrumb(label: 'Main account'),
  ];

  return preview(
    SizedBox(
      width: context.units(42.rem),
      child: CarpenterBreadcrumbs(items: items, maxVisibleItems: maxVisible),
    ),
  );
}

Widget _breadcrumbsLong(BuildContext context) => previewColumn([
  SizedBox(
    width: context.units(22.rem),
    child: CarpenterBreadcrumbs(
      maxVisibleItems: 3,
      items: [
        CarpenterBreadcrumb(label: 'Workspace', onInvoke: () {}),
        CarpenterBreadcrumb(label: 'Projects', onInvoke: () {}),
        CarpenterBreadcrumb(label: '2026', onInvoke: () {}),
        CarpenterBreadcrumb(label: 'ERP migration', onInvoke: () {}),
        CarpenterBreadcrumb(label: 'Documents', onInvoke: () {}),
        const CarpenterBreadcrumb(label: 'Acceptance certificate № 184/26'),
      ],
    ),
  ),
  const CarpenterText.caption('Narrow width forces wrapping; path overflow remains explicit.'),
]);

Widget _notifications(BuildContext context) {
  final includeAction = context.knobs.boolean(
    label: 'Content · Action',
    initialValue: true,
  );
  final includeUnread = context.knobs.boolean(
    label: 'Content · Unread',
    initialValue: true,
  );
  return _NotificationPreview(
    includeAction: includeAction,
    includeUnread: includeUnread,
  );
}

final class _NotificationPreview extends StatefulWidget {
  const _NotificationPreview({
    required this.includeAction,
    required this.includeUnread,
  });

  final bool includeAction;
  final bool includeUnread;

  @override
  State<_NotificationPreview> createState() => _NotificationPreviewState();
}

final class _NotificationPreviewState extends State<_NotificationPreview> {
  late List<CarpenterNotification> _items = _buildItems();

  List<CarpenterNotification> _buildItems() => [
    CarpenterNotification(
      id: 'bank-import',
      title: 'Bank statement imported',
      message: '184 payments were matched; 3 require review.',
      tone: FeedbackColorRole.success,
      unread: widget.includeUnread,
      timestamp: DateTime(2026, 8, 31, 4, 42),
      action: widget.includeAction
          ? CarpenterActionDescriptor(
              id: 'review',
              label: 'Review',
              onInvoke: () {},
            )
          : null,
    ),
    CarpenterNotification(
      id: 'balance-warning',
      title: 'Balance mismatch',
      message: 'Opening balance differs from the imported statement by 12 450.00.',
      tone: FeedbackColorRole.warning,
      unread: widget.includeUnread,
      timestamp: DateTime(2026, 8, 31, 3, 15),
    ),
    CarpenterNotification(
      id: 'sync-info',
      title: 'Directory synchronized',
      message: 'Counterparty data is up to date.',
      tone: FeedbackColorRole.info,
      timestamp: DateTime(2026, 8, 30, 22, 7),
    ),
  ];

  @override
  void didUpdateWidget(_NotificationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.includeAction != widget.includeAction ||
        oldWidget.includeUnread != widget.includeUnread) {
      _items = _buildItems();
    }
  }

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: context.units(42.rem),
      child: CarpenterNotificationList(
        items: _items,
        onDismiss: (id) => setState(
          () => _items = _items.where((item) => item.id != id).toList(),
        ),
      ),
    ),
  );
}

Widget _notificationsEmpty(BuildContext context) => preview(
  SizedBox(
    width: context.units(32.rem),
    height: context.units(10.rem),
    child: const CarpenterNotificationList(items: []),
  ),
);
