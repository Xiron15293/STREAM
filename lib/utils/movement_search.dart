import '../models/account.dart';
import '../models/category.dart';
import '../models/movement.dart';
import '../models/time_filter.dart';

List<Movement> searchMovements({
  required List<Movement> movements,
  required String query,
  required TimeFilter filter,
  required Iterable<Category> categories,
  required Iterable<Account> accounts,
}) {
  final filteredByTime = movements.filterByTime(filter);
  final normalizedQuery = _normalizeQuery(query);
  if (normalizedQuery.isEmpty) {
    return filteredByTime;
  }

  final categoryNamesById = {
    for (final category in categories) category.id: category.name,
  };
  final accountNamesById = {
    for (final account in accounts) account.id: account.name,
  };

  return filteredByTime.where((movement) {
    return _matches(normalizedQuery, movement.title) ||
        _matches(normalizedQuery, movement.note) ||
        _matches(normalizedQuery, categoryNamesById[movement.categoryId]) ||
        _matches(normalizedQuery, accountNamesById[movement.accountId]) ||
        _matches(
          normalizedQuery,
          movement.destinationAccountId == null
              ? null
              : accountNamesById[movement.destinationAccountId!],
        );
  }).toList();
}

String _normalizeQuery(String query) => query.trim().toLowerCase();

bool _matches(String query, String? value) {
  if (value == null) return false;
  return value.trim().toLowerCase().contains(query);
}
