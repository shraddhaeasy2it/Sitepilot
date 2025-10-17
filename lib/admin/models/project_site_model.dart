enum ProjectStatus { ongoing, completed }

class Project {
  final String id;
  final String name;
  final ProjectStatus status;
  final double budget;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final List<String> members;

  Project({
    required this.id,
    required this.name,
    required this.status,
    required this.budget,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.members,
  });

  String get statusText => status == ProjectStatus.ongoing ? 'Ongoing' : 'Completed';
  String get dueDate => 'Due Date: ${_formatDate(endDate)}';
  String get dateRange => '${_formatDate(startDate)} - ${_formatDate(endDate)}';

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Project copyWith({
    String? name,
    ProjectStatus? status,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? members,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      members: members ?? this.members,
    );
  }
}