import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'input/input.dart';

/// Opaque RGB color picker with HSV surface and HEX/RGB inputs.
final class CarpenterColorPicker extends StatefulWidget {
  const CarpenterColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.paletteHeight = 160,
  });

  final Color value;
  final ValueChanged<Color> onChanged;
  final bool enabled;
  final double paletteHeight;

  @override
  State<CarpenterColorPicker> createState() => _CarpenterColorPickerState();
}

final class _CarpenterColorPickerState extends State<CarpenterColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.value);
  late final TextEditingController _hex = TextEditingController();
  late final TextEditingController _red = TextEditingController();
  late final TextEditingController _green = TextEditingController();
  late final TextEditingController _blue = TextEditingController();
  String? _hexError;
  String? _rgbError;

  @override
  void initState() {
    super.initState();
    _sync(widget.value);
  }

  @override
  void didUpdateWidget(CarpenterColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _hsv.toColor()) {
      _hsv = HSVColor.fromColor(widget.value);
      _sync(widget.value);
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    _red.dispose();
    _green.dispose();
    _blue.dispose();
    super.dispose();
  }

  void _emit(Color color, {bool syncHex = true, bool syncRgb = true}) {
    _hsv = HSVColor.fromColor(color);
    if (syncHex) _hex.text = carpenterFormatRgbHex(color);
    if (syncRgb) _syncRgb(color);
    setState(() {
      _hexError = null;
      _rgbError = null;
    });
    widget.onChanged(color);
  }

  void _sync(Color color) {
    _hex.text = carpenterFormatRgbHex(color);
    _syncRgb(color);
  }

  void _syncRgb(Color color) {
    final rgb = color.toARGB32();
    _red.text = '${(rgb >> 16) & 0xff}';
    _green.text = '${(rgb >> 8) & 0xff}';
    _blue.text = '${rgb & 0xff}';
  }

  void _onHexChanged(String source) {
    final color = carpenterParseRgbColor(source);
    setState(() => _hexError = color == null ? 'Use #RGB or #RRGGBB' : null);
    if (color != null) _emit(color, syncHex: false);
  }

  void _onRgbChanged(String _) {
    final red = int.tryParse(_red.text);
    final green = int.tryParse(_green.text);
    final blue = int.tryParse(_blue.text);
    final valid =
        red != null &&
        green != null &&
        blue != null &&
        red >= 0 &&
        red <= 255 &&
        green >= 0 &&
        green <= 255 &&
        blue >= 0 &&
        blue <= 255;
    setState(() => _rgbError = valid ? null : 'RGB values must be 0–255');
    if (valid) _emit(Color.fromARGB(255, red, green, blue), syncRgb: false);
  }

  void _setSaturationValue(Offset position, Size size) {
    if (!widget.enabled || size.width <= 0 || size.height <= 0) return;
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - position.dy / size.height).clamp(0.0, 1.0);
    _emit(_hsv.withSaturation(saturation).withValue(value).toColor());
  }

  void _setHue(double x, double width) {
    if (!widget.enabled || width <= 0) return;
    _emit(_hsv.withHue((x / width).clamp(0.0, 1.0) * 360).toColor());
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return Semantics(
      label: 'Color picker',
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Opacity(
            opacity: widget.enabled ? 1 : .5,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, widget.paletteHeight);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: widget.enabled
                      ? (event) =>
                            _setSaturationValue(event.localPosition, size)
                      : null,
                  onPanUpdate: widget.enabled
                      ? (event) =>
                            _setSaturationValue(event.localPosition, size)
                      : null,
                  child: CustomPaint(
                    size: size,
                    painter: _SaturationValuePainter(_hsv),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: gap),
          Opacity(
            opacity: widget.enabled ? 1 : .5,
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanDown: widget.enabled
                    ? (event) =>
                          _setHue(event.localPosition.dx, constraints.maxWidth)
                    : null,
                onPanUpdate: widget.enabled
                    ? (event) =>
                          _setHue(event.localPosition.dx, constraints.maxWidth)
                    : null,
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 24),
                  painter: _HuePainter(_hsv.hue),
                ),
              ),
            ),
          ),
          SizedBox(height: gap),
          LayoutBuilder(
            builder: (context, constraints) {
              final hex = CarpenterInput(
                controller: _hex,
                label: 'HEX',
                availability: widget.enabled
                    ? FieldAvailability.enabled
                    : FieldAvailability.disabled,
                errorText: _hexError,
                onChanged: _onHexChanged,
              );
              final rgb = Row(
                children: [
                  for (final entry in [
                    ('R', _red),
                    ('G', _green),
                    ('B', _blue),
                  ]) ...[
                    Expanded(
                      child: CarpenterInput(
                        controller: entry.$2,
                        label: entry.$1,
                        availability: widget.enabled
                            ? FieldAvailability.enabled
                            : FieldAvailability.disabled,
                        errorText: entry.$1 == 'B' ? _rgbError : null,
                        keyboardType: TextInputType.number,
                        onChanged: _onRgbChanged,
                      ),
                    ),
                    if (entry.$1 != 'B') SizedBox(width: gap / 2),
                  ],
                ],
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hex,
                    SizedBox(height: gap),
                    rgb,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 2, child: hex),
                  SizedBox(width: gap),
                  Expanded(flex: 3, child: rgb),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Color? carpenterParseRgbColor(String source) {
  var value = source.trim().replaceFirst('#', '');
  if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(value)) {
    value = value.split('').map((character) => '$character$character').join();
  }
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
  return Color(0xff000000 | int.parse(value, radix: 16));
}

String carpenterFormatRgbHex(Color color) {
  final rgb = color.toARGB32() & 0xffffff;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

final class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter(this.color);
  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    canvas.drawRect(
      rect,
      Paint()..color = HSVColor.fromAHSV(1, color.hue, 1, 1).toColor(),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffffffff), Color(0x00ffffff)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xff000000)],
        ).createShader(rect),
    );
    canvas.restore();
    final point = Offset(
      color.saturation * size.width,
      (1 - color.value) * size.height,
    );
    canvas.drawCircle(point, 7, Paint()..color = const Color(0xffffffff));
    canvas.drawCircle(
      point,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xff111827),
    );
  }

  @override
  bool shouldRepaint(_SaturationValuePainter oldDelegate) =>
      oldDelegate.color != color;
}

final class _HuePainter extends CustomPainter {
  const _HuePainter(this.hue);
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xffff0000),
            Color(0xffffff00),
            Color(0xff00ff00),
            Color(0xff00ffff),
            Color(0xff0000ff),
            Color(0xffff00ff),
            Color(0xffff0000),
          ],
        ).createShader(rect),
    );
    final x = hue / 360 * size.width;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, size.height / 2), width: 3, height: 30),
      Paint()..color = const Color(0xffffffff),
    );
  }

  @override
  bool shouldRepaint(_HuePainter oldDelegate) => oldDelegate.hue != hue;
}
