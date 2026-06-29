import 'dart:convert';

/// Reads/writes element rotation stored in [PanelElementModel.meta] JSON.
class ElementRotation {
  ElementRotation._();

  static double fromMeta(String? meta) {
    if (meta == null || meta.isEmpty) return 0;
    try {
      final decoded = jsonDecode(meta);
      if (decoded is Map && decoded['rotation'] != null) {
        return (decoded['rotation'] as num).toDouble();
      }
    } catch (_) {}
    return 0;
  }

  static String setInMeta(String? meta, double rotation) {
    Map<String, dynamic> map = {};
    if (meta != null && meta.isNotEmpty) {
      try {
        final decoded = jsonDecode(meta);
        if (decoded is Map<String, dynamic>) {
          map = Map<String, dynamic>.from(decoded);
        } else if (decoded is Map) {
          map = decoded.map((k, v) => MapEntry(k.toString(), v));
        }
      } catch (_) {}
    }
    map['rotation'] = rotation;
    return jsonEncode(map);
  }
}
