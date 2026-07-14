/// Saved character from Character Studio (local device storage).
class InkwellCharacter {
  final String id;
  final String name;
  final String subtitle;
  final String role;
  final String bio;
  final List<String> traits;
  final String imageAsset;
  final List<int> paletteColors;
  final DateTime updatedAt;

  const InkwellCharacter({
    required this.id,
    required this.name,
    this.subtitle = '',
    this.role = 'Protagonist',
    this.bio = '',
    this.traits = const [],
    this.imageAsset = 'assets/characters/ic_super_hero.png',
    this.paletteColors = const [],
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'subtitle': subtitle,
        'role': role,
        'bio': bio,
        'traits': traits,
        'imageAsset': imageAsset,
        'paletteColors': paletteColors,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InkwellCharacter.fromMap(Map<dynamic, dynamic> map) {
    return InkwellCharacter(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Character',
      subtitle: map['subtitle'] as String? ?? '',
      role: map['role'] as String? ?? 'Protagonist',
      bio: map['bio'] as String? ?? '',
      traits: (map['traits'] as List?)?.cast<String>() ?? [],
      imageAsset: map['imageAsset'] as String? ??
          'assets/characters/ic_super_hero.png',
      paletteColors: (map['paletteColors'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  InkwellCharacter copyWith({
    String? name,
    String? subtitle,
    String? role,
    String? bio,
    List<String>? traits,
    String? imageAsset,
    List<int>? paletteColors,
    DateTime? updatedAt,
  }) {
    return InkwellCharacter(
      id: id,
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      traits: traits ?? this.traits,
      imageAsset: imageAsset ?? this.imageAsset,
      paletteColors: paletteColors ?? this.paletteColors,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
