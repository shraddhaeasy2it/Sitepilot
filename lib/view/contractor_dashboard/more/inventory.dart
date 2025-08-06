import 'package:flutter/material.dart';
import 'more_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const InventoryDetailScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final List<Map<String, dynamic>> _inventory = [
    {
      'name': 'Cement',
      'category': 'Building Material',
      'stock': 25,
      'reorderLevel': 20,
      'usageTrend': 'High'
    },
    {
      'name': 'Bricks',
      'category': 'Building Material',
      'stock': 120,
      'reorderLevel': 100,
      'usageTrend': 'Medium'
    },
    {
      'name': 'Steel Rods',
      'category': 'Structural',
      'stock': 10,
      'reorderLevel': 15,
      'usageTrend': 'Low'
    },
  ];

  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredInventory = _selectedCategory == 'All'
        ? _inventory
        : _inventory.where((item) => item['category'] == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Inventory - ${widget.siteName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStockDialog,
            tooltip: 'Add Stock',
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: _showTransferDialog,
            tooltip: 'Transfer Between Sites',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildInventoryList(filteredInventory)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', ..._inventory.map((e) => e['category'] as String).toSet()];
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: _selectedCategory,
        items: categories.map((cat) {
          return DropdownMenuItem(
            value: cat,
            child: Text(cat),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _selectedCategory = val);
        },
      ),
    );
  }

  Widget _buildInventoryList(List<Map<String, dynamic>> items) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = items[index];
        final isLowStock = item['stock'] < item['reorderLevel'];

        return Card(
          child: ListTile(
            leading: Icon(Icons.inventory_2_outlined, color: isLowStock ? Colors.red : Colors.green),
            title: Text('${item['name']} (${item['stock']} units)'),
            subtitle: Text('Category: ${item['category']} | Usage: ${item['usageTrend']}'),
            trailing: isLowStock
                ? const Icon(Icons.warning, color: Colors.red)
                : const Icon(Icons.check_circle, color: Colors.green),
            onTap: () => _showStockOptions(item),
          ),
        );
      },
    );
  }

  void _showStockOptions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_circle),
              title: const Text('Log Usage (Stock Out)'),
              onTap: () {
                Navigator.pop(context);
                _logStockUsage(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Receive Stock (Stock In)'),
              onTap: () {
                Navigator.pop(context);
                _receiveStock(item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Set Reorder Level'),
              onTap: () {
                Navigator.pop(context);
                _setReorderLevel(item);
              },
            ),
          ],
        );
      },
    );
  }

  void _logStockUsage(Map<String, dynamic> item) {
    _showNumberInputDialog(
      title: 'Log Usage for ${item['name']}',
      onConfirm: (qty) {
        setState(() {
          item['stock'] -= qty;
        });
      },
    );
  }

  void _receiveStock(Map<String, dynamic> item) {
    _showNumberInputDialog(
      title: 'Receive Stock for ${item['name']}',
      onConfirm: (qty) {
        setState(() {
          item['stock'] += qty;
        });
      },
    );
  }

  void _setReorderLevel(Map<String, dynamic> item) {
    _showNumberInputDialog(
      title: 'Set Reorder Level for ${item['name']}',
      initialValue: item['reorderLevel'],
      onConfirm: (val) {
        setState(() {
          item['reorderLevel'] = val;
        });
      },
    );
  }

  void _showNumberInputDialog({
    required String title,
    int initialValue = 1,
    required Function(int) onConfirm,
  }) {
    final controller = TextEditingController(text: '$initialValue');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Enter quantity'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null) {
                onConfirm(value);
                Navigator.pop(context);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAddStockDialog() {
    // Future: Implement material dropdown and quantity input for adding new item
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Add New Stock'),
        content: Text('Feature to add new material stock under development.'),
      ),
    );
  }

  void _showTransferDialog() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('Transfer Between Sites'),
        content: Text('Transfer functionality is under development.'),
      ),
    );
  }
}
