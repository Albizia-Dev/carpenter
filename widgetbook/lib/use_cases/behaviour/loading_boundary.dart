import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';
import 'package:carpenter_units/carpenter_units.dart';

enum _LoadingPresentation {
  headerProgress,
  overlay,
  skeleton,
  blockedRegion,
  none,
}

final loadingBoundaryComponent = WidgetbookComponent(
  name: 'Loading Boundary',
  useCases: [
    WidgetbookUseCase(name: 'Presentation playground', builder: _presentation),
    WidgetbookUseCase(name: 'Concurrent operations', builder: _aggregation),
    WidgetbookUseCase(name: 'Nested boundaries', builder: _nested),
    WidgetbookUseCase(name: 'No scope fallback', builder: _noScope),
  ],
);

Widget _presentation(BuildContext context) {
  final presentation = context.knobs.object.segmented(
    label: 'Presentation · Loading UI',
    options: _LoadingPresentation.values,
    initialOption: _LoadingPresentation.headerProgress,
    labelBuilder: (value) => switch (value) {
      _LoadingPresentation.headerProgress => 'Header progress',
      _LoadingPresentation.overlay => 'Overlay',
      _LoadingPresentation.skeleton => 'Skeleton',
      _LoadingPresentation.blockedRegion => 'Blocked region',
      _LoadingPresentation.none => 'None',
    },
  );

  return preview(
    SizedBox(
      width: context.units(51.25.rem),
      height: context.units(32.5.rem),
      child: LoadingBoundary(
        builder: (context, state, child) => _PresentationFrame(
          presentation: presentation,
          state: state,
          child: child,
        ),
        child: const _LoadingActions(),
      ),
    ),
  );
}

Widget _aggregation(BuildContext context) => preview(
  SizedBox(
    width: context.units(47.5.rem),
    child: LoadingBoundary(
      builder: (context, state, child) => CarpenterCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarpenterText.title(
              state.isLoading ? 'Loading · ${state.activeCount}' : 'Idle',
            ),
            SizedBox(height: context.units(.5.rem)),
            CarpenterText.body(
              state.activeOperations.isEmpty
                  ? 'No active operations.'
                  : state.operationCounts.entries
                        .map((entry) => '${entry.key}: ${entry.value}')
                        .join(' · '),
              colorRole: ContentColorRole.secondary,
            ),
            SizedBox(height: context.units(1.rem)),
            child,
          ],
        ),
      ),
      child: const _AggregationControls(),
    ),
  ),
);

Widget _nested(BuildContext context) => preview(
  SizedBox(
    width: context.units(51.25.rem),
    height: context.units(31.25.rem),
    child: const _NestedBoundaryDemo(),
  ),
);

Widget _noScope(BuildContext context) =>
    preview(SizedBox(width: context.units(43.75.rem), child: _NoScopeDemo()));

final class _PresentationFrame extends StatelessWidget {
  const _PresentationFrame({
    required this.presentation,
    required this.state,
    required this.child,
  });

  final _LoadingPresentation presentation;
  final LoadingState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final header = Padding(
      padding: EdgeInsets.all(context.units(1.25.rem)),
      child: CarpenterPageHeader(
        title: 'LoadingBoundary',
        subtitle: state.isLoading
            ? '${state.activeCount} active · ${state.activeOperations.join(', ')}'
            : 'Idle · child owns no loading presentation',
      ),
    );
    final body = Padding(
      padding: EdgeInsets.all(context.units(1.25.rem)),
      child: child,
    );

    return switch (presentation) {
      _LoadingPresentation.headerProgress => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (state.isLoading)
            const CarpenterProgress(
              value: .6,
              height: context.units(.1875.rem),
              semanticLabel: 'Page loading',
            ),
          Expanded(child: body),
        ],
      ),
      _LoadingPresentation.overlay => Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              header,
              Expanded(child: body),
            ],
          ),
          if (state.isLoading)
            ColoredBox(
              color: theme.overlay.scrim,
              child: const Center(child: CarpenterLoader()),
            ),
        ],
      ),
      _LoadingPresentation.skeleton => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: state.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(context.units(1.25.rem)),
                    child: _SkeletonPreview(),
                  )
                : body,
          ),
        ],
      ),
      _LoadingPresentation.blockedRegion => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                body,
                if (state.isLoading)
                  ColoredBox(
                    color: theme.overlay.scrim,
                    child: const Center(child: CarpenterLoader()),
                  ),
              ],
            ),
          ),
        ],
      ),
      _LoadingPresentation.none => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(child: body),
        ],
      ),
    };
  }
}

final class _LoadingActions extends StatelessWidget {
  const _LoadingActions();

  @override
  Widget build(BuildContext context) => CarpenterCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CarpenterText.body(
          'The child only calls context.loading. Change the presentation knob above without touching this widget.',
        ),
        SizedBox(height: context.units(.5.rem)),
        const CarpenterText.caption(
          "context.loading.track(() => repository.save(), id: 'save-profile')",
          colorRole: ContentColorRole.secondary,
        ),
        SizedBox(height: context.units(1.25.rem)),
        Wrap(
          spacing: context.units(.75.rem),
          runSpacing: context.units(.75.rem),
          children: [
            CarpenterButton.filled(
              label: 'Track save · 2s',
              onPressed: () => unawaited(
                context.loading.track(
                  () => Future<void>.delayed(const Duration(seconds: 2)),
                  id: 'save-profile',
                ),
              ),
            ),
            CarpenterButton(
              label: 'Track refresh · 5s',
              onPressed: () => unawaited(
                context.loading.track(
                  () => Future<void>.delayed(const Duration(seconds: 5)),
                  id: 'refresh-documents',
                ),
              ),
            ),
            CarpenterButton.text(
              label: 'Start manual',
              onPressed: () => context.loading.start('manual-operation'),
            ),
            CarpenterButton.text(
              label: 'Finish manual',
              onPressed: () => context.loading.finish('manual-operation'),
            ),
          ],
        ),
      ],
    ),
  );
}

final class _AggregationControls extends StatelessWidget {
  const _AggregationControls();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: context.units(.75.rem),
    runSpacing: context.units(.75.rem),
    children: [
      CarpenterButton(
        label: 'Start A',
        onPressed: () => context.loading.start('operation-a'),
      ),
      CarpenterButton(
        label: 'Start B',
        onPressed: () => context.loading.start('operation-b'),
      ),
      CarpenterButton.text(
        label: 'Finish A',
        onPressed: () => context.loading.finish('operation-a'),
      ),
      CarpenterButton.text(
        label: 'Finish B',
        onPressed: () => context.loading.finish('operation-b'),
      ),
      CarpenterButton.filled(
        label: 'Track same id twice',
        onPressed: () {
          unawaited(
            context.loading.track(
              () => Future<void>.delayed(const Duration(seconds: 2)),
              id: 'same-id',
            ),
          );
          unawaited(
            context.loading.track(
              () => Future<void>.delayed(const Duration(seconds: 5)),
              id: 'same-id',
            ),
          );
        },
      ),
    ],
  );
}

final class _NestedBoundaryDemo extends StatelessWidget {
  const _NestedBoundaryDemo();

  @override
  Widget build(BuildContext context) => LoadingBoundary(
    builder: (outerContext, outerState, child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.all(context.units(1.25.rem)),
          child: CarpenterPageHeader(
            title: 'Outer boundary',
            subtitle: 'Outer active: ${outerState.activeCount}',
            actions: CarpenterButton(
              label: 'Outer operation · 4s',
              onPressed: () => unawaited(
                outerContext.loading.track(
                  () => Future<void>.delayed(const Duration(seconds: 4)),
                  id: 'outer-operation',
                ),
              ),
            ),
          ),
        ),
        if (outerState.isLoading)
          const CarpenterProgress(value: .6, height: context.units(.1875.rem)),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(context.units(1.25.rem)),
            child: child,
          ),
        ),
      ],
    ),
    child: LoadingBoundary(
      builder: (innerContext, innerState, child) => CarpenterCard(
        child: Stack(
          children: [
            child,
            if (innerState.isLoading)
              Positioned.fill(
                child: ColoredBox(
                  color: CarpenterTheme.of(innerContext).overlay.scrim,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CarpenterLoader(),
                        SizedBox(height: context.units(.75.rem)),
                        CarpenterText.body(
                          'Inner active: ${innerState.activeCount}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      child: Builder(
        builder: (innerContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CarpenterText.title('Inner boundary'),
            SizedBox(height: context.units(.5.rem)),
            const CarpenterText.body(
              'This operation is captured by the inner boundary. The outer progress bar stays idle.',
            ),
            SizedBox(height: context.units(1.25.rem)),
            CarpenterButton.filled(
              label: 'Inner operation · 3s',
              onPressed: () => unawaited(
                innerContext.loading.track(
                  () => Future<void>.delayed(const Duration(seconds: 3)),
                  id: 'inner-operation',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

final class _NoScopeDemo extends StatefulWidget {
  const _NoScopeDemo();

  @override
  State<_NoScopeDemo> createState() => _NoScopeDemoState();
}

final class _NoScopeDemoState extends State<_NoScopeDemo> {
  var _status = 'Idle';

  @override
  Widget build(BuildContext context) => CarpenterCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CarpenterText.title('No LoadingScope above'),
        SizedBox(height: context.units(.5.rem)),
        CarpenterText.body(
          'Fallback loading state: ${context.loading.state.isLoading ? 'loading' : 'idle'} · $_status',
          colorRole: ContentColorRole.secondary,
        ),
        SizedBox(height: context.units(1.25.rem)),
        CarpenterButton.filled(
          label: 'Run operation anyway',
          onPressed: () => unawaited(_run(context)),
        ),
      ],
    ),
  );

  Future<void> _run(BuildContext context) async {
    setState(() => _status = 'Business operation is running');
    await context.loading.track(
      () => Future<void>.delayed(const Duration(seconds: 2)),
      id: 'no-scope-operation',
    );
    if (mounted) setState(() => _status = 'Completed without a loading scope');
  }
}

final class _SkeletonPreview extends StatelessWidget {
  const _SkeletonPreview();

  @override
  Widget build(BuildContext context) {
    final color = CarpenterTheme.of(context).surface.subtle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SkeletonLine(
          width: context.units(17.5.rem),
          height: context.units(1.75.rem),
          color: color,
        ),
        SizedBox(height: context.units(1.25.rem)),
        _SkeletonLine(
          width: double.infinity,
          height: context.units(4.5.rem),
          color: color,
        ),
        SizedBox(height: context.units(.75.rem)),
        _SkeletonLine(
          width: double.infinity,
          height: context.units(4.5.rem),
          color: color,
        ),
        SizedBox(height: context.units(.75.rem)),
        _SkeletonLine(
          width: context.units(32.5.rem),
          height: context.units(4.5.rem),
          color: color,
        ),
      ],
    );
  }
}

final class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(context.units(.5.rem)),
        ),
      ),
    ),
  );
}
