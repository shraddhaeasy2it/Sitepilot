
import 'package:ecoteam_app/models/dashboard/picking_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "picking.db");

    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE picking (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          materialName TEXT,
          materialUnit TEXT,
          quantity REAL,
          supplierName TEXT,
          deliveryDate TEXT,
          status TEXT
        )
      ''');
    });
  }

  static Future<int> insertItem(PickingItem item) async {
    final db = await database;
    return await db.insert('picking', item.toMap());
  }

  static Future<List<PickingItem>> getItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('picking');
    return maps.map((e) => PickingItem.fromMap(e)).toList();
  }

  static Future<int> updateItem(PickingItem item) async {
    final db = await database;
    return await db.update(
      'picking',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  static Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete('picking', where: 'id = ?', whereArgs: [id]);
  }
}
