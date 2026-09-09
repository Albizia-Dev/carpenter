import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

/// Applies presentation once at registration, retaining each case's constraints
/// and scrolling behavior. Page examples receive the entire selected viewport.
WidgetbookFolder catalogGroup({
  required String name,
  required List<WidgetbookNode> children,
  bool fullViewport = false,
}) {
  WidgetbookNode decorate(WidgetbookNode node) {
    if (node is WidgetbookComponent) {
      return WidgetbookComponent(
        name: node.name,
        isInitiallyExpanded: node.isInitiallyExpanded,
        useCases: [
          for (final useCase in node.useCases)
            WidgetbookUseCase(
              name: useCase.name,
              designLink: useCase.designLink,
              builder: (context) => CatalogPreview(
                fullViewport: fullViewport,
                child: Builder(builder: useCase.builder),
              ),
            ),
        ],
      );
    }
    return WidgetbookFolder(
      name: node.name,
      isInitiallyExpanded: node.isInitiallyExpanded,
      children: node.children!.map(decorate).toList(growable: false),
    );
  }

  return WidgetbookFolder(
    name: name,
    children: children.map(decorate).toList(growable: false),
  );
}

class CatalogPreview extends StatelessWidget {
  const CatalogPreview({
    required this.child,
    this.fullViewport = false,
    super.key,
  });

  final Widget child;
  final bool fullViewport;

  @override
  Widget build(BuildContext context) => Padding(
    padding: fullViewport
        ? EdgeInsets.zero
        : EdgeInsets.all(context.units(1.5.rem)),
    child: child,
  );
}
