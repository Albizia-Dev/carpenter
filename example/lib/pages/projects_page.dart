import 'dart:math' as math;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../demo_data.dart';
import '../demo_routes.dart';

final class ProjectsPage extends StatefulWidget {
  const ProjectsPage({
    super.key,
    required this.navigator,
    required this.toaster,
  });

  final DemoNavigator navigator;
  final CarpenterToasterController toaster;

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

final class _ProjectsPageState extends State<ProjectsPage> {
  static const _pageSize = 5;

  final _searchController = TextEditingController();
  var _selection = CollectionSelection<String>.multiple();
  var _sorting = const <CollectionSort>[];
  var _page = 1;
  var _attentionOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DemoProject> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final result = demoProjects
        .where((project) {
          final matchesQuery =
              query.isEmpty ||
              project.id.toLowerCase().contains(query) ||
              project.name.toLowerCase().contains(query) ||
              project.owner.toLowerCase().contains(query);
          final matchesAttention =
              !_attentionOnly ||
              project.role == FeedbackColorRole.warning ||
              project.role == FeedbackColorRole.danger;
          return matchesQuery && matchesAttention;
        })
        .toList(growable: false);

    if (_sorting.isEmpty) return result;
    final sort = _sorting.first;
    result.sort((a, b) {
      final comparison = switch (sort.id) {
        'name' => a.name.compareTo(b.name),
        'owner' => a.owner.compareTo(b.owner),
        'amount' => a.amount.compareTo(b.amount),
        'status' => a.status.compareTo(b.status),
        _ => a.id.compareTo(b.id),
      };
      return sort.direction == CollectionSortDirection.descending
          ? -comparison
          : comparison;
    });
    return result;
  }

  Future<void> _refresh() async {
    await context.loading.track(
      () => Future<void>.delayed(const Duration(milliseconds: 1000)),
      id: 'projects-refresh',
    );
    if (!mounted) return;
    widget.toaster.show(
      const CarpenterToastDescriptor(
        id: 'projects-refreshed',
        title: 'Projects refreshed',
        message: 'Collection data is current.',
        role: FeedbackColorRole.success,
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _attentionOnly = false;
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totalPages = math.max(1, (filtered.length / _pageSize).ceil());
    final effectivePage = math.min(_page, totalPages);
    final start = math.min((effectivePage - 1) * _pageSize, filtered.length);
    final end = math.min(start + _pageSize, filtered.length);
    final visible = filtered.sublist(start, end);
    final snapshot = CollectionSnapshot<DemoProject>(
      items: visible,
      loadPhase: CollectionLoadPhase.ready,
      contentState: filtered.isEmpty
          ? CollectionContentState.emptyResult
          : CollectionContentState.content,
      pageInfo: CollectionOffsetPageInfo(
        offset: start,
        limit: _pageSize,
        itemCount: visible.length,
        totalItems: filtered.length,
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CarpenterPageHeader(
          title: 'Project portfolio',
          subtitle:
              'A collection page using Carpenter filters, table selection, sorting and pagination.',
          status: CarpenterPageStatus(
            label: '${filtered.length} visible',
            role: FeedbackColorRole.info,
          ),
          primaryActions: [
            CarpenterActionDescriptor(
              id: 'projects.refresh',
              label: 'Refresh',
              icon: Icons.refresh,
              onInvoke: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 24),
        CarpenterFilterBar(
          searchController: _searchController,
          searchLabel: 'Find projects',
          searchPlaceholder: 'ID, name or owner',
          onSearchChanged: (_) => setState(() => _page = 1),
          filterControls: [
            CarpenterSwitch(
              value: _attentionOnly,
              label: 'Needs attention',
              onChanged: (value) => setState(() {
                _attentionOnly = value;
                _page = 1;
              }),
            ),
          ],
          activeFilterCount:
              (_searchController.text.trim().isNotEmpty ? 1 : 0) +
              (_attentionOnly ? 1 : 0),
          clearAction: CarpenterActionDescriptor(
            id: 'projects.clear',
            label: 'Clear filters',
            onInvoke: _clearFilters,
          ),
          actions: [
            CarpenterActionDescriptor(
              id: 'projects.refresh.filters',
              label: 'Refresh',
              icon: Icons.refresh,
              onInvoke: _refresh,
            ),
          ],
        ),
        const SizedBox(height: 16),
        CarpenterTable<DemoProject, String>(
          snapshot: snapshot,
          rowKey: (project) => project.id,
          rowSemanticLabel: (project) => '${project.id} ${project.name}',
          selection: _selection,
          onSelectionChanged: (value) => setState(() => _selection = value),
          sorting: _sorting,
          onSortingChanged: (value) => setState(() => _sorting = value),
          columns: [
            CarpenterTableColumn<DemoProject>.text(
              id: 'id',
              header: 'ID',
              value: (project) => project.id,
              sortable: true,
            ),
            CarpenterTableColumn<DemoProject>.text(
              id: 'name',
              header: 'Project',
              value: (project) => project.name,
              sortable: true,
              width: const CarpenterTableColumnWidth.flexible(flex: 2),
            ),
            CarpenterTableColumn<DemoProject>.text(
              id: 'owner',
              header: 'Owner',
              value: (project) => project.owner,
              sortable: true,
            ),
            CarpenterTableColumn<DemoProject>.number(
              id: 'amount',
              header: 'Budget',
              value: (project) => project.amount,
              formatter: (value) => '\$${value.toInt()}',
              sortable: true,
            ),
            CarpenterTableColumn<DemoProject>.status(
              id: 'status',
              header: 'Status',
              label: (project) => project.status,
              role: (project) => project.role,
              sortable: true,
            ),
            CarpenterTableColumn<DemoProject>.actions(
              id: 'actions',
              header: '',
              actions: (project) => [
                CarpenterActionDescriptor(
                  id: 'project.${project.id}.open',
                  label: 'Open',
                  icon: Icons.arrow_forward,
                  onInvoke: () => widget.navigator.project(project.id),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        CarpenterPaginationBar(
          page: effectivePage,
          totalPages: totalPages,
          siblingCount: 1,
          leading: CarpenterText.body(
            _selection.isEmpty
                ? '${filtered.length} projects'
                : '${_selection.selectedKeys.length} selected',
            colorRole: ContentColorRole.secondary,
          ),
          onPageChanged: (value) => setState(() => _page = value),
        ),
      ],
    );
  }
}
