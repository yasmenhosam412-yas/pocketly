import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Bottom sheet to create or verify a 4-digit PIN.
Future<String?> showAppLockPinSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  bool isConfirmation = false,
  String? expectedPin,
  bool dismissible = true,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AppLockPinSheet(
      title: title,
      subtitle: subtitle,
      isConfirmation: isConfirmation,
      expectedPin: expectedPin,
      dismissible: dismissible,
    ),
  );
}

class _AppLockPinSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isConfirmation;
  final String? expectedPin;
  final bool dismissible;

  const _AppLockPinSheet({
    required this.title,
    required this.subtitle,
    required this.isConfirmation,
    this.expectedPin,
    this.dismissible = true,
  });

  @override
  State<_AppLockPinSheet> createState() => _AppLockPinSheetState();
}

class _AppLockPinSheetState extends State<_AppLockPinSheet> {
  String _pin = '';
  bool _showError = false;

  void _onDigit(String digit) {
    if (_pin.length >= AppLockService.pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _showError = false;
      _pin += digit;
    });
    if (_pin.length == AppLockService.pinLength) {
      _finish();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _showError = false;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _finish() {
    final l10n = AppLocalizations.of(context)!;
    if (widget.isConfirmation) {
      if (_pin == widget.expectedPin) {
        Navigator.pop(context, _pin);
        return;
      }
      HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _showError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appLockPinMismatch),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pop(context, _pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textColor.withValues(alpha: 0.6),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            _PinDots(
              length: AppLockService.pinLength,
              filled: _pin.length,
              showError: _showError,
            ),
            const SizedBox(height: 28),
            _PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
            if (widget.dismissible) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  final int length;
  final int filled;
  final bool showError;

  const _PinDots({
    required this.length,
    required this.filled,
    required this.showError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isFilled = index < filled;
        final color = showError
            ? AppColors.errorColor
            : isFilled
                ? AppColors.primaryInk
                : AppColors.border;

        return Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
          ),
        );
      }),
    );
  }
}

class _PinKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _PinKeypad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        for (final row in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: row
                  .map(
                    (d) => Expanded(
                      child: _KeyButton(label: d, onTap: () => onDigit(d)),
                    ),
                  )
                  .toList(),
            ),
          ),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(child: _KeyButton(label: '0', onTap: () => onDigit('0'))),
            Expanded(
              child: _KeyButton(
                icon: Icons.backspace_outlined,
                onTap: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeyButton({this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 64,
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    )
                  : Icon(icon, size: 24, color: AppColors.textColor),
            ),
          ),
        ),
      ),
    );
  }
}
