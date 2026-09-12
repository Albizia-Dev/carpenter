import 'use_cases/samples/messenger/catalog.dart';
import 'use_cases/samples/projects_plus/catalog.dart';
import 'package:widgetbook/widgetbook.dart';

import 'helpers/catalog_group.dart';

import 'use_cases/application/runtime_commands.dart';
import 'use_cases/basic/autosuggest.dart';
import 'use_cases/basic/multi_select.dart';
import 'use_cases/basic/additional_primitives.dart';
import 'use_cases/basic/button.dart';
import 'use_cases/basic/card_link.dart';
import 'use_cases/basic/checkbox.dart';
import 'use_cases/basic/combo_box.dart';
import 'use_cases/basic/extended_primitives.dart';
import 'use_cases/basic/file_input.dart';
import 'use_cases/basic/icon.dart';
import 'use_cases/basic/icon_button.dart';
import 'use_cases/basic/input.dart';
import 'use_cases/basic/masked_input.dart';
import 'use_cases/basic/migrated_primitives.dart';
import 'use_cases/basic/radio_group.dart';
import 'use_cases/basic/select.dart';
import 'use_cases/basic/status_indicator.dart';
import 'use_cases/basic/switch.dart';
import 'use_cases/basic/text.dart';
import 'use_cases/basic/text_area.dart';
import 'use_cases/behaviour/context_actions.dart';
import 'use_cases/behaviour/dialog.dart';
import 'use_cases/behaviour/drag_and_drop.dart';
import 'use_cases/behaviour/dropdown.dart';
import 'use_cases/behaviour/loading_boundary.dart';
import 'use_cases/behaviour/menu.dart';
import 'use_cases/behaviour/migrated_behaviour.dart';
import 'use_cases/behaviour/popover.dart';
import 'use_cases/behaviour/toast.dart';
import 'use_cases/behaviour/tooltip.dart';
import 'use_cases/collections/advanced_collections.dart';
import 'use_cases/collections/editable_table.dart';
import 'use_cases/collections/explorer_interactions.dart';
import 'use_cases/collections/collection_kernel.dart';
import 'use_cases/collections/content_primitives.dart';
import 'use_cases/collections/data_list.dart';
import 'use_cases/collections/filter_bar.dart';
import 'use_cases/collections/migrated_collections.dart';
import 'use_cases/collections/navigation_notifications.dart';
import 'use_cases/collections/table.dart';
import 'use_cases/foundation/colors.dart';
import 'use_cases/foundation/gravity_icons.dart';
import 'use_cases/foundation/typography.dart';
import 'use_cases/layout/adaptive_shell.dart';
import 'use_cases/layout/migrated_layout.dart';
import 'use_cases/layout/page_header.dart';
import 'use_cases/layout/semantic_layout.dart';
import 'use_cases/patterns/list_report.dart';
import 'use_cases/patterns/validation.dart';
import 'use_cases/patterns/migrated_patterns.dart';
import 'use_cases/patterns/nested_composition.dart';
import 'use_cases/patterns/page_patterns.dart';
import 'use_cases/patterns/page_states.dart';
import 'use_cases/samples/payment_list.dart';
import 'use_cases/samples/project_page.dart';
import 'use_cases/samples/dsktp_layouts.dart';
import 'use_cases/samples/work_items/inbox.dart';
import 'use_cases/samples/work_items/rsp_acceptance.dart';
import 'use_cases/samples/work_items/rsp_detail.dart';
import 'use_cases/samples/work_items/rsp_recovery.dart';
import 'use_cases/samples/dsktp_collections.dart';
import 'use_cases/samples/treasury/catalog.dart';

/// The single registry used by the app and catalog coverage tests.
/// Navigation follows user tasks; source files retain their implementation layers.
final List<WidgetbookNode> carpenterCatalog = [
  catalogGroup(
    name: 'Foundation',
    children: [
      WidgetbookFolder(
        name: 'Tokens',
        children: [foundationColorsComponent, foundationTypographyComponent],
      ),
      WidgetbookFolder(name: 'Icons', children: [gravityIconsComponent]),
    ],
  ),
  catalogGroup(
    name: 'Components',
    children: [
      WidgetbookFolder(
        name: 'Actions',
        children: [
          buttonComponent,
          iconButtonComponent,
          toggleButtonComponent,
          linkComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Content',
        children: [
          textComponent,
          iconComponent,
          gravityIconComponent,
          avatarComponent,
          avatarGroupComponent,
          cardComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Text input',
        children: [
          fieldShellComponent,
          inputComponent,
          maskedInputComponent,
          numberInputComponent,
          textAreaComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Selection',
        children: [
          checkboxComponent,
          radioGroupComponent,
          switchComponent,
          selectionButtonGroupComponent,
          selectComponent,
          comboBoxComponent,
          autosuggestComponent,
          multiSelectComponent,
          asyncAutosuggestComponent,
          colorPickerComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Date and time',
        children: [
          calendarComponent,
          dateInputComponent,
          dateRangeInputComponent,
          timeInputComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Files',
        children: [fileInputComponent, uploadProgressComponent],
      ),
      WidgetbookFolder(
        name: 'Feedback',
        children: [
          badgeComponent,
          statusIndicatorComponent,
          activityComponent,
          noticeComponent,
        ],
      ),
    ],
  ),
  catalogGroup(
    name: 'Collections',
    children: [
      WidgetbookFolder(
        name: 'Lists',
        children: [
          dataListComponent,
          listTileComponent,
          reorderableCollectionComponent,
          notificationListComponent,
          definitionListComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Tables and trees',
        children: [
          tableComponent,
          editableTableComponent,
          treeViewComponent,
          treeTableComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Boards',
        children: [kanbanComponent, planningBoardComponent],
      ),
      WidgetbookFolder(
        name: 'Navigation and filtering',
        children: [
          filterBarComponent,
          breadcrumbsComponent,
          tabsComponent,
          paginationBarComponent,
        ],
      ),
      WidgetbookFolder(name: 'Inspection', children: [inspectorComponent]),
    ],
  ),
  catalogGroup(
    name: 'Overlays',
    children: [
      WidgetbookFolder(
        name: 'Menus',
        children: [menuComponent, dropdownComponent, contextActionsComponent],
      ),
      WidgetbookFolder(
        name: 'Floating content',
        children: [popoverComponent, tooltipComponent],
      ),
      WidgetbookFolder(
        name: 'Messages',
        children: [dialogComponent, toastComponent],
      ),
    ],
  ),
  catalogGroup(
    name: 'Layout',
    fullViewport: true,
    children: [
      WidgetbookFolder(
        name: 'Shells',
        children: [
          applicationShellComponent,
          appFrameComponent,
          rootLayoutComponent,
          sidebarComponent,
          shellHeaderComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Page structure',
        children: [
          pageHeaderComponent,
          headerActionsComponent,
          toolbarComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Regions',
        children: [
          splitViewComponent,
          restorableSplitComponent,
          tabsLayoutComponent,
          adaptiveRegionComponent,
          masterDetailComponent,
          expanderComponent,
        ],
      ),
    ],
  ),
  catalogGroup(
    name: 'Pages',
    fullViewport: true,
    children: [
      WidgetbookFolder(
        name: 'Browse',
        children: [
          collectionPageComponent,
          listReportComponent,
          masterDetailPageComponent,
          explorerPatternComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Details',
        children: [objectPageComponent, recordPatternComponent],
      ),
      WidgetbookFolder(
        name: 'Edit',
        children: [
          formPageComponent,
          editorPatternComponent,
          validationComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Workflows',
        children: [workflowPatternComponent, nestedCompositionComponent],
      ),
      WidgetbookFolder(name: 'States', children: [pageStateComponent]),
    ],
  ),
  catalogGroup(
    name: 'Application',
    children: [
      WidgetbookFolder(
        name: 'Runtime and commands',
        children: [
          appHostComponent,
          applicationRuntimeComponent,
          commandComponent,
          hotkeyComponent,
          surfaceHostComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Interaction',
        children: [
          controlComponent,
          dragAndDropComponent,
          explorerInteractionsComponent,
        ],
      ),
      WidgetbookFolder(
        name: 'Data lifecycle',
        children: [
          loadingBoundaryComponent,
          collectionKernelComponent,
          collectionLifecycleComponent,
        ],
      ),
    ],
  ),
  catalogGroup(
    name: 'Examples',
    fullViewport: true,
    children: [
      WidgetbookFolder(
        name: 'Business workflows',
        children: [
          paymentListSampleComponent,
          workInboxComponent,
          rspAcceptanceComponent,
          rspDetailComponent,
          rspRecoveryComponent,
          projectPageSampleComponent,
          dsktpLayoutsComponent,
          WidgetbookFolder(name: 'Messenger', children: messengerComponents),
          dsktpCollectionsComponent,
          WidgetbookFolder(
            name: 'Treasury · dsktp',
            children: treasuryComponents,
          ),
          WidgetbookFolder(
            name: 'Проекты+ · dsktp',
            children: projectsPlusComponents,
          ),
        ],
      ),
    ],
  ),
];
