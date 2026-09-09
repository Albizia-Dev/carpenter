// Bundled in carpenter: legacy package imports relocated; behavior unchanged.
import 'package:carpenter/src/carpenter_older/src/root/face.dart';

/// Старое имя фасада визуального языка.
///
/// Новый код должен использовать `CarpenterFace`. Этот typedef оставлен только
/// для мягкого перехода старого кода.
@Deprecated(
  'Используйте CarpenterFace: CarpenterStyle больше не является темой.',
)
typedef CarpenterStyle = CarpenterFace;
