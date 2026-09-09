/// Legacy Carpenter APIs bundled for incremental application migration.
///
/// Replaces `package:carpenter_older/carpenter.dart` without changing the legacy
/// contracts. This library is intentionally separate from `carpenter.dart`:
/// matching names in the two APIs refer to independent types and theme scopes.
/// Use import prefixes when consuming both APIs in the same Dart library.
///
/// The legacy implementation remains part of Carpenter for gradual integration;
/// this entrypoint does not deprecate or remove its APIs.
library;

export 'src/carpenter_older/carpenter.dart';
