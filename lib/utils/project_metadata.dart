import 'dart:convert';

/// Project metadata stored in [Project.description] as JSON.
class ProjectMetadata {
  final String genre;
  final String format;
  final List<String> castCharacterIds;

  const ProjectMetadata({
    this.genre = 'action',
    this.format = 'comic_book',
    this.castCharacterIds = const [],
  });

  static String encode(ProjectMetadata meta) => jsonEncode(meta.toMap());

  static ProjectMetadata decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ProjectMetadata();
    try {
      final map = jsonDecode(raw);
      if (map is Map) return ProjectMetadata.fromMap(Map<String, dynamic>.from(map));
    } catch (_) {}
    return const ProjectMetadata();
  }

  Map<String, dynamic> toMap() => {
        'genre': genre,
        'format': format,
        'castCharacterIds': castCharacterIds,
      };

  factory ProjectMetadata.fromMap(Map<String, dynamic> map) {
    return ProjectMetadata(
      genre: map['genre'] as String? ?? 'action',
      format: map['format'] as String? ?? 'comic_book',
      castCharacterIds: (map['castCharacterIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Maps wizard format to layout template id.
  static String templateIdForFormat(String format) {
    switch (format) {
      case 'single_page':
        return 'single_splash';
      case 'webtoon':
        return 'webtoon';
      case 'comic_book':
      default:
        return 'manga_page';
    }
  }
}

/// Result returned when the new-project wizard completes.
class NewProjectWizardResult {
  final String name;
  final String genre;
  final String format;
  final String? plotScript;
  final List<String> castCharacterIds;
  final String? templateId;

  const NewProjectWizardResult({
    required this.name,
    required this.genre,
    required this.format,
    this.plotScript,
    this.castCharacterIds = const [],
    this.templateId,
  });
}
