import 'package:flutter/material.dart';

class ManpowerCountScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const ManpowerCountScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<ManpowerCountScreen> createState() => _ManpowerCountScreenState();
}

class _ManpowerCountScreenState extends State<ManpowerCountScreen> {
  final List<String> categories = ['Skilled', 'Unskilled', 'Supervisor', 'Engineer'];
  final Map<String, int> dailyCount = {};

  @override
  void initState() {
    super.initState();
    for (var category in categories) {
      dailyCount[category] = 0;
    }
  }

  void _updateCount(String category, int delta) {
    setState(() {
      dailyCount[category] = (dailyCount[category]! + delta).clamp(0, 999);
    });
  }

  void _generateReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manpower Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categories.map((cat) => Text('$cat: ${dailyCount[cat]}')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Text('Manpower Count - ${widget.siteName}',style: TextStyle(color: Colors.white),),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: categories.map((category) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _updateCount(category, -1),
                      ),
                      Text(
                        '${dailyCount[category]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => _updateCount(category, 1),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
