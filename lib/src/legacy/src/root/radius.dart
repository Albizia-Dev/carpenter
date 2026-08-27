import 'package:carpenter/src/legacy/src/root/dimension.dart';

/// Старое имя радиусной шкалы.
///
/// Новый runtime использует dynamic dimension registry:
/// `face.radius('control')`, `face.radius('pill')`, `face.dimension(...)`.
@Deprecated('Используйте CarpenterDimension и face.radius(String).')
typedef CarpenterRadius = CarpenterDimension;
