import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String? _storedValue;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _onDigit(String digit) {
    setState(() {
      if (_shouldResetDisplay || _display == '0') {
        _display = digit == '.' ? '0.' : digit;
        _shouldResetDisplay = false;
        return;
      }
      if (digit == '.' && _display.contains('.')) return;
      _display += digit;
    });
  }

  void _onOperator(String op) {
    setState(() {
      if (_storedValue != null &&
          _operator != null &&
          !_shouldResetDisplay) {
        _compute();
      } else {
        _storedValue = _display;
      }
      _operator = op;
      _shouldResetDisplay = true;
    });
  }

  void _onEquals() {
    setState(() {
      if (_storedValue == null || _operator == null) return;
      _compute();
      _operator = null;
      _storedValue = null;
      _shouldResetDisplay = true;
    });
  }

  void _compute() {
    final a = double.tryParse(_storedValue ?? '') ?? 0;
    final b = double.tryParse(_display) ?? 0;
    double result;
    switch (_operator) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '×':
        result = a * b;
        break;
      case '÷':
        result = b == 0 ? 0 : a / b;
        break;
      default:
        return;
    }
    _display = _formatResult(result);
    _storedValue = _display;
  }

  String _formatResult(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e12) {
      return value.round().toString();
    }
    final text = value.toStringAsFixed(8);
    return text
        .replaceFirst(RegExp(r'\.?0+$'), '')
        .replaceAll(RegExp(r'(\.\d*?)0+$'), r'$1');
  }

  void _clear() {
    setState(() {
      _display = '0';
      _storedValue = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  void _backspace() {
    setState(() {
      if (_shouldResetDisplay) return;
      if (_display.length <= 1) {
        _display = '0';
        return;
      }
      _display = _display.substring(0, _display.length - 1);
    });
  }

  void _toggleSign() {
    setState(() {
      if (_display == '0') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _percent() {
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      _display = _formatResult(value / 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expression = _operator != null && _storedValue != null
        ? '${_storedValue!} $_operator'
        : null;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.calculatorTitle,
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (expression != null)
                      Text(
                        expression,
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.textColor.withValues(alpha: 0.45),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        _display,
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _CalcRow(
                    children: [
                      _CalcKey(
                        label: 'C',
                        onTap: _clear,
                        background: AppColors.surface,
                      ),
                      _CalcKey(
                        label: '⌫',
                        onTap: _backspace,
                        background: AppColors.surface,
                      ),
                      _CalcKey(
                        label: '%',
                        onTap: _percent,
                        background: AppColors.surface,
                      ),
                      _CalcKey(
                        label: '÷',
                        onTap: () => _onOperator('÷'),
                        background: AppColors.primary,
                        foreground: Colors.white,
                      ),
                    ],
                  ),
                  _CalcRow(
                    children: [
                      _CalcKey(label: '7', onTap: () => _onDigit('7')),
                      _CalcKey(label: '8', onTap: () => _onDigit('8')),
                      _CalcKey(label: '9', onTap: () => _onDigit('9')),
                      _CalcKey(
                        label: '×',
                        onTap: () => _onOperator('×'),
                        background: AppColors.primary,
                        foreground: Colors.white,
                      ),
                    ],
                  ),
                  _CalcRow(
                    children: [
                      _CalcKey(label: '4', onTap: () => _onDigit('4')),
                      _CalcKey(label: '5', onTap: () => _onDigit('5')),
                      _CalcKey(label: '6', onTap: () => _onDigit('6')),
                      _CalcKey(
                        label: '−',
                        onTap: () => _onOperator('-'),
                        background: AppColors.primary,
                        foreground: Colors.white,
                      ),
                    ],
                  ),
                  _CalcRow(
                    children: [
                      _CalcKey(label: '1', onTap: () => _onDigit('1')),
                      _CalcKey(label: '2', onTap: () => _onDigit('2')),
                      _CalcKey(label: '3', onTap: () => _onDigit('3')),
                      _CalcKey(
                        label: '+',
                        onTap: () => _onOperator('+'),
                        background: AppColors.primary,
                        foreground: Colors.white,
                      ),
                    ],
                  ),
                  _CalcRow(
                    children: [
                      _CalcKey(
                        label: '+/−',
                        onTap: _toggleSign,
                        flex: 1,
                      ),
                      _CalcKey(
                        label: '0',
                        onTap: () => _onDigit('0'),
                        flex: 1,
                      ),
                      _CalcKey(
                        label: '.',
                        onTap: () => _onDigit('.'),
                        flex: 1,
                      ),
                      _CalcKey(
                        label: '=',
                        onTap: _onEquals,
                        background: AppColors.balance,
                        foreground: Colors.white,
                        flex: 1,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcRow extends StatelessWidget {
  final List<Widget> children;

  const _CalcRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _CalcKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? background;
  final Color? foreground;
  final int flex;

  const _CalcKey({
    required this.label,
    required this.onTap,
    this.background,
    this.foreground,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.15,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label.length > 1 ? 20 : 26,
                fontWeight: FontWeight.w600,
                color: foreground ?? AppColors.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
