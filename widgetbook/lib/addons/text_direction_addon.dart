import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

class TextDirectionAddon extends WidgetbookAddon<TextDirection> {
  TextDirectionAddon() : super(name: 'Text direction');

  @override
  List<Field> get fields => [
    ObjectDropdownField<TextDirection>(
      name: 'direction',
      values: TextDirection.values,
      initialValue: TextDirection.ltr,
      labelBuilder: (value) => switch (value) {
        TextDirection.ltr => 'Left to right',
        TextDirection.rtl => 'Right to left',
      },
    ),
  ];

  @override
  TextDirection valueFromQueryGroup(Map<String, String> group) =>
      valueOf<TextDirection>('direction', group)!;

  @override
  Widget buildUseCase(
    BuildContext context,
    Widget child,
    TextDirection setting,
  ) => Directionality(textDirection: setting, child: child);
}
