import 'package:ecoteam_app/models/dashboard/picking_model.dart';
import 'package:ecoteam_app/services/db_helper.dart';
import 'package:flutter/material.dart';

class PickingPage extends StatefulWidget {
  const PickingPage({super.key, required String siteId, required String siteName});

  @override
  State<PickingPage> createState() => _PickingPageState();
}

class _PickingPageState extends State<PickingPage> {
  List<PickingItem> items = [];

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    final data = await DBHelper.getItems();
    setState(() => items = data);
  }

  Future<void> addOrEditItem({PickingItem? item}) async {
    final isEditing = item != null;
    final nameCtrl = TextEditingController(text: item?.name);
    final matNameCtrl = TextEditingController(text: item?.materialName);
    final unitCtrl = TextEditingController(text: item?.materialUnit);
    final qtyCtrl = TextEditingController(text: item?.quantity.toString());
    final supplierCtrl = TextEditingController(text: item?.supplierName);
    DateTime selectedDate = item != null
        ? DateTime.parse(item.deliveryDate)
        : DateTime.now();
    String status = item?.status ?? 'Delivered';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? "Edit Item" : "Add Item"),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: matNameCtrl, decoration: InputDecoration(labelText: "Material Name")),
            TextField(controller: unitCtrl, decoration: InputDecoration(labelText: "Material Unit")),
            TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Quantity")),
            TextField(controller: supplierCtrl, decoration: InputDecoration(labelText: "Supplier Name")),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Date: ${selectedDate.toLocal().toString().split(' ')[0]}"),
                IconButton(
                  icon: Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                )
              ],
            ),
            DropdownButton<String>(
              value: status,
              isExpanded: true,
              onChanged: (val) => setState(() => status = val!),
              items: ['Delivered', 'Cancelled']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
            )
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final newItem = PickingItem(
                id: item?.id,
                name: nameCtrl.text,
                materialName: matNameCtrl.text,
                materialUnit: unitCtrl.text,
                quantity: double.tryParse(qtyCtrl.text) ?? 0,
                supplierName: supplierCtrl.text,
                deliveryDate: selectedDate.toIso8601String(),
                status: status,
              );

              if (isEditing) {
                await DBHelper.updateItem(newItem);
              } else {
                await DBHelper.insertItem(newItem);
              }

              Navigator.pop(context);
              fetchItems();
            },
            child: Text(isEditing ? "Update" : "Add"),
          )
        ],
      ),
    );
  }

  Future<void> deleteItem(int id) async {
    await DBHelper.deleteItem(id);
    fetchItems();
  }

  void viewItem(PickingItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Item Details"),
        content: Text(
            "Name: ${item.name}\nMaterial: ${item.materialName} (${item.materialUnit})\nQty: ${item.quantity}\nSupplier: ${item.supplierName}\nDate: ${item.deliveryDate.split("T").first}\nStatus: ${item.status}"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Material Picking")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditItem(),
        child: Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              leading: Text('${index + 1}'),
              title: Text(item.materialName),
              subtitle: Text('Name: ${item.name}\nQty: ${item.quantity} ${item.materialUnit}\nSupplier: ${item.supplierName}\nDate: ${item.deliveryDate.split("T")[0]}\nStatus: ${item.status}'),
              isThreeLine: true,
              trailing: Wrap(
                spacing: 6,
                children: [
                  IconButton(icon: Icon(Icons.remove_red_eye), onPressed: () => viewItem(item)),
                  IconButton(icon: Icon(Icons.edit), onPressed: () => addOrEditItem(item: item)),
                  IconButton(icon: Icon(Icons.delete), onPressed: () => deleteItem(item.id!)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
