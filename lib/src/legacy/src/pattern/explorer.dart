import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/page/descriptor.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

class CarpenterExplorerPage extends StatelessWidget {
  const CarpenterExplorerPage({
    super.key,
    required this.descriptor,
    required this.navigation,
    required this.content,
    this.search,
    this.inspector,
    this.header,
    this.compactNavigation,
    this.state = const CarpenterPageReady(),
    this.breakpoint = 760,
  });

  final CarpenterPageDescriptor descriptor;
  final Widget navigation;
  final Widget content;
  final Widget? search;
  final Widget? inspector;
  final Widget? header;
  final Widget? compactNavigation;
  final CarpenterPageState state;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    assert(descriptor.kind == CarpenterPageKind.explorer);
    return CarpenterPage(
      descriptor: descriptor,
      state: state,
      header:
          header ??
          CarpenterPageHeader(
            title: Text(descriptor.title),
            commandBar: search,
          ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < breakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                search ?? const SizedBox.shrink(),
                if (search != null)
                  SizedBox(height: context.face.space('0.75')),
                compactNavigation ?? navigation,
                SizedBox(height: context.face.space('0.75')),
                Expanded(child: content),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (search != null) ...[
                search!,
                SizedBox(height: context.face.space('1')),
              ],
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 250, child: navigation),
                    SizedBox(width: context.face.space('1')),
                    Expanded(child: content),
                    if (inspector != null) ...[
                      SizedBox(width: context.face.space('1')),
                      inspector!,
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
