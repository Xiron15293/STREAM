import 'account.dart';
import 'category.dart';

class QuickMovement {
  final String id;
  final String title;
  final double amount;
  final MovementType type;
  final String categoryId;
  final String accountId;
  final String? note;

  const QuickMovement({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.accountId = defaultAccountId,
    this.note,
  });
}
