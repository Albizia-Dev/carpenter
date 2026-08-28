import 'package:carpenter/carpenter.dart';

final class DemoProject {
  const DemoProject({
    required this.id,
    required this.name,
    required this.owner,
    required this.amount,
    required this.status,
    required this.role,
    required this.progress,
  });

  final String id;
  final String name;
  final String owner;
  final int amount;
  final String status;
  final FeedbackColorRole role;
  final double progress;
}

const demoProjects = <DemoProject>[
  DemoProject(
    id: 'CP-1042',
    name: 'Treasury migration',
    owner: 'Finance platform',
    amount: 284000,
    status: 'On track',
    role: FeedbackColorRole.success,
    progress: .72,
  ),
  DemoProject(
    id: 'CP-1043',
    name: 'Supplier onboarding',
    owner: 'Procurement',
    amount: 91000,
    status: 'Needs review',
    role: FeedbackColorRole.warning,
    progress: .43,
  ),
  DemoProject(
    id: 'CP-1044',
    name: 'Warehouse reconciliation',
    owner: 'Operations',
    amount: 167000,
    status: 'On track',
    role: FeedbackColorRole.success,
    progress: .81,
  ),
  DemoProject(
    id: 'CP-1045',
    name: 'Contract archive',
    owner: 'Legal',
    amount: 38000,
    status: 'Blocked',
    role: FeedbackColorRole.danger,
    progress: .29,
  ),
  DemoProject(
    id: 'CP-1046',
    name: 'Employee records',
    owner: 'People',
    amount: 53000,
    status: 'On track',
    role: FeedbackColorRole.success,
    progress: .64,
  ),
  DemoProject(
    id: 'CP-1047',
    name: 'Regional rollout',
    owner: 'Delivery',
    amount: 420000,
    status: 'At risk',
    role: FeedbackColorRole.warning,
    progress: .51,
  ),
  DemoProject(
    id: 'CP-1048',
    name: 'Document templates',
    owner: 'Back office',
    amount: 76000,
    status: 'Ready',
    role: FeedbackColorRole.info,
    progress: .93,
  ),
  DemoProject(
    id: 'CP-1049',
    name: 'Counterparty cleanup',
    owner: 'Master data',
    amount: 115000,
    status: 'On track',
    role: FeedbackColorRole.success,
    progress: .68,
  ),
  DemoProject(
    id: 'CP-1050',
    name: 'Approval matrix',
    owner: 'Governance',
    amount: 87000,
    status: 'Needs review',
    role: FeedbackColorRole.warning,
    progress: .34,
  ),
  DemoProject(
    id: 'CP-1051',
    name: 'Bank integrations',
    owner: 'Treasury',
    amount: 312000,
    status: 'On track',
    role: FeedbackColorRole.success,
    progress: .77,
  ),
  DemoProject(
    id: 'CP-1052',
    name: 'Search indexing',
    owner: 'Platform',
    amount: 128000,
    status: 'Ready',
    role: FeedbackColorRole.info,
    progress: .88,
  ),
  DemoProject(
    id: 'CP-1053',
    name: 'Mobile navigation',
    owner: 'Client platform',
    amount: 146000,
    status: 'At risk',
    role: FeedbackColorRole.warning,
    progress: .57,
  ),
];

DemoProject projectById(String id) => demoProjects.firstWhere(
  (project) => project.id == id,
  orElse: () => demoProjects.first,
);
