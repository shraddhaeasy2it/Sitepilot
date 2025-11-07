import 'package:ecoteam_app/admin/models/manpower_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ManpowerPage extends StatefulWidget {
  const ManpowerPage({super.key});

  @override
  State<ManpowerPage> createState() => _ManpowerPageState();
}

class _ManpowerPageState extends State<ManpowerPage> {
  final List<ManpowerRecord> _records = [];
  final TextEditingController _searchController = TextEditingController();
  List<ManpowerRecord> _filteredRecords = [];

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    _filteredRecords = _records;
    _searchController.addListener(_filterRecords);
  }

  void _loadSampleData() {
    _records.add(ManpowerRecord(
      workDate: '10/11/2025',
      supplier: 'Shown Contributions 1',
      site: 'Mining Residency',
      manpowerCounts: {
        'Technician': 15,
        'Electrical': 10,
        'Plumber': 3,
        'Webler': 0,
        'Carpenter': 0,
        'Machinist': 0,
        'Operator': 0,
        'Helper': 3,
        'Assistant Technician': 0,
        'Construction Worker': 0,
        'Assembler': 0,
        'General Labuser': 3,
        'Leader/Unloader': 0,
        'Cleaner': 0,
        'Penn': 8,
        'Superviser': 0,
        'Foreman': 0,
        'Site Manager': 0,
        'Project Coordinator': 0,
        'Team Leader': 0,
        'Engineer': 0,
        'Architect': 0,
        'Quality Inspector': 4,
        'Surveyor': 0,
        'Planner': 0,
        'Safety Officer': 0,
        'Pte Watchs': 0,
        'HSE': 0,
        'Updated Supervisor': 0,
        'tyyy': 0,
      },
    ));
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRecords = _records;
      } else {
        _filteredRecords = _records.where((record) {
          return record.workDate.toLowerCase().contains(query) ||
              record.supplier.toLowerCase().contains(query) ||
              record.site.toLowerCase().contains(query) ||
              record.totalCount.toString().contains(query);
        }).toList();
      }
    });
  }

  void _refreshData() {
    setState(() {
      _filterRecords();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data refreshed')),
    );
  }

  void _addNewRecord() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ManpowerBottomSheet(
        onSave: (newRecord) {
          setState(() {
            _records.add(newRecord);
            _filterRecords();
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _editRecord(ManpowerRecord record) {
    final index = _records.indexOf(record);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ManpowerBottomSheet(
        record: record,
        onSave: (updatedRecord) {
          setState(() {
            _records[index] = updatedRecord;
            _filterRecords();
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deleteRecord(ManpowerRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete the record for ${record.workDate}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _records.remove(record);
                _filterRecords();
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Record deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _filteredRecords.length;

    return Scaffold(
      appBar: AppBar(
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
        title: const Text('Manpower Management', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewRecord,
            tooltip: 'Add New Record',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search records...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Total Count Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Manpower Count:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    totalCount.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                     color: Color(0xFF2a43a0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Records List
          Expanded(
            child: _filteredRecords.isEmpty
                ? const Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = _filteredRecords[index];
                      return _ManpowerCard(
                        record: record,
                        onEdit: () => _editRecord(record),
                        onDelete: () => _deleteRecord(record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ManpowerCard extends StatelessWidget {
  final ManpowerRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManpowerCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Work Date: ${record.workDate}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Supplier: ${record.supplier}'),
                      Text('Site: ${record.site}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: ${record.totalCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class ManpowerBottomSheet extends StatefulWidget {
  final ManpowerRecord? record;
  final Function(ManpowerRecord) onSave;

  const ManpowerBottomSheet({
    super.key,
    this.record,
    required this.onSave,
  });

  @override
  State<ManpowerBottomSheet> createState() => _ManpowerBottomSheetState();
}

class _ManpowerBottomSheetState extends State<ManpowerBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  late String _workDate;
  late String _supplier;
  late String _site;
  final Map<String, int> _manpowerCounts = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing record or default values
    final record = widget.record;
    _workDate = record?.workDate ?? '';
    _supplier = record?.supplier ?? '';
    _site = record?.site ?? '';
    
    // Initialize all manpower counts
    final defaultCounts = {
      'Technician': 0, 'Electrical': 0, 'Plumber': 0, 'Webler': 0,
      'Carpenter': 0, 'Machinist': 0, 'Operator': 0, 'Helper': 0,
      'Assistant Technician': 0, 'Construction Worker': 0, 'Assembler': 0,
      'General Labuser': 0, 'Leader/Unloader': 0, 'Cleaner': 0, 'Penn': 0,
      'Superviser': 0, 'Foreman': 0, 'Site Manager': 0, 'Project Coordinator': 0,
      'Team Leader': 0, 'Engineer': 0, 'Architect': 0, 'Quality Inspector': 0,
      'Surveyor': 0, 'Planner': 0, 'Safety Officer': 0, 'Pte Watchs': 0,
      'HSE': 0, 'Updated Supervisor': 0, 'tyyy': 0,
    };

    defaultCounts.forEach((role, count) {
      _controllers[role] = TextEditingController(
        text: (record?.manpowerCounts[role] ?? count).toString(),
      );
      _manpowerCounts[role] = record?.manpowerCounts[role] ?? count;
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Update manpower counts from controllers
      _controllers.forEach((role, controller) {
        _manpowerCounts[role] = int.tryParse(controller.text) ?? 0;
      });

      final record = ManpowerRecord(
        workDate: _workDate,
        supplier: _supplier,
        site: _site,
        manpowerCounts: Map.from(_manpowerCounts),
        id: widget.record?.id,
      );

      widget.onSave(record);
    }
  }

  Widget _buildManpowerField(String title, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(title),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: _controllers[role],
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (int.tryParse(value) == null) {
                  return 'Enter valid number';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Edit Manpower Record',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Work Date
            TextFormField(
              initialValue: _workDate,
              decoration: const InputDecoration(
                labelText: 'Work Date*',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Work Date is required';
                }
                return null;
              },
              onSaved: (value) => _workDate = value!,
            ),
            const SizedBox(height: 12),
            
            // Supplier
            TextFormField(
              initialValue: _supplier,
              decoration: const InputDecoration(
                labelText: 'Supplier*',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Supplier is required';
                }
                return null;
              },
              onSaved: (value) => _supplier = value!,
            ),
            const SizedBox(height: 12),
            
            // Site
            TextFormField(
              initialValue: _site,
              decoration: const InputDecoration(
                labelText: 'Site*',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Site is required';
                }
                return null;
              },
              onSaved: (value) => _site = value!,
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Manpower Counts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Manpower Counts - Single Column Layout
            Column(
              children: [
                // First Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildManpowerField('Technician', 'Technician'),
                          _buildManpowerField('Electrical', 'Electrical'),
                          _buildManpowerField('Plumber', 'Plumber'),
                          _buildManpowerField('Webler', 'Webler'),
                          _buildManpowerField('Carpenter', 'Carpenter'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildManpowerField('Machinist', 'Machinist'),
                          _buildManpowerField('Operator', 'Operator'),
                          _buildManpowerField('Helper', 'Helper'),
                          _buildManpowerField('Assistant Technician', 'Assistant Technician'),
                          _buildManpowerField('Construction Worker', 'Construction Worker'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Second Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildManpowerField('Assembler', 'Assembler'),
                          _buildManpowerField('General Labuser', 'General Labuser'),
                          _buildManpowerField('Leader/Unloader', 'Leader/Unloader'),
                          _buildManpowerField('Cleaner', 'Cleaner'),
                          _buildManpowerField('Penn', 'Penn'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildManpowerField('Superviser', 'Superviser'),
                          _buildManpowerField('Foreman', 'Foreman'),
                          _buildManpowerField('Site Manager', 'Site Manager'),
                          _buildManpowerField('Project Coordinator', 'Project Coordinator'),
                          _buildManpowerField('Team Leader', 'Team Leader'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Third Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildManpowerField('Engineer', 'Engineer'),
                          _buildManpowerField('Architect', 'Architect'),
                          _buildManpowerField('Quality Inspector', 'Quality Inspector'),
                          _buildManpowerField('Surveyor', 'Surveyor'),
                          _buildManpowerField('Planner', 'Planner'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildManpowerField('Safety Officer', 'Safety Officer'),
                          _buildManpowerField('Pte Watchs', 'Pte Watchs'),
                          _buildManpowerField('HSE', 'HSE'),
                          _buildManpowerField('Updated Supervisor', 'Updated Supervisor'),
                          _buildManpowerField('tyyy', 'tyyy'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Save Button
            ElevatedButton(
              onPressed: _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Record'),
            ),
          ],
        ),
      ),
    );
  }
}