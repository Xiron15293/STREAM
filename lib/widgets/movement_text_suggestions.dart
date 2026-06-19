import 'package:flutter/material.dart';

import '../data/database.dart';
import '../models/category.dart';
import '../theme.dart';

enum MovementTextSuggestionField { title, note }

class MovementTextSuggestion {
  final String text;
  final int frequency;
  final DateTime latestActivity;
  final bool startsWithQuery;
  final bool containsQuery;
  final bool sameType;
  final bool sameCategory;
  final bool sameBeneficiary;

  const MovementTextSuggestion({
    required this.text,
    required this.frequency,
    required this.latestActivity,
    required this.startsWithQuery,
    required this.containsQuery,
    required this.sameType,
    required this.sameCategory,
    required this.sameBeneficiary,
  });
}

class MovementBeneficiarySuggestion {
  final String text;
  final int frequency;
  final DateTime latestActivity;
  final bool startsWithQuery;
  final bool containsQuery;

  const MovementBeneficiarySuggestion({
    required this.text,
    required this.frequency,
    required this.latestActivity,
    required this.startsWithQuery,
    required this.containsQuery,
  });
}

String normalizeMovementText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<MovementTextSuggestion> buildMovementTextSuggestions({
  required AppDatabase db,
  required String query,
  required MovementTextSuggestionField field,
  required MovementType type,
  String? categoryId,
  String? beneficiary,
  int limit = 5,
}) {
  final normalizedQuery = normalizeMovementText(query);
  if (normalizedQuery.length < 2) return const <MovementTextSuggestion>[];

  final normalizedQueryCompact = normalizedQuery.replaceAll(' ', '');
  final normalizedQuerySkeleton = _skeleton(normalizedQuery);
  final beneficiaryKey = normalizeMovementText(beneficiary ?? '');
  final stats = <String, _MovementTextSuggestionStats>{};

  for (final movement in db.movements) {
    final candidateText = switch (field) {
      MovementTextSuggestionField.title => movement.title,
      MovementTextSuggestionField.note => movement.note ?? '',
    };
    final cleaned = candidateText.trim();
    if (cleaned.isEmpty) continue;

    final normalizedCandidate = normalizeMovementText(cleaned);
    if (normalizedCandidate.isEmpty || normalizedCandidate == normalizedQuery) {
      continue;
    }

    final compactCandidate = normalizedCandidate.replaceAll(' ', '');
    final skeletonCandidate = _skeleton(normalizedCandidate);
    final directStartsWith =
        normalizedCandidate.startsWith(normalizedQuery) ||
        compactCandidate.startsWith(normalizedQueryCompact);
    final looseStartsWith =
        normalizedQuerySkeleton.isNotEmpty &&
        skeletonCandidate.startsWith(normalizedQuerySkeleton);
    final startsWith = directStartsWith || looseStartsWith;
    final directContains =
        normalizedCandidate.contains(normalizedQuery) ||
        compactCandidate.contains(normalizedQueryCompact);
    final looseContains =
        normalizedQuerySkeleton.isNotEmpty &&
        skeletonCandidate.contains(normalizedQuerySkeleton);
    final contains = directContains || looseContains;
    if (!startsWith && !contains) continue;

    final sameType = movement.type == type;
    final sameCategory =
        categoryId != null && movement.categoryId == categoryId;
    final sameBeneficiary =
        beneficiaryKey.isNotEmpty &&
        normalizeMovementText(movement.payee ?? '') == beneficiaryKey;

    final current = stats[normalizedCandidate];
    final latestActivity = movement.updatedAt.isAfter(movement.date)
        ? movement.updatedAt
        : movement.date;
    stats[normalizedCandidate] = current == null
        ? _MovementTextSuggestionStats(
            text: cleaned,
            frequency: 1,
            latestActivity: latestActivity,
            startsWithQuery: startsWith,
            containsQuery: contains,
            sameType: sameType,
            sameCategory: sameCategory,
            sameBeneficiary: sameBeneficiary,
          )
        : current.merge(
            text: cleaned,
            latestActivity: latestActivity,
            startsWithQuery: startsWith,
            containsQuery: contains,
            sameType: sameType,
            sameCategory: sameCategory,
            sameBeneficiary: sameBeneficiary,
          );
  }

  final suggestions = stats.values.map((stats) => stats.toSuggestion()).toList()
    ..sort(_compareSuggestions);

  return suggestions.take(limit).toList();
}

List<MovementBeneficiarySuggestion> buildMovementBeneficiarySuggestions({
  required AppDatabase db,
  required String query,
  String? currentValue,
  int limit = 5,
}) {
  final normalizedQuery = normalizeMovementText(query);
  if (normalizedQuery.length < 2) {
    return const <MovementBeneficiarySuggestion>[];
  }

  final normalizedQueryCompact = normalizedQuery.replaceAll(' ', '');
  final normalizedQuerySkeleton = _skeleton(normalizedQuery);
  final currentKey = normalizeMovementText(currentValue ?? '');
  final stats = <String, _MovementBeneficiarySuggestionStats>{};

  void consider(String candidate, DateTime activity, {int weight = 1}) {
    final cleaned = candidate.trim();
    if (cleaned.isEmpty) return;

    final normalizedCandidate = normalizeMovementText(cleaned);
    if (normalizedCandidate.isEmpty ||
        normalizedCandidate == normalizedQuery ||
        normalizedCandidate == currentKey) {
      return;
    }

    final compactCandidate = normalizedCandidate.replaceAll(' ', '');
    final skeletonCandidate = _skeleton(normalizedCandidate);
    final directStartsWith =
        normalizedCandidate.startsWith(normalizedQuery) ||
        compactCandidate.startsWith(normalizedQueryCompact);
    final looseStartsWith =
        normalizedQuerySkeleton.isNotEmpty &&
        skeletonCandidate.startsWith(normalizedQuerySkeleton);
    final startsWith = directStartsWith || looseStartsWith;
    final directContains =
        normalizedCandidate.contains(normalizedQuery) ||
        compactCandidate.contains(normalizedQueryCompact);
    final looseContains =
        normalizedQuerySkeleton.isNotEmpty &&
        skeletonCandidate.contains(normalizedQuerySkeleton);
    final contains = directContains || looseContains;
    if (!startsWith && !contains) return;

    final current = stats[normalizedCandidate];
    stats[normalizedCandidate] = current == null
        ? _MovementBeneficiarySuggestionStats(
            text: cleaned,
            frequency: weight,
            latestActivity: activity,
            startsWithQuery: startsWith,
            containsQuery: contains,
          )
        : current.merge(
            text: cleaned,
            latestActivity: activity,
            weight: weight,
            startsWithQuery: startsWith,
            containsQuery: contains,
          );
  }

  for (final profile in db.beneficiaryProfiles) {
    if (profile.archived) continue;
    consider(
      profile.displayName,
      profile.updatedAt ?? profile.createdAt,
      weight: 3,
    );
  }

  for (final movement in db.movements) {
    final payee = movement.payee?.trim();
    if (payee == null || payee.isEmpty) continue;
    final activity = movement.updatedAt.isAfter(movement.date)
        ? movement.updatedAt
        : movement.date;
    consider(payee, activity);
  }

  final suggestions = stats.values.map((stats) => stats.toSuggestion()).toList()
    ..sort(_compareBeneficiarySuggestions);

  return suggestions.take(limit).toList();
}

int _compareSuggestions(MovementTextSuggestion a, MovementTextSuggestion b) {
  final startCmp = _boolRank(
    a.startsWithQuery,
  ).compareTo(_boolRank(b.startsWithQuery));
  if (startCmp != 0) return startCmp;

  final containsCmp = _boolRank(
    a.containsQuery,
  ).compareTo(_boolRank(b.containsQuery));
  if (containsCmp != 0) return containsCmp;

  final typeCmp = _boolRank(a.sameType).compareTo(_boolRank(b.sameType));
  if (typeCmp != 0) return typeCmp;

  final categoryCmp = _boolRank(
    a.sameCategory,
  ).compareTo(_boolRank(b.sameCategory));
  if (categoryCmp != 0) return categoryCmp;

  final beneficiaryCmp = _boolRank(
    a.sameBeneficiary,
  ).compareTo(_boolRank(b.sameBeneficiary));
  if (beneficiaryCmp != 0) return beneficiaryCmp;

  final latestCmp = b.latestActivity.compareTo(a.latestActivity);
  if (latestCmp != 0) return latestCmp;

  final frequencyCmp = b.frequency.compareTo(a.frequency);
  if (frequencyCmp != 0) return frequencyCmp;

  return a.text.toLowerCase().compareTo(b.text.toLowerCase());
}

int _boolRank(bool value) => value ? 0 : 1;

String _skeleton(String value) {
  return value
      .replaceAll(RegExp(r'[^a-z0-9]'), '')
      .replaceAll(RegExp(r'[aeiou]'), '');
}

class _MovementTextSuggestionStats {
  final String text;
  final int frequency;
  final DateTime latestActivity;
  final bool startsWithQuery;
  final bool containsQuery;
  final bool sameType;
  final bool sameCategory;
  final bool sameBeneficiary;

  const _MovementTextSuggestionStats({
    required this.text,
    required this.frequency,
    required this.latestActivity,
    required this.startsWithQuery,
    required this.containsQuery,
    required this.sameType,
    required this.sameCategory,
    required this.sameBeneficiary,
  });

  _MovementTextSuggestionStats merge({
    required String text,
    required DateTime latestActivity,
    required bool startsWithQuery,
    required bool containsQuery,
    required bool sameType,
    required bool sameCategory,
    required bool sameBeneficiary,
  }) {
    return _MovementTextSuggestionStats(
      text: this.text,
      frequency: frequency + 1,
      latestActivity: latestActivity.isAfter(this.latestActivity)
          ? latestActivity
          : this.latestActivity,
      startsWithQuery: this.startsWithQuery || startsWithQuery,
      containsQuery: this.containsQuery || containsQuery,
      sameType: this.sameType || sameType,
      sameCategory: this.sameCategory || sameCategory,
      sameBeneficiary: this.sameBeneficiary || sameBeneficiary,
    );
  }

  MovementTextSuggestion toSuggestion() {
    return MovementTextSuggestion(
      text: text,
      frequency: frequency,
      latestActivity: latestActivity,
      startsWithQuery: startsWithQuery,
      containsQuery: containsQuery,
      sameType: sameType,
      sameCategory: sameCategory,
      sameBeneficiary: sameBeneficiary,
    );
  }
}

int _compareBeneficiarySuggestions(
  MovementBeneficiarySuggestion a,
  MovementBeneficiarySuggestion b,
) {
  final startCmp = _boolRank(
    a.startsWithQuery,
  ).compareTo(_boolRank(b.startsWithQuery));
  if (startCmp != 0) return startCmp;

  final containsCmp = _boolRank(
    a.containsQuery,
  ).compareTo(_boolRank(b.containsQuery));
  if (containsCmp != 0) return containsCmp;

  final latestCmp = b.latestActivity.compareTo(a.latestActivity);
  if (latestCmp != 0) return latestCmp;

  final frequencyCmp = b.frequency.compareTo(a.frequency);
  if (frequencyCmp != 0) return frequencyCmp;

  return a.text.toLowerCase().compareTo(b.text.toLowerCase());
}

class _MovementBeneficiarySuggestionStats {
  final String text;
  final int frequency;
  final DateTime latestActivity;
  final bool startsWithQuery;
  final bool containsQuery;

  const _MovementBeneficiarySuggestionStats({
    required this.text,
    required this.frequency,
    required this.latestActivity,
    required this.startsWithQuery,
    required this.containsQuery,
  });

  _MovementBeneficiarySuggestionStats merge({
    required String text,
    required DateTime latestActivity,
    required int weight,
    required bool startsWithQuery,
    required bool containsQuery,
  }) {
    return _MovementBeneficiarySuggestionStats(
      text: this.text,
      frequency: frequency + weight,
      latestActivity: latestActivity.isAfter(this.latestActivity)
          ? latestActivity
          : this.latestActivity,
      startsWithQuery: this.startsWithQuery || startsWithQuery,
      containsQuery: this.containsQuery || containsQuery,
    );
  }

  MovementBeneficiarySuggestion toSuggestion() {
    return MovementBeneficiarySuggestion(
      text: text,
      frequency: frequency,
      latestActivity: latestActivity,
      startsWithQuery: startsWithQuery,
      containsQuery: containsQuery,
    );
  }
}

class MovementTextSuggestions extends StatelessWidget {
  final AppDatabase db;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final MovementTextSuggestionField field;
  final MovementType type;
  final String? categoryId;
  final String? beneficiary;
  final int limit;
  final ValueChanged<String>? onSelected;

  const MovementTextSuggestions({
    super.key,
    required this.db,
    required this.controller,
    this.focusNode,
    required this.field,
    required this.type,
    this.categoryId,
    this.beneficiary,
    this.limit = 5,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mergedListenable = Listenable.merge([controller, focusNode]);
    return ListenableBuilder(
      listenable: mergedListenable,
      builder: (context, _) {
        if (focusNode != null && !focusNode!.hasFocus) {
          return const SizedBox.shrink();
        }

        final suggestions = buildMovementTextSuggestions(
          db: db,
          query: controller.text,
          field: field,
          type: type,
          categoryId: categoryId,
          beneficiary: beneficiary,
          limit: limit,
        );
        if (suggestions.isEmpty) return const SizedBox.shrink();

        final title = field == MovementTextSuggestionField.title
            ? 'Suggerimenti titolo'
            : 'Suggerimenti note';

        return Padding(
          padding: const EdgeInsets.only(top: StreamSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: StreamTypography.caption.copyWith(
                  color: StreamColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: StreamSpacing.xs),
              Wrap(
                spacing: StreamSpacing.sm,
                runSpacing: StreamSpacing.sm,
                children: [
                  for (var i = 0; i < suggestions.length; i++)
                    ActionChip(
                      key: Key('movement_${field.name}_suggestion_$i'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.zero,
                      label: Text(
                        suggestions[i].text,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        controller.value = TextEditingValue(
                          text: suggestions[i].text,
                          selection: TextSelection.collapsed(
                            offset: suggestions[i].text.length,
                          ),
                        );
                        FocusManager.instance.primaryFocus?.unfocus();
                        onSelected?.call(suggestions[i].text);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class MovementBeneficiarySuggestions extends StatelessWidget {
  final AppDatabase db;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int limit;
  final ValueChanged<String>? onSelected;

  const MovementBeneficiarySuggestions({
    super.key,
    required this.db,
    required this.controller,
    this.focusNode,
    this.limit = 5,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final mergedListenable = Listenable.merge([controller, focusNode]);
    return ListenableBuilder(
      listenable: mergedListenable,
      builder: (context, _) {
        if (focusNode != null && !focusNode!.hasFocus) {
          return const SizedBox.shrink();
        }

        final suggestions = buildMovementBeneficiarySuggestions(
          db: db,
          query: controller.text,
          currentValue: controller.text,
          limit: limit,
        );
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: StreamSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggerimenti beneficiario',
                style: StreamTypography.caption.copyWith(
                  color: StreamColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: StreamSpacing.xs),
              Wrap(
                spacing: StreamSpacing.sm,
                runSpacing: StreamSpacing.sm,
                children: [
                  for (var i = 0; i < suggestions.length; i++)
                    ActionChip(
                      key: Key('movement_beneficiary_suggestion_$i'),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      padding: EdgeInsets.zero,
                      label: Text(
                        suggestions[i].text,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        controller.value = TextEditingValue(
                          text: suggestions[i].text,
                          selection: TextSelection.collapsed(
                            offset: suggestions[i].text.length,
                          ),
                        );
                        FocusManager.instance.primaryFocus?.unfocus();
                        onSelected?.call(suggestions[i].text);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
