import 'package:carpenter/carpenter.dart';
import 'package:carpenter/gravity_icons.dart';

import 'package:flutter/widgets.dart';

import '../demo_data.dart';
import '../demo_routes.dart';
import 'package:carpenter_units/carpenter_units.dart';

enum _ProjectTab { details, timeline }

final class ProjectPage extends StatefulWidget {
  const ProjectPage({
    super.key,
    required this.projectId,
    required this.navigator,
    required this.toaster,
  });

  final String projectId;
  final DemoNavigator navigator;
  final CarpenterToasterController toaster;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

final class _ProjectPageState extends State<ProjectPage> {
  var _tab = _ProjectTab.details;

  DemoProject get _project => projectById(widget.projectId);

  Future<void> _save() async {
    await context.loading.track(
      () => Future<void>.delayed(const Duration(milliseconds: 1100)),
      id: 'project-save-${_project.id}',
    );
    if (!mounted) return;
    widget.toaster.show(
      CarpenterToastDescriptor(
        id: 'project-saved-${_project.id}',
        title: 'Project saved',
        message: '${_project.id} was updated successfully.',
        role: FeedbackColorRole.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = _project;
    return ListView(
      padding: EdgeInsets.all(context.units(1.5.rem)),
      children: [
        CarpenterEntityHeader(
          title: project.name,
          subtitle: '${project.id} · ${project.owner}',
          status: CarpenterPageStatus(
            label: project.status,
            role: project.role,
          ),
          metadata: [
            CarpenterStatusIndicator(
              label: '\$${project.amount}',
              role: FeedbackColorRole.neutral,
            ),
            CarpenterStatusIndicator(
              label: '${(project.progress * 100).round()}% complete',
              role: FeedbackColorRole.info,
            ),
          ],
          primaryActions: [
            CarpenterActionDescriptor(
              id: 'project.save',
              label: 'Save',
              icon: GravityIcons.floppyDisk,
              onInvoke: _save,
            ),
          ],
          secondaryActions: [
            CarpenterActionDescriptor(
              id: 'project.back',
              label: 'Back to projects',
              icon: GravityIcons.arrowLeft,
              onInvoke: widget.navigator.projects,
            ),
          ],
        ),
        SizedBox(height: context.units(1.5.rem)),
        CarpenterRecordSummary(
          children: [
            CarpenterRecordMetric(
              label: 'Budget',
              value: CarpenterText.title('\$${project.amount}'),
              description: 'Approved project envelope',
            ),
            CarpenterRecordMetric(
              label: 'Progress',
              value: CarpenterText.title(
                '${(project.progress * 100).round()}%',
              ),
              description: 'Current execution progress',
            ),
            CarpenterRecordMetric(
              label: 'Owner',
              value: CarpenterText.title(project.owner),
              description: 'Responsible workstream',
            ),
          ],
        ),
        SizedBox(height: context.units(1.5.rem)),
        CarpenterProgress(value: project.progress),
        SizedBox(height: context.units(1.5.rem)),
        CarpenterRecordTabs<_ProjectTab>(
          value: _tab,
          onChanged: (value) => setState(() => _tab = value),
          tabs: [
            CarpenterRecordTab<_ProjectTab>(
              value: _ProjectTab.details,
              label: 'Details',
              content: CarpenterCard(
                child: CarpenterRecordDetails(
                  details: [
                    CarpenterRecordDetail(
                      label: 'Project ID',
                      value: CarpenterText.body(project.id),
                    ),
                    CarpenterRecordDetail(
                      label: 'Owner',
                      value: CarpenterText.body(project.owner),
                    ),
                    CarpenterRecordDetail(
                      label: 'Status',
                      value: CarpenterStatusIndicator(
                        label: project.status,
                        role: project.role,
                      ),
                    ),
                    CarpenterRecordDetail(
                      label: 'Budget',
                      value: CarpenterText.body('\$${project.amount}'),
                    ),
                    const CarpenterRecordDetail(
                      label: 'Scope',
                      value: CarpenterText.body(
                        'Demonstrate record composition, responsive details, actions and loading propagation.',
                      ),
                      description:
                          'This is intentionally richer than a static component showcase.',
                    ),
                  ],
                ),
              ),
            ),
            CarpenterRecordTab<_ProjectTab>(
              value: _ProjectTab.timeline,
              label: 'Timeline',
              content: CarpenterTimeline(
                items: [
                  CarpenterTimelineItem(
                    id: 'created',
                    title: 'Project created',
                    description: 'Initial scope and budget were registered.',
                    timestamp: DateTime(2026, 8, 20, 9, 30),
                    leading: const CarpenterAvatar(
                      initials: 'PO',
                      size: Rem(2),
                    ),
                  ),
                  CarpenterTimelineItem(
                    id: 'review',
                    title: 'Review completed',
                    description:
                        'Architecture and delivery plan were approved.',
                    timestamp: DateTime(2026, 8, 24, 14, 10),
                    leading: const CarpenterAvatar(
                      initials: 'AR',
                      size: Rem(2),
                    ),
                  ),
                  CarpenterTimelineItem(
                    id: 'sync',
                    title: 'Latest synchronization',
                    description:
                        'External data was reconciled with the project.',
                    timestamp: DateTime(2026, 8, 28, 11, 45),
                    leading: const CarpenterAvatar(
                      initials: 'SY',
                      size: Rem(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
