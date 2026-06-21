import 'package:flutter/material.dart';

import '../design/stream_theme_extension.dart';
import '../theme.dart';
import 'calculator_amount_pad.dart';

typedef MovementPadDateTap = Future<void> Function();

class MovementCalculatorPad extends StatefulWidget {
  final TextEditingController controller;
  final MovementPadDateTap? onDateTap;
  final bool allowNegative;
  final AmountExpressionEvaluator evaluator;

  const MovementCalculatorPad({
    super.key,
    required this.controller,
    this.onDateTap,
    this.allowNegative = false,
    this.evaluator = const AmountExpressionEvaluator(),
  });

  @override
  State<MovementCalculatorPad> createState() => _MovementCalculatorPadState();
}

class _MovementCalculatorPadState extends State<MovementCalculatorPad> {
  String? _error;

  void _write(String value) {
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  void _append(String value) {
    setState(() => _error = null);
    final current = widget.controller.text;
    final isDigit = RegExp(r'^\d+$').hasMatch(value);
    if (current == '0' && isDigit) {
      _write(value);
      return;
    }
    _write('$current$value');
  }

  void _backspace() {
    if (widget.controller.text.isEmpty) return;
    setState(() => _error = null);
    final next = widget.controller.text.substring(
      0,
      widget.controller.text.length - 1,
    );
    _write(next);
  }

  void _toggleSign() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      _append('-');
      return;
    }
    if (text.startsWith('-')) {
      _write(text.substring(1));
    } else {
      _write('-$text');
    }
  }

  void _applyPercent() {
    final result = widget.evaluator.evaluate(
      widget.controller.text,
      allowNegative: true,
    );
    if (!result.isValid || result.value == null) {
      setState(() => _error = result.error ?? 'Espressione non valida');
      return;
    }
    setState(() => _error = null);
    _write(formatAmountExpressionValue(result.value! / 100));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.$palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          const SizedBox(height: StreamSpacing.sm),
          Text(
            _error!,
            key: const Key('movement_calculator_error'),
            style: StreamTypography.caption.copyWith(color: p.warning),
          ),
        ],
        const SizedBox(height: StreamSpacing.md),
        _row([
          _PadSpec.text('7'),
          _PadSpec.text('8'),
          _PadSpec.text('9'),
          _PadSpec.icon(
            key: 'movement_pad_backspace',
            icon: Icons.backspace_outlined,
            onTap: () async => _backspace(),
            tinted: true,
          ),
        ]),
        _row([
          _PadSpec.text('4'),
          _PadSpec.text('5'),
          _PadSpec.text('6'),
          _PadSpec.text('/', operator: true),
        ]),
        _row([
          _PadSpec.text('1'),
          _PadSpec.text('2'),
          _PadSpec.text('3'),
          _PadSpec.text('*', operator: true),
        ]),
        _row([
          _PadSpec.text(','),
          _PadSpec.text('0'),
          _PadSpec.text('00'),
          _PadSpec.text('-', operator: true),
        ]),
        _row([
          _PadSpec.icon(
            key: 'movement_pad_calendar',
            icon: Icons.calendar_today_outlined,
            onTap: () async => widget.onDateTap?.call(),
            tinted: true,
          ),
          _PadSpec.text(
            '+/-',
            key: 'movement_pad_sign',
            onTap: () async => _toggleSign(),
            tinted: true,
          ),
          _PadSpec.text(
            '%',
            key: 'movement_pad_percent',
            onTap: () async => _applyPercent(),
            tinted: true,
          ),
          _PadSpec.text('+', operator: true, tinted: true),
        ]),
      ],
    );
  }

  Widget _row(List<_PadSpec> specs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0) const SizedBox(width: StreamSpacing.sm),
            Expanded(child: _buildButton(specs[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildButton(_PadSpec spec) {
    final p = context.$palette;
    final background = spec.operator
        ? p.primary.withValues(
            alpha: p.brightness == Brightness.light ? 0.14 : 0.2,
          )
        : spec.tinted
        ? p.surfaceElevated
        : p.surface;
    final foreground = spec.operator ? p.primary : p.textPrimary;
    return SizedBox(
      height: 56,
      child: FilledButton(
        key: Key(spec.key),
        onPressed: () async {
          final callback = spec.onTap;
          if (callback != null) {
            await callback();
            return;
          }
          _append(spec.label!);
        },
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StreamRadius.md),
          ),
          side: BorderSide(
            color: spec.operator ? p.primary.withValues(alpha: 0.4) : p.divider,
          ),
          padding: EdgeInsets.zero,
        ),
        child: spec.icon != null
            ? Icon(spec.icon, size: 22)
            : Text(spec.label!, style: StreamTypography.h2),
      ),
    );
  }
}

class _PadSpec {
  final String key;
  final String? label;
  final IconData? icon;
  final Future<void> Function()? onTap;
  final bool operator;
  final bool tinted;

  const _PadSpec._({
    required this.key,
    this.label,
    this.icon,
    this.onTap,
    this.operator = false,
    this.tinted = false,
  });

  factory _PadSpec.text(
    String label, {
    String? key,
    Future<void> Function()? onTap,
    bool operator = false,
    bool tinted = false,
  }) {
    return _PadSpec._(
      key: key ?? 'movement_pad_$label',
      label: label,
      onTap: onTap,
      operator: operator,
      tinted: tinted,
    );
  }

  factory _PadSpec.icon({
    required String key,
    required IconData icon,
    required Future<void> Function()? onTap,
    bool tinted = false,
  }) {
    return _PadSpec._(key: key, icon: icon, onTap: onTap, tinted: tinted);
  }
}
