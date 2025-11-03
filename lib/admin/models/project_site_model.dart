// project_site_model.dart
import 'package:flutter/material.dart';

enum ProjectStatus { ongoing, completed, onHold }

class Project {
  final String id;
  final String name;
  final ProjectStatus status;
  final double budget;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final List<String> members;
  final String companyId;
  final String companyName;
  final double progress;

  Project({
    required this.id,
    required this.name,
    required this.status,
    required this.budget,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.members,
    required this.companyId,
    required this.companyName,
    this.progress = 0.0,
  });

  String get statusString {
    switch (status) {
      case ProjectStatus.ongoing:
        return 'Ongoing';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.onHold:
        return 'On Hold';
    }
  }

  String get statusText => statusString;

  String get dueDate {
    return "${endDate.month.toString().padLeft(2, '0')}/${endDate.day.toString().padLeft(2, '0')}/${endDate.year}";
  }

  Color get statusColor {
    switch (status) {
      case ProjectStatus.ongoing:
        return const Color(0xFF4CAF50);
      case ProjectStatus.completed:
        return const Color(0xFF2196F3);
      case ProjectStatus.onHold:
        return const Color(0xFFFF9800);
    }
  }

  Project copyWith({
    String? id,
    String? name,
    ProjectStatus? status,
    double? budget,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    List<String>? members,
    String? companyId,
    String? companyName,
    double? progress,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      members: members ?? this.members,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      progress: progress ?? this.progress,
    );
  }
}

enum ViewMode { grid, list }