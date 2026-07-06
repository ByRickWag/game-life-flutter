import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/v3_commitment_models.dart';
import '../utils/id_generator.dart';

class AttributeWeightInput {
  const AttributeWeightInput({
    required this.attributeId,
    required this.weight,
    this.isPrimary = false,
  });

  final String attributeId;
  final int weight;
  final bool isPrimary;
}

class ItemAttributeRepository {
  Future<List<ItemAttributeLink>> getLinks({
    required String itemType,
    required String itemId,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT item_attribute_links.*, attributes.name AS attribute_name
      FROM item_attribute_links
      INNER JOIN attributes ON attributes.id = item_attribute_links.attribute_id
      WHERE item_type = ? AND item_id = ?
      ORDER BY is_primary DESC, weight DESC, attributes.sort_order ASC;
    ''', [itemType, itemId]);
    return rows.map(ItemAttributeLink.fromMap).toList();
  }

  Future<void> setLinks({
    required String itemType,
    required String itemId,
    required List<AttributeWeightInput> attributes,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final limited = attributes.take(3).toList();

    await db.transaction((txn) async {
      await txn.delete(
        'item_attribute_links',
        where: 'item_type = ? AND item_id = ?',
        whereArgs: [itemType, itemId],
      );

      for (var index = 0; index < limited.length; index++) {
        final input = limited[index];
        await txn.insert(
          'item_attribute_links',
          {
            'id': IdGenerator.create('attr_link'),
            'item_type': itemType,
            'item_id': itemId,
            'attribute_id': input.attributeId,
            'weight': input.weight.clamp(1, 100),
            'is_primary': input.isPrimary || index == 0 ? 1 : 0,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
