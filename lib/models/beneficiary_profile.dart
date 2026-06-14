import '../design/stream_icon_library.dart';

class BeneficiaryProfile {
  static const String defaultIconKey = 'user';
  final String id;
  final String key;
  final String displayName;
  final String iconKey;
  final int color;
  final bool archived;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const BeneficiaryProfile({
    required this.id,
    required this.key,
    required this.displayName,
    this.iconKey = defaultIconKey,
    this.color = StreamColorPalette.defaultColor,
    this.archived = false,
    required this.createdAt,
    this.updatedAt,
  });

  BeneficiaryProfile copyWith({
    String? id,
    String? key,
    String? displayName,
    String? iconKey,
    int? color,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BeneficiaryProfile(
      id: id ?? this.id,
      key: key ?? this.key,
      displayName: displayName ?? this.displayName,
      iconKey: iconKey ?? this.iconKey,
      color: color ?? this.color,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String normalizeKey(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String cleanDisplayName(String name) {
    return name.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
