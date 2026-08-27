import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

Widget carpenterHarness(
  Widget child, {
  CarpenterThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  bool disableAnimations = false,
}) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: theme ?? CarpenterThemeData.light(),
    child: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Directionality(
        textDirection: direction,
        child: FocusScope(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 420, child: child),
          ),
        ),
      ),
    ),
  ),
);

Widget carpenterOverlayHarness(
  Widget child, {
  CarpenterThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  bool disableAnimations = false,
}) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: theme ?? CarpenterThemeData.light(),
    child: MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: Directionality(
        textDirection: direction,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => FocusScope(
                child: Align(alignment: Alignment.topLeft, child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
