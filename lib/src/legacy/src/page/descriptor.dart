/// Stable identity of a Carpenter page.
extension type const CarpenterPageId(String value) {
  /// A restoration-safe representation of this id.
  String get restorationNamespace => value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}

/// The user scenario represented by a page.
enum CarpenterPageKind {
  collection,
  record,
  editor,
  workflow,
  explorer,
  custom,
}

/// Persistence lifetime for page view state.
enum CarpenterRestorationLifetime { session, local, url, userPreference }

/// Describes how view state of a page should be restored.
final class CarpenterRestorationPolicy {
  const CarpenterRestorationPolicy({
    this.lifetime = CarpenterRestorationLifetime.session,
  });

  final CarpenterRestorationLifetime lifetime;
}

/// A resolved permission requirement.
///
/// Domain code remains responsible for evaluating permissions. Carpenter only
/// renders and exposes the result consistently.
final class CarpenterPermissionRequirement {
  const CarpenterPermissionRequirement({required this.granted, this.reason});

  const CarpenterPermissionRequirement.granted()
    : granted = true,
      reason = null;

  final bool granted;
  final String? reason;
}

/// Compact, immutable metadata shared by the page infrastructure.
final class CarpenterPageDescriptor {
  const CarpenterPageDescriptor({
    required this.id,
    required this.title,
    required this.kind,
    this.restorationPolicy,
    this.permission,
  });

  final CarpenterPageId id;
  final String title;
  final CarpenterPageKind kind;
  final CarpenterRestorationPolicy? restorationPolicy;
  final CarpenterPermissionRequirement? permission;
}
