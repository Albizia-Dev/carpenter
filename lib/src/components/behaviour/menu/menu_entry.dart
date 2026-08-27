import '../../../foundation/roles.dart';

/// One action presented by a [CarpenterMenu].
final class CarpenterMenuItem {
  const CarpenterMenuItem({
    required this.action,
    this.id,
    this.selected = false,
  });

  final CarpenterActionDescriptor action;
  final Object? id;
  final bool selected;

  Object get effectiveId => id ?? action.id;
}
