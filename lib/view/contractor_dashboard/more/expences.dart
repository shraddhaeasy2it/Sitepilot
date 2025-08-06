import 'package:flutter/material.dart';

class MachineryDetailScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const MachineryDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<MachineryDetailScreen> createState() => _MachineryDetailScreenState();
}

class _MachineryDetailScreenState extends State<MachineryDetailScreen> {
  final List<Map<String, dynamic>> _fuelLogs = [];
  final List<Map<String, dynamic>> _rentals = [];

  final _machineController = TextEditingController();
  final _litersController = TextEditingController();
  final _rateController = TextEditingController();
  final _advanceController = TextEditingController();
  final _dieselUsedController = TextEditingController();

  @override
  void dispose() {
    _machineController.dispose();
    _litersController.dispose();
    _rateController.dispose();
    _advanceController.dispose();
    _dieselUsedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Machinery - ${widget.siteName}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Fuel Log'),
              Tab(text: 'Rental Tracking'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFuelLogTab(),
            _buildRentalTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showEntryDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // --------------------- FUEL LOG ----------------------

  Widget _buildFuelLogTab() {
    return ListView.builder(
      itemCount: _fuelLogs.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final entry = _fuelLogs[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.local_gas_station, color: Colors.orange),
            title: Text('${entry['machine']} - ${entry['liters']}L'),
            subtitle: Text('Rate: ₹${entry['rate']} | Total: ₹${entry['total']}'),
            trailing: Text(entry['date']),
          ),
        );
      },
    );
  }

  void _addFuelLog() {
    final machine = _machineController.text.trim();
    final liters = double.tryParse(_litersController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    final total = liters * rate;

    if (machine.isEmpty || liters <= 0 || rate <= 0) return;

    setState(() {
      _fuelLogs.add({
        'machine': machine,
        'liters': liters,
        'rate': rate,
        'total': total,
        'date': DateTime.now().toString().split(' ').first,
      });
    });

    _machineController.clear();
    _litersController.clear();
    _rateController.clear();
  }

  // --------------------- RENTAL TRACKING ----------------------

  Widget _buildRentalTab() {
    return ListView.builder(
      itemCount: _rentals.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final entry = _rentals[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.settings, color: Colors.blue),
            title: Text('${entry['machine']} - Advance: ₹${entry['advance']}'),
            subtitle: Text('Diesel Supplied: ${entry['diesel']}L'),
            trailing: Text(entry['date']),
          ),
        );
      },
    );
  }

  void _addRentalEntry() {
    final machine = _machineController.text.trim();
    final advance = double.tryParse(_advanceController.text) ?? 0;
    final diesel = double.tryParse(_dieselUsedController.text) ?? 0;

    if (machine.isEmpty || advance <= 0) return;

    setState(() {
      _rentals.add({
        'machine': machine,
        'advance': advance,
        'diesel': diesel,
        'date': DateTime.now().toString().split(' ').first,
      });
    });

    _machineController.clear();
    _advanceController.clear();
    _dieselUsedController.clear();
  }

  // --------------------- ENTRY DIALOG ----------------------

  void _showEntryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Entry',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _machineController,
                decoration: const InputDecoration(labelText: 'Machine Name'),
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Fuel Log Entry'),
                children: [
                  TextField(
                    controller: _litersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Liters'),
                  ),
                  TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rate (₹/L)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _addFuelLog();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text('Save Fuel Entry'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text('Rental Entry'),
                children: [
                  TextField(
                    controller: _advanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Advance Paid (₹)'),
                  ),
                  TextField(
                    controller: _dieselUsedController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Diesel Supplied (L)'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _addRentalEntry();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save Rental Entry'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
