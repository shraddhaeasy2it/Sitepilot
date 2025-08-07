import 'package:flutter/material.dart';

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
        : _inventory
            .where((item) => item['category'] == _selectedCategory)
            .toList();

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
          elevation: 4,
          child: ListTile(
            leading: Icon(
              Icons.inventory_2_outlined,
              color: isLowStock ? Colors.red : Colors.green,
            ),
            title: Text(
              '${item['name']} (${item['stock']} units)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isLowStock ? Colors.red.shade700 : Colors.green.shade700,
              ),
            ),
            subtitle: Text(
              'Category: ${item['category']} | Usage: ${item['usageTrend']}',
              style: const TextStyle(fontSize: 13),
            ),
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
        return Wrap(
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
        if (qty > item['stock']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not enough stock available')),
          );
          return;
        }
        setState(() {
          item['stock'] -= qty;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['name']} stock reduced by $qty')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['name']} stock increased by $qty')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item['name']} reorder level set to $val')),
        );
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
              if (value != null && value >= 0) {
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
    String name = '';
    String category = '';
    int stock = 0;
    int reorderLevel = 10;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add New Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Material Name'),
              onChanged: (val) => name = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Category'),
              onChanged: (val) => category = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Initial Stock'),
              keyboardType: TextInputType.number,
              onChanged: (val) => stock = int.tryParse(val) ?? 0,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Reorder Level'),
              keyboardType: TextInputType.number,
              onChanged: (val) => reorderLevel = int.tryParse(val) ?? 10,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty && category.isNotEmpty && stock >= 0) {
                setState(() {
                  _inventory.add({
                    'name': name,
                    'category': category,
                    'stock': stock,
                    'reorderLevel': reorderLevel,
                    'usageTrend': 'Medium',
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New material added')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() {
    String materialName = '';
    int transferQty = 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Transfer Stock Between Sites'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Material Name'),
              onChanged: (val) => materialName = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Quantity to Transfer'),
              keyboardType: TextInputType.number,
              onChanged: (val) => transferQty = int.tryParse(val) ?? 0,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transfer request sent (mocked)')),
              );
            },
            child: const Text('Transfer'),
          ),
        ],
      ),
    );
  }
}
