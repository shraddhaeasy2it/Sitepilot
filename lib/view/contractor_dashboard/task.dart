import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:flutter/material.dart';


class TaskPage extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;
  final List<String> contractors;

  const TaskPage({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
    required this.contractors,
  });

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class Task {
  final String id;
  final String title;
  final String description;
  final String siteId;
  final String assignedTo;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.siteId,
    required this.assignedTo,
    required this.dueDate,
    this.status = 'Pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class _TaskPageState extends State<TaskPage> {
  late String _selectedSiteId;
  final List<Task> _tasks = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _loadTasks();
  }

  void _loadTasks() {
    // Mock data - replace with actual API call
    _tasks.clear();
    _tasks.addAll([
      Task(
        id: '1',
        title: 'Foundation Work',
        description: 'Complete foundation pouring for Block A',
        siteId: 'site1',
        assignedTo: 'John Doe',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        status: 'In Progress',
      ),
      Task(
        id: '2',
        title: 'Material Delivery',
        description: 'Deliver steel beams to site',
        siteId: 'site1',
        assignedTo: 'Supplier Team',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        status: 'Pending',
      ),
      Task(
        id: '3',
        title: 'Safety Inspection',
        description: 'Conduct weekly safety inspection',
        siteId: 'site2',
        assignedTo: 'Safety Officer',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      ),
    ]);
  }

  void _showAddTaskBottomSheet() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedContractor = widget.contractors.isNotEmpty ? widget.contractors.first : '';
    String selectedStatus = 'Pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add New Task',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildInputField(
                      controller: titleController,
                      label: 'Task Title',
                      icon: Icons.task,
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildContractorDropdown(
                      value: selectedContractor,
                      onChanged: (value) => selectedContractor = value!,
                    ),
                    const SizedBox(height: 16),
                    _buildDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      onDateSelected: (date) => selectedDate = date,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusDropdown(
                      value: selectedStatus,
                      onChanged: (value) => selectedStatus = value!,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty && 
                              descriptionController.text.isNotEmpty) {
                            final newTask = Task(
                              id: 'task${_tasks.length + 1}',
                              title: titleController.text,
                              description: descriptionController.text,
                              siteId: _selectedSiteId,
                              assignedTo: selectedContractor,
                              dueDate: selectedDate,
                              status: selectedStatus,
                            );
                            setState(() {
                              _tasks.add(newTask);
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Task "${newTask.title}" added successfully!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add Task',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
    );
  }

  Widget _buildContractorDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value.isNotEmpty ? value : null,
      decoration: InputDecoration(
        labelText: 'Assign To',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.person, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
      items: widget.contractors.map((contractor) {
        return DropdownMenuItem<String>(
          value: contractor,
          child: Text(contractor),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime) onDateSelected,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (picked != null && picked != initialDate) {
          onDateSelected(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Due Date',
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${initialDate.day}/${initialDate.month}/${initialDate.year}',
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Status',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(Icons.timeline, color: Colors.blue.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
      items: ['Pending', 'In Progress', 'Completed', 'On Hold']
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTaskItem(Task task) {
    final site = widget.sites.firstWhere((s) => s.id == task.siteId, orElse: () => Site(id: '', name: 'Unknown Site', address: ''));
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status,
                    style: TextStyle(
                      color: _getStatusColor(task.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.description,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  task.assignedTo,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const Spacer(),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.construction, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    site.name,
                    style: TextStyle(color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'on hold':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _selectedSiteId.isEmpty
        ? _tasks
        : _tasks.where((task) => task.siteId == _selectedSiteId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: Column(
        children: [
          _buildSiteSelector(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];
                return _buildTaskItem(task);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSiteSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        child: DropdownButtonFormField<String>(
          value: _selectedSiteId.isNotEmpty ? _selectedSiteId : null,
          decoration: const InputDecoration(
            labelText: 'Filter by Site',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.construction, color: Colors.blue),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: '',
              child: Text('All Sites'),
            ),
            ...widget.sites.map((site) {
              return DropdownMenuItem<String>(
                value: site.id,
                child: Text(site.name),
              );
            }).toList(),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSiteId = newValue;
              });
              widget.onSiteChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}