class Profile {
  final String id;
  final String name;
  final String dbFileName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.name,
    required this.dbFileName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.main() {
    final now = DateTime.now();
    return Profile(
      id: 'main',
      name: 'Principale',
      dbFileName: 'stream.db',
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim();
    final name = (json['name'] as String?)?.trim();
    final isMain = id == 'main';
    final dbFileName = _normalizedDbFileName(
      id: id ?? 'main',
      rawDbFileName: json['dbFileName'] as String?,
      rawDbPath: json['dbPath'] as String?,
      isMain: isMain,
    );
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    final now = DateTime.now();

    return Profile(
      id: id?.isNotEmpty == true ? id! : 'main',
      name: name?.isNotEmpty == true ? name! : 'Principale',
      dbFileName: dbFileName,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? createdAt ?? now,
    );
  }

  Profile copyWith({
    String? id,
    String? name,
    String? dbFileName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      dbFileName: dbFileName ?? this.dbFileName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dbFileName': dbFileName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isMain => id == 'main';

  static String defaultDbFileNameFor(String profileId) {
    if (profileId == 'main') return 'stream.db';
    return 'stream_profile_$profileId.db';
  }

  static String _normalizedDbFileName({
    required String id,
    required bool isMain,
    String? rawDbFileName,
    String? rawDbPath,
  }) {
    if (isMain) return 'stream.db';

    final candidate = (rawDbFileName ?? rawDbPath?.split('/').last ?? '').trim();
    final fallback = defaultDbFileNameFor(id);
    if (candidate.isEmpty || candidate == 'stream.db') return fallback;
    return candidate;
  }
}
