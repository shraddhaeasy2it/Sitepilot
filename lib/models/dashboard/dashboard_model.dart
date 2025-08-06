import 'package:ecoteam_app/models/dashboard/site_model.dart';


class DashboardData {
  final String selectedSiteId;
  final List<Site> sites;
  final int totalProjects;
  final int totalWorkers;
  final int totalPicking;
  final int totalInspection;

  DashboardData({
    required this.selectedSiteId,
    required this.sites,
    required this.totalProjects,
    required this.totalWorkers,
    required this.totalPicking,
    required this.totalInspection,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      selectedSiteId: json['selectedSiteId'] ?? '',
      sites: (json['sites'] as List).map((e) => Site.fromJson(e)).toList(),
      totalProjects: json['totalProjects'],
      totalWorkers: json['totalWorkers'],
      totalPicking: json['totalPicking'],
      totalInspection: json['totalInspection'],
    );
  }
}