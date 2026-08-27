import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../collections/contracts/collection_snapshot.dart';
import '../../collections/contracts/selection_state.dart';
import '../page_header.dart';
import '../regions/region_role.dart';
import 'collection_page.dart';

final class CarpenterListReport<T, K> extends StatelessWidget {
  const CarpenterListReport({
    super.key,
    required this.title,
    required this.snapshot,
    required this.selection,
    required this.collectionBuilder,
    required this.summary,
    this.subtitle,
    this.status,
    this.filterBar,
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.exportAction,
    this.retryAction,
    this.scrollOwnership = CarpenterRegionScrollOwnership.child,
    this.messages = const CarpenterCollectionPageMessages(),
  });

  final String title;
  final String? subtitle;
  final CarpenterPageStatus? status;
  final CollectionSnapshot<T> snapshot;
  final CollectionSelection<K> selection;
  final CarpenterCollectionRenderer<T> collectionBuilder;
  final Widget summary;
  final Widget? filterBar;
  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;
  final CarpenterActionDescriptor? exportAction;
  final CarpenterActionDescriptor? retryAction;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final CarpenterCollectionPageMessages messages;

  @override
  Widget build(BuildContext context) => CarpenterCollectionPage<T, K>(
    title: title,
    subtitle: subtitle,
    status: status,
    snapshot: snapshot,
    selection: selection,
    collectionBuilder: collectionBuilder,
    summary: summary,
    filterBar: filterBar,
    primaryActions: primaryActions,
    secondaryActions: [...secondaryActions, ?exportAction],
    retryAction: retryAction,
    scrollOwnership: scrollOwnership,
    messages: messages,
  );
}
