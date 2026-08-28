extension type const CarpenterPageId(String value) {
  String get restorationNamespace => value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}

enum CarpenterPageKind {
  collection,
  record,
  editor,
  workflow,
  explorer,
  custom,
}

enum CarpenterRestorationLifetime { session, local, url, userPreference }

final class CarpenterRestorationPolicy {
  const CarpenterRestorationPolicy({
    this.lifetime = CarpenterRestorationLifetime.session,
  });
  final CarpenterRestorationLifetime lifetime;
}

final class CarpenterPermissionRequirement {
  const CarpenterPermissionRequirement({required this.granted, this.reason});
  const CarpenterPermissionRequirement.granted()
    : granted = true,
      reason = null;
  final bool granted;
  final String? reason;
}

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
