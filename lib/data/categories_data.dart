import '../models/category.dart';

class DefaultCategories {
  static const List<Category> income = [
    Category(id: 'inc_1', name: 'Stipendio', type: MovementType.income, color: 0xFF4CAF50),
    Category(id: 'inc_2', name: 'Rimborso', type: MovementType.income, color: 0xFF66BB6A),
    Category(id: 'inc_3', name: 'Vendita', type: MovementType.income, color: 0xFF81C784),
    Category(id: 'inc_4', name: 'Altro', type: MovementType.income, color: 0xFFA5D6A7),
  ];

  static const List<Category> expense = [
    Category(id: 'exp_1', name: 'Spesa', type: MovementType.expense, color: 0xFFEF5350),
    Category(id: 'exp_2', name: 'Casa', type: MovementType.expense, color: 0xFFEC407A),
    Category(id: 'exp_3', name: 'Auto', type: MovementType.expense, color: 0xFFAB47BC),
    Category(id: 'exp_4', name: 'Svago', type: MovementType.expense, color: 0xFFFF7043),
    Category(id: 'exp_5', name: 'Salute', type: MovementType.expense, color: 0xFF42A5F5),
    Category(id: 'exp_6', name: 'Altro', type: MovementType.expense, color: 0xFF78909C),
  ];

  static List<Category> get all => [...income, ...expense];

  static Category? byId(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
