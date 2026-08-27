import 'package:flutter/material.dart' show Text, ThemeData, ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import 'addons/carpenter_addons.dart';
import 'use_cases/basic/button.dart';
import 'use_cases/basic/card_link.dart';
import 'use_cases/basic/autosuggest.dart';
import 'use_cases/basic/checkbox.dart';
import 'use_cases/basic/combo_box.dart';
import 'use_cases/basic/icon.dart';
import 'use_cases/basic/icon_button.dart';
import 'use_cases/basic/input.dart';
import 'use_cases/basic/radio_group.dart';
import 'use_cases/basic/select.dart';
import 'use_cases/basic/status_indicator.dart';
import 'use_cases/basic/switch.dart';
import 'use_cases/basic/text.dart';
import 'use_cases/basic/text_area.dart';
import 'use_cases/behaviour/dropdown.dart';
import 'use_cases/behaviour/dialog.dart';
import 'use_cases/behaviour/menu.dart';
import 'use_cases/behaviour/popover.dart';
import 'use_cases/behaviour/tooltip.dart';
import 'use_cases/behaviour/toast.dart';
import 'use_cases/collections/collection_kernel.dart';
import 'use_cases/collections/content_primitives.dart';
import 'use_cases/collections/data_list.dart';
import 'use_cases/collections/table.dart';
import 'use_cases/foundation/colors.dart';
import 'use_cases/layout/semantic_layout.dart';
import 'use_cases/patterns/page_patterns.dart';
import 'use_cases/samples/payment_list.dart';

Widget createCarpenterWidgetbook() => Widgetbook.material(
  directories: [
    WidgetbookFolder(name: 'Foundation', children: [foundationColorsComponent]),
    WidgetbookFolder(
      name: 'Basic',
      children: [
        textComponent,
        iconComponent,
        statusIndicatorComponent,
        buttonComponent,
        iconButtonComponent,
        cardComponent,
        linkComponent,
        inputComponent,
        textAreaComponent,
        checkboxComponent,
        radioGroupComponent,
        switchComponent,
        selectComponent,
        comboBoxComponent,
        autosuggestComponent,
      ],
    ),
    WidgetbookFolder(
      name: 'Behaviour',
      children: [
        popoverComponent,
        menuComponent,
        dropdownComponent,
        tooltipComponent,
        toastComponent,
        dialogComponent,
      ],
    ),
    WidgetbookFolder(
      name: 'Collections',
      children: [
        collectionKernelComponent,
        dataListComponent,
        definitionListComponent,
        tabsComponent,
        tableComponent,
      ],
    ),
    WidgetbookFolder(
      name: 'Layout',
      children: [
        applicationShellComponent,
        toolbarComponent,
        splitViewComponent,
        adaptiveRegionComponent,
        masterDetailComponent,
      ],
    ),
    WidgetbookFolder(
      name: 'Page Patterns',
      children: [
        collectionPageComponent,
        objectPageComponent,
        formPageComponent,
        masterDetailPageComponent,
      ],
    ),
    WidgetbookFolder(name: 'Samples', children: [paymentListSampleComponent]),
  ],
  addons: carpenterAddons,
  header: const Text('Carpenter'),
  lightTheme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  themeMode: ThemeMode.system,
);
