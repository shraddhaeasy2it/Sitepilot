import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class Inspection {
  final String name;
  final String email;
  final DateTime date;
  String status;

  Inspection({
    required this.name,
    required this.email,
    required this.date,
    required this.status,
  });
}

class InspectionPage extends StatefulWidget {
  final Function(int) onTotalUpdate;

  const InspectionPage({
    Key? key,
    required this.onTotalUpdate,
    required String siteId,
    required String siteName,
  }) : super(key: key);

  @override
  _InspectionPageState createState() => _InspectionPageState();
}

class _InspectionPageState extends State<InspectionPage> {
  List<Inspection> inspections = [
    Inspection(
      name: "John Doe",
      email: "john@example.com",
      date: DateTime.now(),
      status: "Pending",
    ),
    Inspection(
      name: "Jane Smith",
      email: "jane@example.com",
      date: DateTime.now(),
      status: "Completed",
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.onTotalUpdate(inspections.length);
  }

  void _editInspection(int index) {
    String newStatus = inspections[index].status;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Status"),
        content: DropdownButton<String>(
          value: newStatus,
          isExpanded: true,
          onChanged: (value) {
            setState(() {
              newStatus = value!;
            });
          },
          items: [
            'Pending',
            'In Progress',
            'Completed',
            'Rejected',
          ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                inspections[index].status = newStatus;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteInspection(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Inspection"),
        content: const Text("Are you sure you want to delete this inspection?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                inspections.removeAt(index);
                widget.onTotalUpdate(inspections.length);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _viewInspection(Inspection inspection) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Inspection Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "👤 Name: ${inspection.name}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "✉️ Email: ${inspection.email}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "📅 Date: ${DateFormat.yMMMd().format(inspection.date)}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "⏰ Time: ${DateFormat.Hm().format(inspection.date)}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              "📌 Status: ${inspection.status}",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Text(
          'Inspection',
          style: const TextStyle(color: Colors.white), // Title white
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // Back arrow white
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF6f88e2), Color(0xFF5a73d1), Color(0xFF4a63c0)],
            ),
          ),
        ),
      ),
      body: inspections.isEmpty
          ? const Center(child: Text("No inspections available."))
          : ListView.builder(
              itemCount: inspections.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final inspection = inspections[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inspection.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text("Email: ${inspection.email}"),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${DateFormat.yMMMd().format(inspection.date)}",
                        ),
                        Text(
                          "Time: ${DateFormat.Hm().format(inspection.date)}",
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text("Status: "),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  inspection.status,
                                ).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                inspection.status,
                                style: TextStyle(
                                  color: _getStatusColor(inspection.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _viewInspection(inspection),
                              icon: const Icon(Icons.remove_red_eye),
                              color: Colors.blue[500],
                            ),
                            IconButton(
                              onPressed: () => _editInspection(index),
                              icon: const Icon(Icons.edit),
                              color: Colors.orange[500],
                            ),
                            IconButton(
                              onPressed: () => _deleteInspection(index),
                              icon: const Icon(Icons.delete),
                              color: Colors.red[500],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "In Progress":
        return Colors.blue;
      case "Completed":
        return Colors.green;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}