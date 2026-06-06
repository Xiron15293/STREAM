import '../design/stream_icon_library.dart';

enum AccountType { cash, bank, card, savings, other }

const String defaultAccountId = 'acc_default';

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final String iconKey;
  final int color;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.iconKey = StreamIconLibrary.defaultAccountIcon,
    this.color = StreamColorPalette.defaultColor,
    this.archived = false,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;
}
