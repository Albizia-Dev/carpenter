import 'package:flutter/widgets.dart';

import '../../../../foundation/adaptive.dart';
import '../../../layout/master_detail.dart';
import '../../../layout/regions/region_role.dart';

/// Keeps the selected conversation visible as a wide workspace becomes narrow.
/// The host owns selection and state restoration; both regions stay bounded.
final class CarpenterConversationSplitView extends StatelessWidget {
  const CarpenterConversationSplitView({
    super.key,
    required this.selected,
    required this.master,
    required this.detail,
    required this.emptyDetail,
  });

  final bool selected;
  final Widget master;
  final Widget detail;
  final Widget emptyDetail;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = const CarpenterViewportPolicy(accountForTextScale: true);
      if (viewport.resolve(context, constraints.maxWidth) ==
          CarpenterViewportClass.narrow) {
        return selected ? detail : master;
      }
      return CarpenterMasterDetail(
        viewportPolicy: viewport,
        detailScrollOwnership: CarpenterRegionScrollOwnership.child,
        masterSemanticLabel: 'Разговоры',
        detailSemanticLabel: 'Переписка',
        onDetailVisibilityChanged: null,
        master: master,
        detail: selected ? detail : emptyDetail,
      );
    },
  );
}
