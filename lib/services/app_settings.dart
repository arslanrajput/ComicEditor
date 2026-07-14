import 'package:hive/hive.dart';

import '../utils/story_text_meta.dart';

/// Lightweight app preferences stored locally (no account).
class AppSettings {
  static const _boxName = 'app_settings';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box get _box {
    if (!Hive.isBoxOpen(_boxName)) {
      throw StateError('AppSettings.init() must be called before use.');
    }
    return Hive.box(_boxName);
  }

  static T _get<T>(String key, T defaultValue) {
    if (!Hive.isBoxOpen(_boxName)) return defaultValue;
    return Hive.box(_boxName).get(key, defaultValue: defaultValue) as T;
  }

  // --- Onboarding ---
  static bool get layoutCoachComplete =>
      _get('layout_coach_complete', false);

  static Future<void> setLayoutCoachComplete() =>
      _box.put('layout_coach_complete', true);

  // --- Defaults ---
  static String get defaultPageFormat =>
      _get('default_page_format', 'A4');

  static Future<void> setDefaultPageFormat(String value) =>
      _box.put('default_page_format', value);

  static bool get defaultShowGrid =>
      _get('default_show_grid', false);

  static Future<void> setDefaultShowGrid(bool value) =>
      _box.put('default_show_grid', value);

  static bool get defaultSnapToGrid =>
      _get('default_snap_to_grid', false);

  static Future<void> setDefaultSnapToGrid(bool value) =>
      _box.put('default_snap_to_grid', value);

  static double get exportPixelRatio =>
      (_get<num>('export_pixel_ratio', 3.0)).toDouble();

  static Future<void> setExportPixelRatio(double value) =>
      _box.put('export_pixel_ratio', value);

  // --- Reader ---
  static String get readingDirection =>
      _get('reading_direction', 'ltr');

  static Future<void> setReadingDirection(String value) =>
      _box.put('reading_direction', value);

  static bool get webtoonReaderMode =>
      _get('webtoon_reader_mode', false);

  static Future<void> setWebtoonReaderMode(bool value) =>
      _box.put('webtoon_reader_mode', value);

  // --- Project list ---
  static String get projectSortOrder =>
      _get('project_sort_order', 'modified');

  static Future<void> setProjectSortOrder(String value) =>
      _box.put('project_sort_order', value);

  // --- Story editor ---
  static StoryTextDirection get storyDisplayDirection =>
      StoryTextDirection.fromKey(_get('story_display_direction', 'horizontal'));

  static Future<void> setStoryDisplayDirection(StoryTextDirection value) =>
      _box.put('story_display_direction', value.storageKey);

  static StoryTextDirection get storyTextDirection =>
      StoryTextDirection.fromKey(_get('story_text_direction', 'horizontal'));

  static Future<void> setStoryTextDirection(StoryTextDirection value) =>
      _box.put('story_text_direction', value.storageKey);

  static bool get storyCreateAsBubble =>
      _get('story_create_as_bubble', false);

  static Future<void> setStoryCreateAsBubble(bool value) =>
      _box.put('story_create_as_bubble', value);

  static String get storyDefaultFont =>
      _get('story_default_font', 'Comic Neue');

  static Future<void> setStoryDefaultFont(String value) =>
      _box.put('story_default_font', value);

  static double get storyDefaultFontSize =>
      (_get<num>('story_default_font_size', 16)).toDouble();

  static Future<void> setStoryDefaultFontSize(double value) =>
      _box.put('story_default_font_size', value);

  // --- Home ---
  static List<String> get bookmarkedTemplateIds {
    final raw = _get<List>('bookmarked_template_ids', const []);
    return raw.map((e) => e.toString()).toList();
  }

  static Future<void> setBookmarkedTemplateIds(List<String> ids) =>
      _box.put('bookmarked_template_ids', ids);
}
