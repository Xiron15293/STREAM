import 'package:flutter/material.dart';

import '../data/database.dart';
import '../design/stream_icon_library.dart';
import '../models/beneficiary_profile.dart';
import '../theme.dart';
import '../widgets/icon_picker.dart';

enum SaveBeneficiaryDecision { cancel, movementOnly, saveBeneficiary }

Future<SaveBeneficiaryDecision> askToSaveBeneficiary(
  BuildContext context,
  AppDatabase db,
  String? payee,
) async {
  final cleaned = db.cleanBeneficiaryName(payee);
  if (cleaned.isEmpty) return SaveBeneficiaryDecision.movementOnly;

  final key = BeneficiaryProfile.normalizeKey(cleaned);
  if (db.hasBeneficiaryProfile(key)) {
    return SaveBeneficiaryDecision.movementOnly;
  }

  final similarProfiles = findSimilarBeneficiaryProfiles(db, cleaned);

  final decision = await showDialog<SaveBeneficiaryDecision>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Vuoi salvare questo beneficiario?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Puoi salvare "$cleaned" come beneficiario per riutilizzare nome, icona e colore.',
              ),
              if (similarProfiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Beneficiari simili già presenti:',
                  style: Theme.of(dialogContext).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: similarProfiles
                      .map(
                        (profile) => Chip(
                          label: Text(profile.displayName),
                          avatar: CircleAvatar(
                            backgroundColor: Color(profile.color),
                            child: Icon(
                              StreamIconLibrary.getIcon(profile.iconKey),
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(SaveBeneficiaryDecision.cancel);
            },
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(SaveBeneficiaryDecision.movementOnly);
            },
            child: const Text('No, solo movimento'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(
                dialogContext,
              ).pop(SaveBeneficiaryDecision.saveBeneficiary);
            },
            child: const Text('Salva beneficiario'),
          ),
        ],
      );
    },
  );

  return decision ?? SaveBeneficiaryDecision.cancel;
}

List<BeneficiaryProfile> findSimilarBeneficiaryProfiles(
  AppDatabase db,
  String rawName, {
  int limit = 3,
}) {
  final cleaned = db.cleanBeneficiaryName(rawName);
  if (cleaned.isEmpty) return const <BeneficiaryProfile>[];

  final normalized = BeneficiaryProfile.normalizeKey(cleaned);
  if (normalized.isEmpty) return const <BeneficiaryProfile>[];

  final scored = <({BeneficiaryProfile profile, double score})>[];
  for (final profile in db.beneficiaryProfiles) {
    if (profile.key == normalized) continue;
    final score = _beneficiarySimilarity(normalized, profile.key);
    if (score >= 0.55) {
      scored.add((profile: profile, score: score));
    }
  }

  scored.sort((a, b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return a.profile.displayName.compareTo(b.profile.displayName);
  });

  return scored.take(limit).map((entry) => entry.profile).toList();
}

double _beneficiarySimilarity(String left, String right) {
  final a = left.replaceAll(' ', '');
  final b = right.replaceAll(' ', '');
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 1;

  final maxLength = a.length > b.length ? a.length : b.length;
  final distance = _levenshteinDistance(a, b);
  final baseScore = 1 - (distance / maxLength);
  final tokensA = left.split(' ').where((token) => token.isNotEmpty).toSet();
  final tokensB = right.split(' ').where((token) => token.isNotEmpty).toSet();
  final sharedTokens = tokensA
      .intersection(tokensB)
      .where((token) => token.length > 4);
  if (sharedTokens.isNotEmpty) {
    return baseScore + 0.18;
  }
  if (a.startsWith(b) || b.startsWith(a) || a.contains(b) || b.contains(a)) {
    return baseScore + 0.08;
  }
  return baseScore;
}

int _levenshteinDistance(String left, String right) {
  if (left.isEmpty) return right.length;
  if (right.isEmpty) return left.length;

  final previous = List<int>.generate(right.length + 1, (index) => index);
  final current = List<int>.filled(right.length + 1, 0);

  for (var i = 0; i < left.length; i++) {
    current[0] = i + 1;
    for (var j = 0; j < right.length; j++) {
      final cost = left[i] == right[j] ? 0 : 1;
      current[j + 1] = [
        current[j] + 1,
        previous[j + 1] + 1,
        previous[j] + cost,
      ].reduce((a, b) => a < b ? a : b);
    }
    for (var j = 0; j < previous.length; j++) {
      previous[j] = current[j];
    }
  }

  return previous[right.length];
}

Future<BeneficiaryProfile?> showCreateBeneficiaryDialog(
  BuildContext context,
  AppDatabase db,
) async {
  return showDialog<BeneficiaryProfile?>(
    context: context,
    builder: (dialogContext) => _CreateBeneficiaryDialog(db: db),
  );
}

class _CreateBeneficiaryDialog extends StatefulWidget {
  final AppDatabase db;

  const _CreateBeneficiaryDialog({required this.db});

  @override
  State<_CreateBeneficiaryDialog> createState() =>
      _CreateBeneficiaryDialogState();
}

class _CreateBeneficiaryDialogState extends State<_CreateBeneficiaryDialog> {
  late final TextEditingController _nameCtrl;
  String _selectedIconKey = BeneficiaryProfile.defaultIconKey;
  int _selectedColor = StreamColorPalette.defaultColor;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final iconKey = await showDialog<String>(
      context: context,
      builder: (_) =>
          IconPickerDialog(currentIconKey: _selectedIconKey, isAccount: false),
    );
    if (!mounted || iconKey == null) return;
    setState(() => _selectedIconKey = iconKey);
  }

  Future<void> _pickColor() async {
    final color = await showDialog<int>(
      context: context,
      builder: (colorContext) {
        var draftColor = _selectedColor;
        return AlertDialog(
          title: const Text('Scegli colore'),
          content: StatefulBuilder(
            builder: (context, setInnerState) {
              return SingleChildScrollView(
                child: ColorPicker(
                  currentColor: draftColor,
                  onChanged: (value) {
                    setInnerState(() => draftColor = value);
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(colorContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(colorContext).pop(draftColor),
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );
    if (!mounted || color == null) return;
    setState(() => _selectedColor = color);
  }

  Future<void> _submit() async {
    final cleaned = widget.db.cleanBeneficiaryName(_nameCtrl.text);
    final key = BeneficiaryProfile.normalizeKey(cleaned);

    if (cleaned.isEmpty) {
      setState(() => _errorText = 'Inserisci un nome beneficiario');
      return;
    }
    if (widget.db.hasBeneficiaryProfile(key)) {
      setState(() => _errorText = 'Esiste già un beneficiario con questo nome');
      return;
    }

    final profile = await widget.db.createManualBeneficiaryProfile(
      cleaned,
      iconKey: _selectedIconKey,
      color: _selectedColor,
    );
    if (!mounted) return;
    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuovo beneficiario'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('beneficiary_name_field'),
                controller: _nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  if (_errorText != null) {
                    setState(() => _errorText = null);
                  }
                },
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Nome beneficiario',
                  errorText: _errorText,
                ),
              ),
              const SizedBox(height: StreamSpacing.md),
              Container(
                padding: const EdgeInsets.all(StreamSpacing.md),
                decoration: BoxDecoration(
                  color: StreamColors.surface,
                  borderRadius: BorderRadius.circular(StreamRadius.md),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(_selectedColor),
                        borderRadius: BorderRadius.circular(StreamRadius.md),
                      ),
                      child: Icon(
                        StreamIconLibrary.getIcon(_selectedIconKey),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: StreamSpacing.md),
                    Expanded(
                      child: Text(
                        'Anteprima beneficiario',
                        style: StreamTypography.bodyBold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: StreamSpacing.md),
              Wrap(
                spacing: StreamSpacing.sm,
                runSpacing: StreamSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    key: const Key('beneficiary_pick_icon_button'),
                    onPressed: _pickIcon,
                    icon: const Icon(Icons.face),
                    label: const Text('Icona'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('beneficiary_pick_color_button'),
                    onPressed: _pickColor,
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Colore'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          key: const Key('beneficiary_create_confirm_button'),
          onPressed: _submit,
          child: const Text('Crea'),
        ),
      ],
    );
  }
}
