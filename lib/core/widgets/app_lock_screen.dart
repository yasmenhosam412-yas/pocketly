import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imrpo/core/services/app_lock_service.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _pin = '';
  bool _isVerifying = false;
  bool _showError = false;
  bool _biometricAttempted = false;

  AppLockService get _lock => getIt<AppLockService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (_biometricAttempted || !_lock.biometricEnabled) return;
    _biometricAttempted = true;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isVerifying = true);
    final ok = await _lock.unlockWithBiometric(
      localizedReason: l10n.appLockBiometricReason,
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);
    if (!ok) {
      setState(() => _showError = false);
    }
  }

  void _onDigit(String digit) {
    if (_isVerifying || _pin.length >= AppLockService.pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _showError = false;
      _pin += digit;
    });
    if (_pin.length == AppLockService.pinLength) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_isVerifying || _pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _showError = false;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submitPin() async {
    setState(() => _isVerifying = true);
    final ok = await _lock.unlockWithPin(_pin);
    if (!mounted) return;

    if (ok) {
      setState(() {
        _pin = '';
        _isVerifying = false;
        _showError = false;
      });
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      _pin = '';
      _isVerifying = false;
      _showError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: AppColors.scaffold,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.appLockTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appLockSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),
              _PinDots(
                length: AppLockService.pinLength,
                filled: _pin.length,
                showError: _showError,
              ),
              if (_showError) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.appLockWrongPin,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorColor,
                  ),
                ),
              ],
              const Spacer(flex: 3),
              if (_isVerifying)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              else
                _PinKeypad(
                  onDigit: _onDigit,
                  onBackspace: _onBackspace,
                  onBiometric: _lock.biometricEnabled && _lock.canUseBiometrics
                      ? () {
                          _biometricAttempted = false;
                          _tryBiometric();
                        }
                      : null,
                  biometricIcon: _lock.supportsFace
                      ? Icons.face_rounded
                      : Icons.fingerprint_rounded,
                ),
              const SizedBox(height: 16),
            ],
          ),
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
                ? AppColors.primary
                : AppColors.border;

        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 10),
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
  final VoidCallback? onBiometric;
  final IconData biometricIcon;

  const _PinKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.onBiometric,
    this.biometricIcon = Icons.fingerprint_rounded,
  });

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
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: row
                  .map((d) => Expanded(child: _KeyButton(label: d, onTap: () => onDigit(d))))
                  .toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: onBiometric != null
                    ? _KeyButton(
                        icon: biometricIcon,
                        onTap: onBiometric!,
                      )
                    : const SizedBox(),
              ),
              Expanded(child: _KeyButton(label: '0', onTap: () => onDigit('0'))),
              Expanded(
                child: _KeyButton(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _KeyButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Material(
        color: AppColors.card,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 72,
            child: Center(
              child: label != null
                  ? Text(
                      label!,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    )
                  : Icon(icon, size: 28, color: AppColors.textColor),
            ),
          ),
        ),
      ),
    );
  }
}
