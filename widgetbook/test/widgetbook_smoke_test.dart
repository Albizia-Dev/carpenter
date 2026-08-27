import 'package:carpenter_widgetbook/widgetbook.dart';
import 'package:carpenter_widgetbook/addons/carpenter_addons.dart';
import 'package:carpenter_widgetbook/helpers/layout_viewport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  testWidgets('Widgetbook catalog is constructible', (tester) async {
    await tester.pumpWidget(createCarpenterWidgetbook());
    expect(find.byType(Widgetbook), findsOneWidget);
  });

  test('catalog exposes focused interactive component groups', () {
    final widgetbook = createCarpenterWidgetbook() as Widgetbook;
    final foundation = widgetbook.directories.first as WidgetbookFolder;
    expect(foundation.name, 'Foundation');
    expect(foundation.children!.map((component) => component.name), ['Colors']);
    expect(
      foundation.children!.cast<WidgetbookComponent>().single.useCases.map(
        (useCase) => useCase.name,
      ),
      ['Semantic colors', 'Action matrix', 'Selection roles'],
    );

    final basic = widgetbook.directories[1] as WidgetbookFolder;

    expect(basic.name, 'Basic');
    expect(basic.children!.map((component) => component.name), [
      'Text',
      'Icon',
      'Status Indicator',
      'Button',
      'Icon Button',
      'Card',
      'Link',
      'Input',
      'Text Area',
      'Checkbox',
      'Radio Group',
      'Switch',
      'Select',
      'Combo Box',
      'Autosuggest',
    ]);

    final components = basic.children!.cast<WidgetbookComponent>();
    expect(
      components.every(
        (component) =>
            component.useCases.any((useCase) => useCase.name == 'Playground'),
      ),
      isTrue,
    );
    expect(
      components[3].useCases.map((useCase) => useCase.name),
      containsAll(['Size comparison', 'Color roles']),
    );
    expect(
      components[7].useCases.map((useCase) => useCase.name),
      containsAll(['Size comparison', 'Availability']),
    );
    expect(
      components[8].useCases.map((useCase) => useCase.name),
      contains('Size comparison'),
    );

    final behaviour = widgetbook.directories[2] as WidgetbookFolder;
    expect(behaviour.name, 'Behaviour');
    expect(behaviour.children!.map((component) => component.name), [
      'Popover',
      'Menu',
      'Dropdown',
      'Tooltip',
      'Toast',
      'Dialog',
    ]);
    expect(
      behaviour.children!.cast<WidgetbookComponent>().every(
        (component) =>
            component.useCases.any((useCase) => useCase.name == 'Playground'),
      ),
      isTrue,
    );

    final collections = widgetbook.directories[3] as WidgetbookFolder;
    expect(collections.name, 'Collections');
    expect(collections.children!.map((component) => component.name), [
      'Collection Kernel',
      'Data List',
      'Definition List',
      'Tabs',
      'Table',
    ]);
    expect(
      collections.children!.cast<WidgetbookComponent>().every(
        (component) =>
            component.useCases.any((useCase) => useCase.name == 'Playground'),
      ),
      isTrue,
    );

    final layout = widgetbook.directories[4] as WidgetbookFolder;
    expect(layout.name, 'Layout');
    expect(layout.children!.map((component) => component.name), [
      'Application Shell',
      'Toolbar',
      'Split View',
      'Adaptive Region',
      'Master / Detail',
    ]);
    expect(
      layout.children!.cast<WidgetbookComponent>().every(
        (component) =>
            component.useCases.any((useCase) => useCase.name == 'Playground'),
      ),
      isTrue,
    );
    expect(
      layout.children!.cast<WidgetbookComponent>().first.useCases.map(
        (useCase) => useCase.name,
      ),
      ['Playground', 'Invoice workspace'],
    );
    expect(
      layout.children!.cast<WidgetbookComponent>()[1].useCases.map(
        (useCase) => useCase.name,
      ),
      ['Playground', 'Async actions'],
    );

    final patterns = widgetbook.directories[5] as WidgetbookFolder;
    expect(patterns.name, 'Page Patterns');
    expect(patterns.children!.map((component) => component.name), [
      'Collection Page',
      'Object Page',
      'Form Page',
      'Master Detail Page',
    ]);
    expect(
      patterns.children!.cast<WidgetbookComponent>().every(
        (component) =>
            component.useCases.any((useCase) => useCase.name == 'Playground'),
      ),
      isTrue,
    );
    expect(
      patterns.children!.cast<WidgetbookComponent>().expand(
        (component) => component.useCases.map((useCase) => useCase.name),
      ),
      containsAll([
        'Network workflow',
        'Loaded invoice',
        'Async save',
        'Invoice inbox',
      ]),
    );

    final samples = widgetbook.directories[6] as WidgetbookFolder;
    expect(samples.name, 'Samples');
    expect(samples.children!.map((component) => component.name), [
      'Payment List',
    ]);
    expect(
      samples.children!.cast<WidgetbookComponent>().single.useCases.map(
        (useCase) => useCase.name,
      ),
      ['Playground'],
    );
  });

  test('viewport addon is not exposed globally', () {
    expect(carpenterAddons.whereType<ViewportAddon>(), isEmpty);
  });

  test('layout viewport control exposes semantic presets and off', () {
    expect(LayoutViewportPreset.values.map((preset) => preset.label), [
      'Off',
      'Mobile · Portrait · 390 × 844',
      'Mobile · Landscape · 844 × 390',
      'Tablet · Portrait · 768 × 1024',
      'Tablet · Landscape · 1024 × 768',
      'Desktop · Small · 1280 × 800',
      'Desktop · Large · 1920 × 1080',
    ]);
    expect(LayoutViewportPreset.off.dimensions, isNull);
    expect(LayoutViewportPreset.mobilePortrait.dimensions?.$1.value, 390);
    expect(LayoutViewportPreset.desktopLarge.dimensions?.$2.value, 1080);
  });
}
