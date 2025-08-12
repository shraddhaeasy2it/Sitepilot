import 'package:ecoteam_app/models/dashboard/site_model.dart';
import 'package:flutter/material.dart';


class AttendanceScreen extends StatefulWidget {
  final String? selectedSiteId;
  final Function(String) onSiteChanged;
  final List<Site> sites;

  const AttendanceScreen({
    super.key,
    required this.selectedSiteId,
    required this.onSiteChanged,
    required this.sites,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late String _selectedSiteId;
  final List<Map<String, dynamic>> _attendanceData = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedSiteId = widget.selectedSiteId ?? '';
    _loadAttendanceData();
  }

  @override
  void didUpdateWidget(AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSiteId != oldWidget.selectedSiteId) {
      _selectedSiteId = widget.selectedSiteId ?? '';
      _loadAttendanceData();
    }
  }

  void _loadAttendanceData() {
    // Mock attendance data - replace with actual API call
    _attendanceData.clear();
    _attendanceData.addAll([
      {
        'id': '1',
        'workerName': 'John Smith',
        'workerId': 'WS001',
        'siteId': 'site1',
        'site': 'Site A',
        'date': DateTime.now(),
        'timeIn': '08:00 AM',
        'timeOut': '05:00 PM',
        'status': 'Present',
        'hours': 9.0,
        'overtime': 1.0,
      },
      {
        'id': '2',
        'workerName': 'Maria Garcia',
        'workerId': 'WS002',
        'siteId': 'site2',
        'site': 'Site B',
        'date': DateTime.now(),
        'timeIn': '07:45 AM',
        'timeOut': '05:15 PM',
        'status': 'Present',
        'hours': 9.5,
        'overtime': 1.5,
      },
      {
        'id': '3',
        'workerName': 'Robert Johnson',
        'workerId': 'WS003',
        'siteId': 'site1',
        'site': 'Site A',
        'date': DateTime.now(),
        'timeIn': '08:35 AM',
        'timeOut': '05:00 PM',
        'status': 'Late',
        'hours': 8.5,
        'overtime': 0.5,
      },
      {
        'id': '4',
        'workerName': 'Sarah Williams',
        'workerId': 'WS004',
        'siteId': 'site3',
        'site': 'Site C',
        'date': DateTime.now(),
        'timeIn': '',
        'timeOut': '',
        'status': 'Absent',
        'hours': 0.0,
        'overtime': 0.0,
      },
    ]);
    setState(() {});
  }

  List<Map<String, dynamic>> get filteredAttendanceData {
    return _attendanceData.where((record) {
      final matchesSite = _selectedSiteId.isEmpty || record['siteId'] == _selectedSiteId;
      final matchesDate = record['date'].year == _selectedDate.year &&
          record['date'].month == _selectedDate.month &&
          record['date'].day == _selectedDate.day;
      return matchesSite && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 90,
        title: const Text('Attendence',style: TextStyle(color:Colors.white ,fontWeight: FontWeight.w600,fontSize: 30),),
        backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                ),
              ),
      ),
   body: 
   Column(
      children: [
        _buildSiteSelector(),
        _buildDateSelector(),
        _buildSummaryCards(),
        Expanded(
          child: _buildAttendanceList(),
        ),
      ],
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
      child: DropdownButtonFormField<String>(
        value: _selectedSiteId.isNotEmpty ? _selectedSiteId : null,
        decoration: const InputDecoration(
          labelText: 'Select Site for Attendance',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.location_on, color: Colors.blue),
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
    );
  }

  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Selected Date'),
              onTap: () => _selectDate(context),
            ),
          ),
          const SizedBox(width: 8),
          // ElevatedButton.icon(
          //   onPressed: () => _exportAttendance(),
          //   icon: const Icon(Icons.download),
          //   label: const Text('Export'),
          // ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final presentCount = filteredAttendanceData.where((r) => r['status'] == 'Present').length;
    final absentCount = filteredAttendanceData.where((r) => r['status'] == 'Absent').length;
    final lateCount = filteredAttendanceData.where((r) => r['status'] == 'Late').length;
    final totalHours = filteredAttendanceData.fold<double>(0, (sum, record) => sum + (record['hours'] is int ? (record['hours'] as int).toDouble() : record['hours'] as double));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Present',
              value: presentCount.toString(),
              color: Colors.green,
              icon: Icons.check_circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'Absent',
              value: absentCount.toString(),
              color: Colors.red,
              icon: Icons.cancel,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'Late',
              value: lateCount.toString(),
              color: Colors.orange,
              icon: Icons.schedule,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              title: 'Total Hours',
              value: '${totalHours.toStringAsFixed(1)}h',
              color: Colors.blue,
              icon: Icons.access_time,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAttendanceData.length,
      itemBuilder: (context, index) {
        final record = filteredAttendanceData[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final statusColor = _getStatusColor(record['status']);
    
    return Card(
      color: const Color.fromARGB(255, 247, 247, 247),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            _getStatusIcon(record['status']),
            color: Colors.white,
          ),
        ),
        title: Text(record['workerName']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${record['workerId']}'),
            Text('Site: ${record['site']}'),
            if (record['timeIn'].isNotEmpty)
              Text('Time In: ${record['timeIn']}'),
            if (record['timeOut'].isNotEmpty)
              Text('Time Out: ${record['timeOut']}'),
            Text('Hours: ${record['hours']}h'),
            if (record['overtime'] > 0)
              Text('Overtime: ${record['overtime']}h'),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                record['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
           const SizedBox(height: 7),
           
            GestureDetector(
              onTap: () {
                _editAttendance(record);
              },
              child: Icon(Icons.edit),
            )
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Late':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _editAttendance(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Attendance - ${record['workerName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Time In'),
              controller: TextEditingController(text: record['timeIn']),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Time Out'),
              controller: TextEditingController(text: record['timeOut']),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Status'),
              value: record['status'],
              items: ['Present', 'Absent', 'Late'].map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                // Handle status change
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Save changes
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting attendance data...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}