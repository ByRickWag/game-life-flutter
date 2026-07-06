import '../database/app_database.dart';

class AreaAttributeSuggestion {
  const AreaAttributeSuggestion({
    required this.attributeId,
    required this.weight,
    required this.attributeName,
  });

  final String attributeId;
  final int weight;
  final String attributeName;
}

class AreaAttributeSuggestionService {
  static const String _activeAreasSettingKey = 'onboarding_active_area_ids';

  Future<List<Map<String, Object?>>> loadActiveAreas() async {
    final db = await AppDatabase.instance.database;
    final areas = await db.query('areas', orderBy: 'sort_order ASC');
    final settings = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_activeAreasSettingKey],
      limit: 1,
    );

    if (settings.isEmpty) return areas;

    final activeAreaIds = _decodeList(_readString(settings.first, 'value')).toSet();
    if (activeAreaIds.isEmpty) return areas;

    final filtered = areas.where((area) => activeAreaIds.contains(_readString(area, 'id'))).toList();
    return filtered.isEmpty ? areas : filtered;
  }

  Future<List<AreaAttributeSuggestion>> suggestForArea(
    String? areaId, {
    int limit = 3,
  }) async {
    final safeAreaId = areaId?.trim();
    if (safeAreaId == null || safeAreaId.isEmpty) return const [];

    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        area_attribute_links.attribute_id,
        area_attribute_links.weight,
        attributes.name AS attribute_name,
        attributes.sort_order
      FROM area_attribute_links
      INNER JOIN attributes ON attributes.id = area_attribute_links.attribute_id
      WHERE area_attribute_links.area_id = ?
      ORDER BY area_attribute_links.weight DESC, attributes.sort_order ASC, attributes.name ASC
      LIMIT ?;
      ''',
      [safeAreaId, limit],
    );

    return rows.map((row) {
      return AreaAttributeSuggestion(
        attributeId: _readString(row, 'attribute_id'),
        weight: _readInt(row, 'weight'),
        attributeName: _readString(row, 'attribute_name', fallback: 'Atributo'),
      );
    }).where((suggestion) => suggestion.attributeId.isNotEmpty).toList();
  }

  Future<List<String>> suggestAttributeIds(
    String? areaId, {
    int limit = 3,
  }) async {
    final suggestions = await suggestForArea(areaId, limit: limit);
    return suggestions.map((suggestion) => suggestion.attributeId).toList();
  }

  static List<String> _decodeList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _readString(
    Map<String, Object?> map,
    String key, {
    String fallback = '',
  }) {
    final value = map[key];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
