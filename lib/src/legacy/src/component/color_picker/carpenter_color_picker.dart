import 'package:carpenter/src/legacy/src/component/input/carpenter_input.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Непрозрачный RGB color picker с визуальной HSV-палитрой и HEX/RGB вводом.
class CarpenterColorPicker extends StatefulWidget {
  const CarpenterColorPicker({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.paletteHeight = 160,
    super.key,
  });

  final Color value;
  final ValueChanged<Color> onChanged;
  final bool enabled;
  final double paletteHeight;

  @override
  State<CarpenterColorPicker> createState() => _CarpenterColorPickerState();
}

class _CarpenterColorPickerState extends State<CarpenterColorPicker> {
  late HSVColor _hsv;
  late final TextEditingController _hex;
  late final TextEditingController _red;
  late final TextEditingController _green;
  late final TextEditingController _blue;
  String? _hexError;
  String? _rgbError;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.value);
    _hex = TextEditingController();
    _red = TextEditingController();
    _green = TextEditingController();
    _blue = TextEditingController();
    _syncInputs(widget.value);
  }

  @override
  void didUpdateWidget(covariant CarpenterColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _hsv.toColor()) {
      _hsv = HSVColor.fromColor(widget.value);
      _syncInputs(widget.value);
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

  void _setSaturationValue(Offset position, Size size) {
    if (!widget.enabled) return;
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - position.dy / size.height).clamp(0.0, 1.0);
    _emit(_hsv.withSaturation(saturation).withValue(value).toColor());
  }

  void _setHue(double x, double width) {
    if (!widget.enabled) return;
    _emit(_hsv.withHue((x / width).clamp(0.0, 1.0) * 360).toColor());
  }

  void _onHexChanged(String source) {
    final color = carpenterParseRgbColor(source);
    setState(
      () => _hexError = color == null ? 'Введите #RGB или #RRGGBB' : null,
    );
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
    setState(() => _rgbError = valid ? null : 'RGB: от 0 до 255');
    if (valid) {
      _emit(Color.fromARGB(255, red, green, blue), syncRgb: false);
    }
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

  void _syncInputs(Color color) {
    _hex.text = carpenterFormatRgbHex(color);
    _syncRgb(color);
  }

  void _syncRgb(Color color) {
    final rgb = color.toARGB32();
    _red.text = '${(rgb >> 16) & 0xFF}';
    _green.text = '${(rgb >> 8) & 0xFF}';
    _blue.text = '${rgb & 0xFF}';
  }

  Widget _inputControls(BuildContext context) {
    final face = context.face;
    final preview = DecoratedBox(
      decoration: BoxDecoration(
        color: _hsv.toColor(),
        border: Border.all(color: face.color('border.normal')),
        borderRadius: BorderRadius.circular(face.radius('md')),
      ),
      child: const SizedBox.square(dimension: 44),
    );
    final hex = CarpenterInput(
      controller: _hex,
      label: 'HEX',
      enabled: widget.enabled,
      errorText: _hexError,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
        LengthLimitingTextInputFormatter(7),
      ],
      onChanged: _onHexChanged,
    );
    final rgb = <Widget>[
      for (final field in [
        (label: 'R', controller: _red),
        (label: 'G', controller: _green),
        (label: 'B', controller: _blue),
      ]) ...[
        Expanded(
          child: CarpenterInput(
            controller: field.controller,
            label: field.label,
            enabled: widget.enabled,
            errorText: field.label == 'B' ? _rgbError : null,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: _onRgbChanged,
          ),
        ),
        if (field.label != 'B') SizedBox(width: face.space('0.375')),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  preview,
                  SizedBox(width: face.space('0.5')),
                  Expanded(child: hex),
                ],
              ),
              SizedBox(height: face.space('0.5')),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: rgb),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            preview,
            SizedBox(width: face.space('0.5')),
            Expanded(flex: 2, child: hex),
            SizedBox(width: face.space('0.5')),
            ...rgb,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Выбор цвета',
    enabled: widget.enabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: widget.enabled ? 1 : .5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, widget.paletteHeight);
              return Semantics(
                label: 'Насыщенность и яркость',
                slider: true,
                enabled: widget.enabled,
                value:
                    '${(_hsv.saturation * 100).round()}%, '
                    '${(_hsv.value * 100).round()}%',
                increasedValue:
                    '${(_hsv.saturation * 100).round()}%, '
                    '${((_hsv.value + .05).clamp(0.0, 1.0) * 100).round()}%',
                decreasedValue:
                    '${(_hsv.saturation * 100).round()}%, '
                    '${((_hsv.value - .05).clamp(0.0, 1.0) * 100).round()}%',
                onIncrease: widget.enabled
                    ? () => _emit(
                        _hsv
                            .withValue((_hsv.value + .05).clamp(0.0, 1.0))
                            .toColor(),
                      )
                    : null,
                onDecrease: widget.enabled
                    ? () => _emit(
                        _hsv
                            .withValue((_hsv.value - .05).clamp(0.0, 1.0))
                            .toColor(),
                      )
                    : null,
                child: MouseRegion(
                  cursor: widget.enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: widget.enabled
                        ? (details) =>
                              _setSaturationValue(details.localPosition, size)
                        : null,
                    onPanUpdate: widget.enabled
                        ? (details) =>
                              _setSaturationValue(details.localPosition, size)
                        : null,
                    child: CustomPaint(
                      size: size,
                      painter: _SaturationValuePainter(_hsv),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: context.face.space('0.625')),
        Opacity(
          opacity: widget.enabled ? 1 : .5,
          child: LayoutBuilder(
            builder: (context, constraints) => Semantics(
              label: 'Оттенок',
              slider: true,
              enabled: widget.enabled,
              value: '${_hsv.hue.round()}°',
              increasedValue: '${((_hsv.hue + 5) % 360).round()}°',
              decreasedValue: '${((_hsv.hue - 5 + 360) % 360).round()}°',
              onIncrease: widget.enabled
                  ? () => _emit(_hsv.withHue((_hsv.hue + 5) % 360).toColor())
                  : null,
              onDecrease: widget.enabled
                  ? () => _emit(
                      _hsv.withHue((_hsv.hue - 5 + 360) % 360).toColor(),
                    )
                  : null,
              child: MouseRegion(
                cursor: widget.enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: widget.enabled
                      ? (details) => _setHue(
                          details.localPosition.dx,
                          constraints.maxWidth,
                        )
                      : null,
                  onPanUpdate: widget.enabled
                      ? (details) => _setHue(
                          details.localPosition.dx,
                          constraints.maxWidth,
                        )
                      : null,
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 24),
                    painter: _HuePainter(_hsv.hue),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: context.face.space('0.75')),
        _inputControls(context),
      ],
    ),
  );
}

/// Разбирает `#RGB`, `RGB`, `#RRGGBB` или `RRGGBB` в непрозрачный цвет.
Color? carpenterParseRgbColor(String source) {
  var value = source.trim().replaceFirst('#', '');
  if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(value)) {
    value = value.split('').map((character) => '$character$character').join();
  }
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
  return Color(0xFF000000 | int.parse(value, radix: 16));
}

String carpenterFormatRgbHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter(this.color);

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final radius = const Radius.circular(6);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, radius));
    canvas.drawRect(
      rect,
      Paint()..color = HSVColor.fromAHSV(1, color.hue, 1, 1).toColor(),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0xFF000000)],
        ).createShader(rect),
    );
    canvas.restore();
    final point = Offset(
      color.saturation * size.width,
      (1 - color.value) * size.height,
    );
    canvas.drawCircle(point, 7, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(
      point,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF111827),
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HuePainter extends CustomPainter {
  const _HuePainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF00FFFF),
            Color(0xFF0000FF),
            Color(0xFFFF00FF),
            Color(0xFFFF0000),
          ],
        ).createShader(rect),
    );
    final x = hue / 360 * size.width;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, size.height / 2), width: 3, height: 30),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}
