import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/status_indicator.dart';
import '../../collections/contracts/collection_load_phase.dart';
import '../../collections/contracts/collection_snapshot.dart';
import '../../collections/contracts/selection_state.dart';
import '../page_header.dart';
import '../regions/primary_region.dart';
import '../regions/region_role.dart';
import '../toolbar.dart';
import 'header_actions.dart';
import 'states/empty_state.dart';

typedef CarpenterCollectionRenderer<T> = Widget Function(
  BuildContext context,
  CollectionSnapshot<T> snapshot,
);

@immutable
final class CarpenterCollectionPageMessages {
  const CarpenterCollectionPageMessages({
    this.loading = 'Loading collection',
    this.zero = 'No records yet',
    this.emptyResult = 'No matching records',
    this.initialError = 'Collection could not be loaded',
    this.refreshing = 'Refreshing collection',
    this.refreshError = 'Refresh failed. Existing records are preserved.',
  });

  final String loading;
  final String zero;
  final String emptyResult;
  final String initialError;
  final String refreshing;
  final String refreshError;
}

final class CarpenterCollectionPage<T, K> extends StatelessWidget {
  const CarpenterCollectionPage({
    super.key,
    required this.title,
    required this.snapshot,
    required this.selection,
    required this.collectionBuilder,
    this.subtitle,
    this.status,
    this.breadcrumbs,
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.destructiveActions = const [],
    this.filterBar,
    this.summary,
    this.selectionActions = const [],
    this.retryAction,
    this.scrollOwnership = CarpenterRegionScrollOwnership.child,
    this.scrollController,
    this.messages = const CarpenterCollectionPageMessages(),
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final CarpenterPageStatus? status;
  final Widget? breadcrumbs;
  final CollectionSnapshot<T> snapshot;
  final CollectionSelection<K> selection;
  final CarpenterCollectionRenderer<T> collectionBuilder;
  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;
  final List<CarpenterActionDescriptor> destructiveActions;
  final Widget? filterBar;
  final Widget? summary;
  final List<CarpenterActionDescriptor> selectionActions;
  final CarpenterActionDescriptor? retryAction;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final ScrollController? scrollController;
  final CarpenterCollectionPageMessages messages;
  final String? semanticLabel;

  List<CarpenterActionDescriptor> get _pageActions => [
    ...primaryActions,
    ...secondaryActions,
    ...destructiveActions,
    ...selectionActions,
  ];

  @override
  Widget build(BuildContext context) {
    final hasHeaderActions =
        primaryActions.isNotEmpty ||
        secondaryActions.isNotEmpty ||
        destructiveActions.isNotEmpty;
    return CarpenterPageRegion(
      semanticLabel: semanticLabel ?? title,
      scrollOwnership: scrollOwnership,
      scrollController: scrollController,
      shortcutActions: _pageActions,
      header: CarpenterPageHeader(
        title: title,
        subtitle: subtitle,
        status: status,
        breadcrumbs: breadcrumbs,
        actions: hasHeaderActions
            ? CarpenterHeaderActions(
                primary: primaryActions,
                secondary: secondaryActions,
                destructive: destructiveActions,
              )
            : null,
      ),
      toolbar: filterBar,
      body: _CollectionPageBody<T, K>(
        snapshot: snapshot,
        selection: selection,
        collectionBuilder: collectionBuilder,
        summary: summary,
        selectionActions: selectionActions,
        retryAction: retryAction,
        messages: messages,
        fillAvailable: scrollOwnership == CarpenterRegionScrollOwnership.child,
      ),
    );
  }
}

final class _CollectionPageBody<T, K> extends StatelessWidget {
  const _CollectionPageBody({
    required this.snapshot,
    required this.selection,
    required this.collectionBuilder,
    required this.summary,
    required this.selectionActions,
    required this.retryAction,
    required this.messages,
    required this.fillAvailable,
  });

  final CollectionSnapshot<T> snapshot;
  final CollectionSelection<K> selection;
  final CarpenterCollectionRenderer<T> collectionBuilder;
  final Widget? summary;
  final List<CarpenterActionDescriptor> selectionActions;
  final CarpenterActionDescriptor? retryAction;
  final CarpenterCollectionPageMessages messages;
  final bool fillAvailable;

  @override
  Widget build(BuildContext context) {
    final exclusive = _exclusiveState();
    if (exclusive != null) return exclusive;
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutSection);
    final collection = collectionBuilder(context, snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fillAvailable ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (snapshot.refreshFailure != null) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CarpenterStatusIndicator(
              label: snapshot.refreshFailure!.message ?? messages.refreshError,
              role: FeedbackColorRole.danger,
            ),
          ),
          SizedBox(height: gap),
        ] else if (snapshot.isRefreshing) ...[
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CarpenterStatusIndicator(
              label: messages.refreshing,
              role: FeedbackColorRole.info,
            ),
          ),
          SizedBox(height: gap),
        ],
        if (summary != null) ...[summary!, SizedBox(height: gap)],
        if (!selection.isEmpty && selectionActions.isNotEmpty) ...[
          CarpenterToolbar(
            items: [
              for (final action in selectionActions)
                CarpenterToolbarItem(
                  action: action,
                  priority: CarpenterToolbarPriority.critical,
                ),
            ],
            semanticLabel: 'Selection actions',
          ),
          SizedBox(height: gap),
        ],
        if (fillAvailable) Expanded(child: collection) else collection,
      ],
    );
  }

  Widget? _exclusiveState() {
    if (snapshot.isInitialLoading) {
      return CarpenterPageStatePresentation.loading(title: messages.loading);
    }
    if (snapshot.initialFailure != null) {
      return CarpenterPageStatePresentation(
        kind: CarpenterPageStateKind.initialError,
        title: messages.initialError,
        description: snapshot.initialFailure!.message,
        action: retryAction,
      );
    }
    if (snapshot.contentState == CollectionContentState.zero) {
      return CarpenterPageStatePresentation(
        kind: CarpenterPageStateKind.zero,
        title: messages.zero,
      );
    }
    if (snapshot.contentState == CollectionContentState.emptyResult) {
      return CarpenterPageStatePresentation(
        kind: CarpenterPageStateKind.emptyResult,
        title: messages.emptyResult,
      );
    }
    return null;
  }
}
