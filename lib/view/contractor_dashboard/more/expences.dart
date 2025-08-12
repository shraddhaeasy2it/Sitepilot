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
  final List<Map<String, dynamic>> _entries = [];
  String _filter = 'All';

  // Controllers
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
    final filtered = _entries.where((e) {
      if (_filter == 'Fuel') return e['type'] == 'Fuel';
      if (_filter == 'Rental') return e['type'] == 'Rental';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Machinery - ${widget.siteName}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Fuel', child: Text('Fuel Only')),
              PopupMenuItem(value: 'Rental', child: Text('Rental Only')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('No entries yet.'))
          : ListView.builder(
              itemCount: filtered.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final entry = filtered[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      entry['type'] == 'Fuel'
                          ? Icons.local_gas_station
                          : Icons.settings,
                      color: entry['type'] == 'Fuel'
                          ? Colors.orange
                          : Colors.blue,
                    ),
                    title: Text('${entry['machine']} (${entry['type']})'),
                    subtitle: entry['type'] == 'Fuel'
                        ? Text(
                            'Liters: ${entry['liters']} | Rate: ₹${entry['rate']}\nTotal: ₹${entry['total']}',
                          )
                        : Text(
                            'Advance: ₹${entry['advance']}\nDiesel: ${entry['diesel']}L\nFrom: ${entry['fromSite']} → ${entry['toSite']}',
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showEntryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEntryDialog() {
    String? fromSite;
    String? toSite;
    String? machineError;

    final List<String> siteOptions = [
      widget.siteName,
      'Other Site 1',
      'Other Site 2',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Add Machinery Entry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _machineController,
                      decoration: InputDecoration(
                        labelText: 'Machine Name',
                        errorText: machineError,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Fuel Entry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _litersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Liters',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rate (₹/L)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final machine = _machineController.text.trim();
                          if (machine.isEmpty) {
                            setState(() => machineError = 'Required');
                            return;
                          }
                          final liters =
                              double.tryParse(_litersController.text) ?? 0;
                          final rate =
                              double.tryParse(_rateController.text) ?? 0;

                          if (liters <= 0 || rate <= 0) return;

                          setState(() {
                            _entries.add({
                              'type': 'Fuel',
                              'machine': machine,
                              'liters': liters,
                              'rate': rate,
                              'total': liters * rate,
                              'date':
                                  DateTime.now().toString().split(' ').first,
                            });
                            _machineController.clear();
                            _litersController.clear();
                            _rateController.clear();
                            machineError = null;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.local_gas_station),
                        label: const Text('Save Fuel Entry'),
                      ),
                    ),
                    const Divider(height: 32),
                    const Text(
                      'Rental Entry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: fromSite,
                      decoration: const InputDecoration(
                        labelText: 'From Site',
                        border: OutlineInputBorder(),
                      ),
                      items: siteOptions.map((site) {
                        return DropdownMenuItem(
                          value: site,
                          child: Text(site),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => fromSite = val),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: toSite,
                      decoration: const InputDecoration(
                        labelText: 'To Site',
                        border: OutlineInputBorder(),
                      ),
                      items: siteOptions.map((site) {
                        return DropdownMenuItem(
                          value: site,
                          child: Text(site),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => toSite = val),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _advanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Advance Paid (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dieselUsedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diesel Supplied (L)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final machine = _machineController.text.trim();
                          if (machine.isEmpty ||
                              fromSite == null ||
                              toSite == null) {
                            setState(() {
                              machineError = machine.isEmpty ? 'Required' : null;
                            });
                            return;
                          }

                          final diesel =
                              double.tryParse(_dieselUsedController.text) ?? 0;
                          final advance =
                              double.tryParse(_advanceController.text) ?? 0;

                          setState(() {
                            _entries.add({
                              'type': 'Rental',
                              'machine': machine,
                              'advance': advance,
                              'diesel': diesel,
                              'fromSite': fromSite,
                              'toSite': toSite,
                              'date':
                                  DateTime.now().toString().split(' ').first,
                            });
                            _machineController.clear();
                            _advanceController.clear();
                            _dieselUsedController.clear();
                            machineError = null;
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Save Rental Entry'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}