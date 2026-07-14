import 'package:hive/hive.dart';

import '../models/inkwell_character.dart';

/// Local Inkwell profile + saved characters (no account server).
class InkwellProfileService {
  static const _boxName = 'inkwell_profile';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box? get _boxOrNull =>
      Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : null;

  static String get displayName =>
      (_boxOrNull?.get('display_name', defaultValue: 'Creator') as String?) ??
      'Creator';

  static Future<void> setDisplayName(String value) async {
    await init();
    await Hive.box(_boxName).put('display_name', value);
  }

  static String get bio =>
      (_boxOrNull?.get('bio', defaultValue: '') as String?) ?? '';

  static Future<void> setBio(String value) async {
    await init();
    await Hive.box(_boxName).put('bio', value);
  }

  static String? get avatarPath =>
      _boxOrNull?.get('avatar_path') as String?;

  static Future<void> setAvatarPath(String? path) async {
    await init();
    final box = Hive.box(_boxName);
    if (path == null) {
      await box.delete('avatar_path');
    } else {
      await box.put('avatar_path', path);
    }
  }

  static List<InkwellCharacter> get characters {
    final raw = _boxOrNull?.get('characters');
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => InkwellCharacter.fromMap(Map<dynamic, dynamic>.from(m)))
        .toList();
  }

  static Future<void> saveCharacter(InkwellCharacter character) async {
    await init();
    final box = Hive.box(_boxName);
    final list = characters.where((c) => c.id != character.id).toList()
      ..add(character);
    await box.put('characters', list.map((c) => c.toMap()).toList());
  }

  static Future<void> deleteCharacter(String id) async {
    await init();
    final box = Hive.box(_boxName);
    final list = characters.where((c) => c.id != id).toList();
    await box.put('characters', list.map((c) => c.toMap()).toList());
  }

  static InkwellCharacter? characterById(String id) {
    for (final c in characters) {
      if (c.id == id) return c;
    }
    return null;
  }
}
