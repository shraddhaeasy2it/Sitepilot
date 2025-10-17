import 'package:ecoteam_app/admin/models/project_site_model.dart';
import 'package:ecoteam_app/admin/widget/project_siteWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ProjectSitePage extends StatefulWidget {
  const ProjectSitePage({super.key});

  @override
  State<ProjectSitePage> createState() => _ProjectSitePageState();
}

class _ProjectSitePageState extends State<ProjectSitePage> {
  final List<Project> _projects = [
    Project(
      id: '1',
      name: 'Nisarg Residency',
      status: ProjectStatus.ongoing,
      budget: 50000000,
      startDate: DateTime(2025, 9, 13),
      endDate: DateTime(2027, 9, 13),
      description: 'Nisarg Residency',
      members: ['User 1', 'User 2'],
    ),
    Project(
      id: '2',
      name: 'Vijay Residency',
      status: ProjectStatus.ongoing,
      budget: 75000000,
      startDate: DateTime(2024, 9, 15),
      endDate: DateTime(2026, 9, 15),
      description: 'Vijay Residency',
      members: ['User 3', 'User 4'],
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  ViewMode _viewMode = ViewMode.grid;
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects / Sites', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 80.h,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF4a63c0),
                Color(0xFF3a53b0),
                Color(0xFF2a43a0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_viewMode == ViewMode.grid ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Projects')),
              const PopupMenuItem(value: 'Ongoing', child: Text('Ongoing')),
              const PopupMenuItem(value: 'Completed', child: Text('Completed')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: _buildProjectList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProjectBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProjectList() {
    List<Project> filteredProjects = _projects.where((project) {
      final matchesSearch = project.name.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesStatus = _filterStatus == 'All' || 
          (_filterStatus == 'Ongoing' && project.status == ProjectStatus.ongoing) ||
          (_filterStatus == 'Completed' && project.status == ProjectStatus.completed);
      return matchesSearch && matchesStatus;
    }).toList();

    if (_viewMode == ViewMode.grid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8,
        ),
        itemCount: filteredProjects.length,
        itemBuilder: (context, index) {
          return ProjectCard(
            project: filteredProjects[index],
            onTap: () => _showProjectDetailsBottomSheet(filteredProjects[index]),
            onMoreVert: () => _showProjectOptionsPopup(filteredProjects[index]),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: filteredProjects.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ProjectCard(
              project: filteredProjects[index],
              onTap: () => _showProjectDetailsBottomSheet(filteredProjects[index]),
              onMoreVert: () => _showProjectOptionsPopup(filteredProjects[index]),
              isListView: true,
            ),
          );
        },
      );
    }
  }

  void _showProjectDetailsBottomSheet(Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProjectDetailsBottomSheet(project: project),
    );
  }

  void _showProjectOptionsPopup(Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ProjectOptionsPopup(
        project: project,
        onEdit: () {
          Navigator.pop(context);
          _showEditProjectBottomSheet(project);
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteConfirmation(project);
        },
      ),
    );
  }

  void _showCreateProjectBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateProjectBottomSheet(
        onProjectCreated: (newProject) {
          setState(() {
            _projects.add(newProject);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEditProjectBottomSheet(Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProjectBottomSheet(
        project: project,
        onProjectUpdated: (updatedProject) {
          setState(() {
            final index = _projects.indexWhere((p) => p.id == updatedProject.id);
            if (index != -1) {
              _projects[index] = updatedProject;
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete ${project.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _projects.removeWhere((p) => p.id == project.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

enum ViewMode { grid, list }