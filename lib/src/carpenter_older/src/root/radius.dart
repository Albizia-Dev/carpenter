// Bundled in carpenter: legacy package imports relocated; behavior unchanged.
import 'package:carpenter/src/carpenter_older/src/root/dimension.dart';

/// Старое имя радиусной шкалы.
///
/// Новый runtime использует dynamic dimension registry:
/// `face.radius('control')`, `face.radius('pill')`, `face.dimension(...)`.
@Deprecated('Используйте CarpenterDimension и face.radius(String).')
typedef CarpenterRadius = CarpenterDimension;
