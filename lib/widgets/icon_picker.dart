import 'package:flutter/material.dart';
import '../design/stream_icon_library.dart';
import '../theme.dart';

class IconPickerDialog extends StatefulWidget {
  final String currentIconKey;
  final bool isAccount;

  const IconPickerDialog({
    super.key,
    required this.currentIconKey,
    this.isAccount = false,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late String _selectedIconKey;
  late TextEditingController _searchCtrl;
  late List<StreamIconGroup> _allGroups;
  List<StreamIconGroup> _filteredGroups = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIconKey = widget.currentIconKey;
    _searchCtrl = TextEditingController();
    _allGroups = widget.isAccount
        ? StreamIconLibrary.accountIconGroupsList
        : StreamIconLibrary.categoryIconGroupsList;
    _filteredGroups = _allGroups;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredGroups = _allGroups;
      } else {
        _filteredGroups = [];
        for (final group in _allGroups) {
          final matching = group.entries.where((e) =>
              e.key.toLowerCase().contains(_searchQuery) ||
              e.label.toLowerCase().contains(_searchQuery) ||
              group.name.toLowerCase().contains(_searchQuery)).toList();
          if (matching.isNotEmpty) {
            _filteredGroups.add(StreamIconGroup(group.name, matching));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconData = widget.isAccount
        ? StreamIconLibrary.getAccountIcon(_selectedIconKey)
        : StreamIconLibrary.getIcon(_selectedIconKey);
    final label = widget.isAccount
        ? StreamIconLibrary.getAccountLabel(_selectedIconKey)
        : StreamIconLibrary.getLabel(_selectedIconKey);

    return AlertDialog(
      title: const Text('Scegli icona'),
      content: SizedBox(
        width: double.maxFinite,
        height: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(StreamSpacing.md),
              decoration: BoxDecoration(
                color: StreamColors.surface,
                borderRadius: BorderRadius.circular(StreamRadius.md),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconData, size: 28, color: Colors.white),
                  const SizedBox(width: StreamSpacing.md),
                  Text(label, style: StreamTypography.bodyBold),
                ],
              ),
            ),
            const SizedBox(height: StreamSpacing.md),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cerca icona o gruppo...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
              textInputAction: TextInputAction.done,
              onChanged: _onSearch,
            ),
            const SizedBox(height: StreamSpacing.md),
            Expanded(
              child: ListView(
                children: [
                  for (final group in _filteredGroups) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        top: 8,
                        bottom: 4,
                      ),
                      child: Text(
                        group.name,
                        style: StreamTypography.captionBold.copyWith(
                          color: StreamColors.primary,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                        childAspectRatio: 1,
                      ),
                      itemCount: group.entries.length,
                      itemBuilder: (context, index) {
                        final entry = group.entries[index];
                        final isSelected = entry.key == _selectedIconKey;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedIconKey = entry.key);
                            Navigator.of(context).pop(_selectedIconKey);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? StreamColors.primary.withValues(alpha: 0.2)
                                  : StreamColors.surface,
                              borderRadius:
                                  BorderRadius.circular(StreamRadius.sm),
                              border: isSelected
                                  ? Border.all(
                                      color: StreamColors.primary, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(entry.icon,
                                    size: 20,
                                    color: isSelected
                                        ? StreamColors.primary
                                        : StreamColors.textSecondary),
                                const SizedBox(height: 2),
                                Text(
                                  entry.label,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isSelected
                                        ? StreamColors.primary
                                        : StreamColors.textMuted,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
      ],
    );
  }
}

class ColorPicker extends StatelessWidget {
  final int currentColor;
  final ValueChanged<int> onChanged;

  const ColorPicker({
    super.key,
    required this.currentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: StreamColorPalette.colors.map((c) => GestureDetector(
        onTap: () => onChanged(c),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(c),
            shape: BoxShape.circle,
            border: currentColor == c
                ? Border.all(color: Colors.white, width: 3)
                : null,
          ),
        ),
      )).toList(),
    );
  }
}
