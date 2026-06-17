import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme.dart';

class AmountExpressionResult {
  final double? value;
  final String? error;

  const AmountExpressionResult._({this.value, this.error});

  bool get isValid => value != null && error == null;

  factory AmountExpressionResult.success(double value) =>
      AmountExpressionResult._(value: value);

  factory AmountExpressionResult.failure(String error) =>
      AmountExpressionResult._(error: error);
}

class AmountExpressionEvaluator {
  const AmountExpressionEvaluator();

  AmountExpressionResult evaluate(String input, {bool allowNegative = false}) {
    final tokens = _tokenize(input);
    if (tokens.isEmpty) {
      return AmountExpressionResult.success(0);
    }
    if (_isOperator(tokens.last)) {
      return AmountExpressionResult.failure('Espressione incompleta');
    }

    final values = <double>[];
    final operators = <String>[];

    void applyOperator() {
      if (values.length < 2 || operators.isEmpty) {
        throw const FormatException('Espressione non valida');
      }
      final right = values.removeLast();
      final left = values.removeLast();
      final operator = operators.removeLast();
      final result = switch (operator) {
        '+' => left + right,
        '-' => left - right,
        '*' => left * right,
        '/' || ':' =>
          right == 0
              ? throw UnsupportedError('Divisione per zero')
              : left / right,
        _ => throw const FormatException('Operatore non valido'),
      };
      values.add(result);
    }

    try {
      for (final token in tokens) {
        if (_isOperator(token)) {
          while (operators.isNotEmpty &&
              _precedence(operators.last) >= _precedence(token)) {
            applyOperator();
          }
          operators.add(token);
        } else {
          values.add(double.parse(token));
        }
      }
      while (operators.isNotEmpty) {
        applyOperator();
      }
      if (values.length != 1) {
        return AmountExpressionResult.failure('Espressione non valida');
      }
      final value = values.single;
      if (value.isNaN || value.isInfinite) {
        return AmountExpressionResult.failure('Risultato non valido');
      }
      if (!allowNegative && value < 0) {
        return AmountExpressionResult.failure('Importo negativo non valido');
      }
      return AmountExpressionResult.success(value);
    } on UnsupportedError {
      return AmountExpressionResult.failure('Divisione per zero');
    } on FormatException {
      return AmountExpressionResult.failure('Espressione non valida');
    }
  }

  List<String> _tokenize(String input) {
    final normalized = input
        .replaceAll(',', '.')
        .replaceAll('÷', '/')
        .replaceAll(RegExp(r'\s+'), '');
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (var i = 0; i < normalized.length; i++) {
      final char = normalized[i];
      final unaryMinus =
          char == '-' &&
          buffer.isEmpty &&
          (tokens.isEmpty || _isOperator(tokens.last));
      if (_isDigit(char) || char == '.' || unaryMinus) {
        buffer.write(char);
        continue;
      }
      if (_isOperator(char)) {
        if (buffer.isEmpty) {
          return const [];
        }
        tokens.add(buffer.toString());
        buffer.clear();
        tokens.add(char);
        continue;
      }
      return const [];
    }
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }
    return tokens;
  }

  bool _isDigit(String value) => RegExp(r'\d').hasMatch(value);

  bool _isOperator(String value) =>
      value == '+' ||
      value == '-' ||
      value == '*' ||
      value == '/' ||
      value == ':';

  int _precedence(String operator) =>
      operator == '*' || operator == '/' || operator == ':' ? 2 : 1;
}

class CalculatorAmountField extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final bool allowNegative;
  final ValueChanged<String>? onChanged;
  final Key? fieldKey;

  const CalculatorAmountField({
    super.key,
    required this.controller,
    required this.decoration,
    this.allowNegative = false,
    this.onChanged,
    this.fieldKey,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      decoration: decoration,
      readOnly: true,
      showCursor: false,
      keyboardType: TextInputType.none,
      onChanged: onChanged,
      onTap: () => _showPad(context),
    );
  }

  Future<void> _showPad(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CalculatorAmountPad(
        controller: controller,
        allowNegative: allowNegative,
        onChanged: onChanged,
      ),
    );
  }
}

class CalculatorAmountPad extends StatefulWidget {
  final TextEditingController controller;
  final bool allowNegative;
  final ValueChanged<String>? onChanged;
  final AmountExpressionEvaluator evaluator;

  const CalculatorAmountPad({
    super.key,
    required this.controller,
    this.allowNegative = false,
    this.onChanged,
    this.evaluator = const AmountExpressionEvaluator(),
  });

  @override
  State<CalculatorAmountPad> createState() => _CalculatorAmountPadState();
}

class _CalculatorAmountPadState extends State<CalculatorAmountPad> {
  String? _error;

  void _write(String value) {
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged?.call(value);
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
    setState(() => _error = null);
    final text = widget.controller.text;
    if (text.isEmpty) return;
    _write(text.substring(0, text.length - 1));
  }

  void _clear() {
    setState(() => _error = null);
    _write('');
  }

  bool _calculate() {
    final result = widget.evaluator.evaluate(
      widget.controller.text,
      allowNegative: widget.allowNegative,
    );
    if (!result.isValid) {
      setState(() => _error = result.error);
      return false;
    }
    setState(() => _error = null);
    _write(formatAmountExpressionValue(result.value!));
    return true;
  }

  void _done() {
    if (widget.controller.text.trim().isNotEmpty && !_calculate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        StreamSpacing.lg,
        StreamSpacing.lg,
        StreamSpacing.lg,
        math.max(bottomInset, StreamSpacing.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('calculator_amount_display'),
            padding: const EdgeInsets.all(StreamSpacing.md),
            decoration: BoxDecoration(
              color: StreamColors.surfaceElevated,
              borderRadius: BorderRadius.circular(StreamRadius.md),
            ),
            child: Text(
              widget.controller.text.isEmpty ? '0' : widget.controller.text,
              textAlign: TextAlign.right,
              style: StreamTypography.h2,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: StreamSpacing.sm),
            Text(
              _error!,
              key: const Key('calculator_amount_error'),
              style: StreamTypography.caption.copyWith(
                color: StreamColors.warning,
              ),
            ),
          ],
          const SizedBox(height: StreamSpacing.md),
          _row(['7', '8', '9', '/']),
          _row(['4', '5', '6', '*']),
          _row(['1', '2', '3', '-']),
          _row(['0', '.', ':', '+']),
          Row(
            children: [
              Expanded(child: _button('C', _clear, key: 'calculator_clear')),
              const SizedBox(width: StreamSpacing.sm),
              Expanded(
                child: _button('⌫', _backspace, key: 'calculator_backspace'),
              ),
              const SizedBox(width: StreamSpacing.sm),
              Expanded(
                child: _button('=', _calculate, key: 'calculator_equals'),
              ),
              const SizedBox(width: StreamSpacing.sm),
              Expanded(
                child: _button(
                  'Fatto',
                  _done,
                  key: 'calculator_done',
                  emphasized: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: StreamSpacing.sm),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: StreamSpacing.sm),
            Expanded(
              child: _button(
                values[i],
                () => _append(values[i]),
                key: 'calculator_key_${values[i]}',
                operator: '+-*/:'.contains(values[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _button(
    String label,
    VoidCallback onPressed, {
    required String key,
    bool emphasized = false,
    bool operator = false,
  }) {
    final background = emphasized
        ? StreamColors.primary
        : operator
        ? StreamColors.surfaceHighlight
        : StreamColors.surfaceElevated;
    return SizedBox(
      height: 48,
      child: FilledButton(
        key: Key(key),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StreamRadius.md),
          ),
        ),
        child: Text(label, style: StreamTypography.bodyBold),
      ),
    );
  }
}

String formatAmountExpressionValue(double value) {
  final rounded = double.parse(value.toStringAsFixed(2));
  if (rounded == rounded.truncateToDouble()) {
    return rounded.toStringAsFixed(0);
  }
  return rounded.toStringAsFixed(2);
}
