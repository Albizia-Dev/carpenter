enum CarpenterRegionRole { navigation, primary, secondary, detail, tools }

/// Declares whether the semantic region or its child owns vertical scrolling.
///
/// With [child], Carpenter only constrains the region and the supplied child
/// must provide its own viewport. With [region], Carpenter creates the single
/// scroll viewport and the child must be non-scrollable content.
enum CarpenterRegionScrollOwnership { child, region }
