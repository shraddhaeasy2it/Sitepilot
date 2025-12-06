// project_site_page.dart
import 'package:ecoteam_app/admin/models/project_site_model.dart';
import 'package:ecoteam_app/admin/provider/project_site_provider.dart';
import 'package:ecoteam_app/admin/widget/project_siteWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class ProjectSitePage extends StatefulWidget {
  const ProjectSitePage({super.key});

  @override
  State<ProjectSitePage> createState() => _ProjectSitePageState();
}

class _ProjectSitePageState extends State<ProjectSitePage> {
  final TextEditingController _searchController = TextEditingController();
  ViewMode _viewMode = ViewMode.grid;
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    // Load data when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProjectSiteProvider>(context, listen: false);
      provider.loadCompanies();
    });
  }

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
              const PopupMenuItem(value: 'On Hold', child: Text('On Hold')),
            ],
          ),
        ],
      ),
      body: Consumer<ProjectSiteProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Company Dropdown
              _buildCompanyDropdown(provider),
              
              // Search Bar
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
              
              // Projects Count
              _buildProjectsCount(provider),
              
              // Projects List
              Expanded(
                child: _buildProjectList(provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectBottomSheet(context),
        backgroundColor: const Color(0xFF4a63c0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCompanyDropdown(ProjectSiteProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: DropdownButton<String>(
            value: provider.selectedCompanyId,
            isExpanded: true,
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('All Companies', style: TextStyle(color: Colors.grey)),
              ),
              ...provider.companies.map((company) {
                return DropdownMenuItem(
                  value: company['id'].toString(),
                  child: Text(company['name']),
                );
              }).toList(),
            ],
            onChanged: (String? newValue) {
              final provider = Provider.of<ProjectSiteProvider>(context, listen: false);
              provider.selectCompany(newValue ?? '');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProjectsCount(ProjectSiteProvider provider) {
    final filteredProjects = _getFilteredProjects(provider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Text(
            '${filteredProjects.length} projects',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          if (provider.selectedCompanyName != null && provider.selectedCompanyName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4a63c0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                provider.selectedCompanyName!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF4a63c0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectList(ProjectSiteProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4a63c0)),
        ),
      );
    }

    final filteredProjects = _getFilteredProjects(provider);

    if (filteredProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Projects Found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.selectedCompanyId == null || provider.selectedCompanyId!.isEmpty
                  ? 'Add your first project to get started'
                  : 'No projects found for selected company',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
            onTap: () => _showProjectDetailsBottomSheet(context, filteredProjects[index]),
            onMoreVert: () => _showProjectOptionsPopup(context, filteredProjects[index]),
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
              onTap: () => _showProjectDetailsBottomSheet(context, filteredProjects[index]),
              onMoreVert: () => _showProjectOptionsPopup(context, filteredProjects[index]),
              isListView: true,
            ),
          );
        },
      );
    }
  }

  List<Project> _getFilteredProjects(ProjectSiteProvider provider) {
    List<Project> projects = provider.filteredProjects;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      projects = projects.where((project) {
        return project.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            project.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            project.companyName.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();
    }

    // Apply status filter
    if (_filterStatus != 'All') {
      projects = projects.where((project) {
        switch (_filterStatus) {
          case 'Ongoing':
            return project.status == ProjectStatus.ongoing;
          case 'Completed':
            return project.status == ProjectStatus.completed;
          case 'On Hold':
            return project.status == ProjectStatus.onHold;
          default:
            return true;
        }
      }).toList();
    }

    return projects;
  }

  void _showProjectDetailsBottomSheet(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProjectDetailsBottomSheet(project: project),
    );
  }

  void _showProjectOptionsPopup(BuildContext context, Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ProjectOptionsPopup(
        project: project,
        onEdit: () {
          Navigator.pop(context);
          _showEditProjectBottomSheet(context, project);
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteConfirmation(context, project);
        },
      ),
    );
  }

  void _showCreateProjectBottomSheet(BuildContext context) {
    final provider = Provider.of<ProjectSiteProvider>(context, listen: false);
    
    if (provider.companies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while companies are loading...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateProjectBottomSheet(
        companies: provider.companies,
        onProjectCreated: (newProject) async {
          final success = await provider.addProject(newProject);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Project created successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create project'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditProjectBottomSheet(BuildContext context, Project project) {
    final provider = Provider.of<ProjectSiteProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProjectBottomSheet(
        project: project,
        companies: provider.companies,
        onProjectUpdated: (updatedProject) async {
          final success = await provider.updateProject(updatedProject);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Project updated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update project'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final provider = Provider.of<ProjectSiteProvider>(context, listen: false);
              final success = await provider.deleteProject(project.id);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Project deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete project'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class EditProjectBottomSheet extends StatefulWidget {
  final Project project;
  final List<Map<String, dynamic>> companies;
  final Function(Project) onProjectUpdated;

  const EditProjectBottomSheet({
    Key? key,
    required this.project,
    required this.companies,
    required this.onProjectUpdated,
  }) : super(key: key);

  @override
  State<EditProjectBottomSheet> createState() => _EditProjectBottomSheetState();
}

class _EditProjectBottomSheetState extends State<EditProjectBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  late String? _selectedCompanyId;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(text: widget.project.description);
    _budgetController = TextEditingController(text: widget.project.budget.toString());
    _startDateController = TextEditingController(
      text: "${widget.project.startDate.year}-${widget.project.startDate.month.toString().padLeft(2, '0')}-${widget.project.startDate.day.toString().padLeft(2, '0')}",
    );
    _endDateController = TextEditingController(
      text: "${widget.project.endDate.year}-${widget.project.endDate.month.toString().padLeft(2, '0')}-${widget.project.endDate.day.toString().padLeft(2, '0')}",
    );
    
    _selectedCompanyId = widget.project.companyId;
    _selectedStatus = widget.project.statusString;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Project',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Company Dropdown
              _buildCompanyDropdown(),
              SizedBox(height: 16.h),

              // Project Name
              _buildTextField(
                controller: _nameController,
                label: 'Project Name',
                icon: Icons.work_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Budget
              _buildTextField(
                controller: _budgetController,
                label: 'Budget',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid budget';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Date Row
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      controller: _startDateController,
                      label: 'Start Date',
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildDateField(
                      controller: _endDateController,
                      label: 'End Date',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Status Dropdown
              _buildStatusDropdown(),
              SizedBox(height: 32.h),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _updateProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4a63c0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Update Project',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company *',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCompanyId,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              errorStyle: TextStyle(fontSize: 12.sp),
            ),
            items: widget.companies.map((company) {
              return DropdownMenuItem(
                value: company['id'].toString(),
                child: Text(company['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCompanyId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a company';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4a63c0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(controller),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFF4a63c0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            items: const [
              DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              DropdownMenuItem(value: 'On Hold', child: Text('On Hold')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4a63c0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _updateProject() {
    if (_formKey.currentState!.validate() && _selectedCompanyId != null) {
      // Get company name
      final company = widget.companies.firstWhere(
        (c) => c['id'].toString() == _selectedCompanyId,
      );

      // Parse status
      ProjectStatus status;
      switch (_selectedStatus) {
        case 'Completed':
          status = ProjectStatus.completed;
          break;
        case 'On Hold':
          status = ProjectStatus.onHold;
          break;
        default:
          status = ProjectStatus.ongoing;
      }

      // Parse dates
      DateTime startDate;
      DateTime endDate;
      try {
        startDate = DateTime.parse(_startDateController.text);
        endDate = DateTime.parse(_endDateController.text);
      } catch (e) {
        // Fallback to original dates
        startDate = widget.project.startDate;
        endDate = widget.project.endDate;
      }

      // Create updated project
      final updatedProject = widget.project.copyWith(
        name: _nameController.text,
        status: status,
        budget: double.parse(_budgetController.text),
        startDate: startDate,
        endDate: endDate,
        description: _descriptionController.text,
        companyId: _selectedCompanyId!,
        companyName: company['name'],
      );

      widget.onProjectUpdated(updatedProject);
      Navigator.pop(context);
    }
  }
}

class CreateProjectBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> companies;
  final Function(Project) onProjectCreated;

  const CreateProjectBottomSheet({
    Key? key,
    required this.companies,
    required this.onProjectCreated,
  }) : super(key: key);

  @override
  State<CreateProjectBottomSheet> createState() => _CreateProjectBottomSheetState();
}

class _CreateProjectBottomSheetState extends State<CreateProjectBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String? _selectedCompanyId;
  String _selectedStatus = 'Ongoing';

  @override
  void initState() {
    super.initState();
    // Select first company by default
    if (widget.companies.isNotEmpty) {
      _selectedCompanyId = widget.companies.first['id'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New Project',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Company Dropdown
              _buildCompanyDropdown(),
              SizedBox(height: 16.h),

              // Project Name
              _buildTextField(
                controller: _nameController,
                label: 'Project Name',
                icon: Icons.work_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Budget
              _buildTextField(
                controller: _budgetController,
                label: 'Budget',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter project budget';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid budget';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Date Row
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      controller: _startDateController,
                      label: 'Start Date',
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildDateField(
                      controller: _endDateController,
                      label: 'End Date',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Status Dropdown
              _buildStatusDropdown(),
              SizedBox(height: 32.h),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4a63c0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Create Project',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Company *',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCompanyId,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              errorStyle: TextStyle(fontSize: 12.sp),
            ),
            items: widget.companies.map((company) {
              return DropdownMenuItem(
                value: company['id'].toString(),
                child: Text(company['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCompanyId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a company';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4a63c0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(controller),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.calendar_today, color: const Color(0xFF4a63c0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF4a63c0), width: 2),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            ),
            items: const [
              DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              DropdownMenuItem(value: 'On Hold', child: Text('On Hold')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4a63c0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  void _createProject() {
    if (_formKey.currentState!.validate() && _selectedCompanyId != null) {
      // Get company name
      final company = widget.companies.firstWhere(
        (c) => c['id'].toString() == _selectedCompanyId,
      );

      // Parse status
      ProjectStatus status;
      switch (_selectedStatus) {
        case 'Completed':
          status = ProjectStatus.completed;
          break;
        case 'On Hold':
          status = ProjectStatus.onHold;
          break;
        default:
          status = ProjectStatus.ongoing;
      }

      // Parse dates
      DateTime startDate;
      DateTime endDate;
      try {
        startDate = DateTime.parse(_startDateController.text);
        endDate = DateTime.parse(_endDateController.text);
      } catch (e) {
        // Fallback dates
        startDate = DateTime.now();
        endDate = DateTime.now().add(const Duration(days: 365));
      }

      // Create project
      final newProject = Project(
        id: '', // Will be generated by API
        name: _nameController.text,
        status: status,
        budget: double.parse(_budgetController.text),
        startDate: startDate,
        endDate: endDate,
        description: _descriptionController.text,
        members: [],
        companyId: _selectedCompanyId!,
        companyName: company['name'],
      );

      widget.onProjectCreated(newProject);
      Navigator.pop(context);
    }
  }
}