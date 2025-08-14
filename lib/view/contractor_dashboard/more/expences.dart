import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecoteam_app/services/company_site_provider.dart';

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

  int? _editingIndex; // null means adding new, otherwise editing existing

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
    final siteProvider = Provider.of<CompanySiteProvider>(context);
    final siteOptions = siteProvider.sites.map((site) => site.name).toList();

    final filtered = _entries.where((e) {
      if (_filter == 'Fuel') return e['type'] == 'Fuel';
      if (_filter == 'Rental') return e['type'] == 'Rental';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        title: Text(
          'Machinery - ${widget.siteName}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) => setState(() => _filter = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Fuel', child: Text('Fuel Only')),
              PopupMenuItem(value: 'Rental', child: Text('Rental Only')),
            ],
            icon: const Icon(Icons.filter_list, color: Colors.white),
          ),
        ],
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

      body: filtered.isEmpty
          ? const Center(child: Text('No entries yet.'))
          : ListView.builder(
              itemCount: filtered.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final entry = filtered[index];
                final actualIndex = _entries.indexOf(entry); // for editing

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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: () {
                            _editingIndex = actualIndex;
                            final existing = _entries[actualIndex];
                            if (existing['type'] == 'Fuel') {
                              _machineController.text = existing['machine'];
                              _litersController.text =
                                  existing['liters'].toString();
                              _rateController.text =
                                  existing['rate'].toString();
                              _showFuelEntryForm(isEditing: true);
                            } else {
                              _machineController.text = existing['machine'];
                              _advanceController.text =
                                  existing['advance'].toString();
                              _dieselUsedController.text =
                                  existing['diesel'].toString();
                              _showRentalEntryForm(siteOptions,
                                  isEditing: true,
                                  fromSiteInit: existing['fromSite'],
                                  toSiteInit: existing['toSite']);
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEntry(actualIndex),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _editingIndex = null; // ensure fresh add
          _showEntryTypeDialog(siteOptions);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _deleteEntry(int index) {
    setState(() {
      _entries.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry deleted'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showEntryTypeDialog(List<String> siteOptions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add New Entry',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_gas_station, color: Colors.orange),
              title: const Text('Fuel Entry'),
              onTap: () {
                Navigator.pop(context);
                _showFuelEntryForm();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blue),
              title: const Text('Rental Entry'),
              onTap: () {
                Navigator.pop(context);
                _showRentalEntryForm(siteOptions);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFuelEntryForm({bool isEditing = false}) {
    String? machineError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildEnhancedTextField(
                        controller: _machineController,
                        label: 'Machine Name',
                        icon: Icons.precision_manufacturing,
                        errorText: machineError,
                      ),
                      const SizedBox(height: 10),
                      _buildEnhancedTextField(
                        controller: _litersController,
                        label: 'Liters',
                        icon: Icons.water_drop,
                        keyboardType: TextInputType.number,
                        suffix: 'L',
                      ),
                      const SizedBox(height: 10),
                      _buildEnhancedTextField(
                        controller: _rateController,
                        label: 'Rate per Liter',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        suffix: '₹/L',
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          final machine = _machineController.text.trim();
                          if (machine.isEmpty) {
                            setState(() =>
                                machineError = 'Machine name is required');
                            return;
                          }
                          final liters =
                              double.tryParse(_litersController.text) ?? 0;
                          final rate =
                              double.tryParse(_rateController.text) ?? 0;

                          final entry = {
                            'type': 'Fuel',
                            'machine': machine,
                            'liters': liters,
                            'rate': rate,
                            'total': liters * rate,
                            'date':
                                DateTime.now().toString().split(' ').first,
                          };

                          setState(() => machineError = null);

                          if (isEditing && _editingIndex != null) {
                            this.setState(() {
                              _entries[_editingIndex!] = entry;
                            });
                          } else {
                            this.setState(() {
                              _entries.add(entry);
                            });
                          }

                          _machineController.clear();
                          _litersController.clear();
                          _rateController.clear();
                          Navigator.pop(context);
                        },
                        child: Text(isEditing ? 'Update Fuel Entry' : 'Save Fuel Entry'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRentalEntryForm(List<String> siteOptions,
      {bool isEditing = false, String? fromSiteInit, String? toSiteInit}) {
    String? machineError;
    String? fromSite = fromSiteInit;
    String? toSite = toSiteInit;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildEnhancedTextField(
                        controller: _machineController,
                        label: 'Machine Name',
                        icon: Icons.precision_manufacturing,
                        errorText: machineError,
                      ),
                      const SizedBox(height: 10),
                      _buildEnhancedDropdown(
                        value: fromSite,
                        label: 'From Site',
                        icon: Icons.location_on,
                        items: siteOptions,
                        onChanged: (val) => setState(() => fromSite = val),
                      ),
                      const SizedBox(height: 10),
                      _buildEnhancedDropdown(
                        value: toSite,
                        label: 'To Site',
                        icon: Icons.flag,
                        items: siteOptions,
                        onChanged: (val) => setState(() => toSite = val),
                      ),
                      const SizedBox(height: 10),
                      _buildEnhancedTextField(
                        controller: _advanceController,
                        label: 'Advance Paid',
                        icon: Icons.payment,
                        keyboardType: TextInputType.number,
                        suffix: '₹',
                      ),
                      const SizedBox(height: 10),
                      _buildEnhancedTextField(
                        controller: _dieselUsedController,
                        label: 'Diesel Supplied',
                        icon: Icons.local_gas_station,
                        keyboardType: TextInputType.number,
                        suffix: 'L',
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          final machine = _machineController.text.trim();
                          if (machine.isEmpty) {
                            setState(() =>
                                machineError = 'Machine name is required');
                            return;
                          }
                          final diesel =
                              double.tryParse(_dieselUsedController.text) ?? 0;
                          final advance =
                              double.tryParse(_advanceController.text) ?? 0;

                          final entry = {
                            'type': 'Rental',
                            'machine': machine,
                            'advance': advance,
                            'diesel': diesel,
                            'fromSite': fromSite,
                            'toSite': toSite,
                            'date':
                                DateTime.now().toString().split(' ').first,
                          };

                          setState(() => machineError = null);

                          if (isEditing && _editingIndex != null) {
                            this.setState(() {
                              _entries[_editingIndex!] = entry;
                            });
                          } else {
                            this.setState(() {
                              _entries.add(entry);
                            });
                          }

                          _machineController.clear();
                          _advanceController.clear();
                          _dieselUsedController.clear();
                          Navigator.pop(context);
                        },
                        child: Text(isEditing ? 'Update Rental Entry' : 'Save Rental Entry'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? errorText,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: const Color(0xFF6f88e2)),
      ),
    );
  }

  Widget _buildEnhancedDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6f88e2)),
      ),
      items: items.map((site) {
        return DropdownMenuItem(value: site, child: Text(site));
      }).toList(),
      onChanged: onChanged,
    );
  }
}