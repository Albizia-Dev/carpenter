import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the checked-in dsktp font without network or system-font dependencies.
Future<void> loadGoldenFonts(String directory) async {
  final font = FontLoader('Onest');
  for (final weight in ['Regular', 'SemiBold']) {
    font.addFont(
      Future.value(
        ByteData.sublistView(
          File('$directory/Onest-$weight.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await font.load();
}
