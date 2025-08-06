import 'package:flutter/material.dart';

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
  final Function(int) onTotalUpdate; // Callback to dashboard

  const InspectionPage({Key? key, required this.onTotalUpdate, required String siteId, required String siteName}) : super(key: key);

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
    widget.onTotalUpdate(inspections.length); // Update dashboard
  }

  void _editInspection(int index) {
    showDialog(
      context: context,
      builder: (_) {
        String newStatus = inspections[index].status;
        return AlertDialog(
          title: Text("Edit Status"),
          content: DropdownButton<String>(
            value: newStatus,
            onChanged: (value) {
              setState(() {
                newStatus = value!;
              });
            },
            items: ['Pending', 'In Progress', 'Completed', 'Rejected']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  inspections[index].status = newStatus;
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteInspection(int index) {
    setState(() {
      inspections.removeAt(index);
      widget.onTotalUpdate(inspections.length); // Update dashboard count
    });
  }

  void _viewInspection(Inspection inspection) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Inspection Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${inspection.name}"),
            Text("Email: ${inspection.email}"),
            Text("Date: ${inspection.date.toLocal()}"),
            Text("Status: ${inspection.status}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Inspections")),
      body: ListView.builder(
        itemCount: inspections.length,
        itemBuilder: (context, index) {
          final inspection = inspections[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(inspection.name),
              subtitle: Text("${inspection.email}\n${inspection.date.toLocal()}"),
              trailing: Wrap(
                spacing: 12,
                children: [
                  Text(inspection.status),
                  IconButton(
                    icon: Icon(Icons.remove_red_eye),
                    onPressed: () => _viewInspection(inspection),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editInspection(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteInspection(index),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
