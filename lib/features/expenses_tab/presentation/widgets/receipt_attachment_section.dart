import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/core/utils/receipt_image_validator.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class ReceiptAttachmentSection extends StatelessWidget {
  final File? localFile;
  final String? remoteUrl;
  final bool removed;
  final Color accentColor;
  final ValueChanged<File?> onLocalFileChanged;
  final VoidCallback onRemove;
  final String? label;
  final String? attachLabel;
  final String? replaceLabel;
  final String? removeLabel;
  final IconData attachIcon;

  const ReceiptAttachmentSection({
    super.key,
    required this.localFile,
    required this.remoteUrl,
    required this.removed,
    required this.accentColor,
    required this.onLocalFileChanged,
    required this.onRemove,
    this.label,
    this.attachLabel,
    this.replaceLabel,
    this.removeLabel,
    this.attachIcon = Icons.receipt_long_outlined,
  });

  bool get _hasPreview =>
      !removed && (localFile != null || (remoteUrl?.isNotEmpty ?? false));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? l10n.expenseReceiptLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 10),
        if (_hasPreview) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: localFile != null
                  ? Image.file(
                      localFile!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, o, errro) =>
                          _invalidPreview(context, l10n),
                    )
                  : Image.network(
                      remoteUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, o, errro) =>
                          _invalidPreview(context, l10n),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _pick(context),
                icon: const Icon(Icons.photo_camera_outlined, size: 20),
                label: Text(replaceLabel ?? l10n.expenseReceiptReplace),
              ),
              TextButton.icon(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.errorColor.withValues(alpha: 0.9),
                ),
                label: Text(
                  removeLabel ?? l10n.expenseReceiptRemove,
                  style: TextStyle(color: AppColors.errorColor),
                ),
              ),
            ],
          ),
        ] else
          OutlinedButton.icon(
            onPressed: () => _pick(context),
            icon: Icon(attachIcon, color: accentColor),
            label: Text(attachLabel ?? l10n.expenseReceiptAttach),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _invalidPreview(BuildContext context, AppLocalizations l10n) {
    return ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: AppColors.textColor.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.expenseReceiptInvalidType,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textColor.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ReceiptImageValidator.supportedExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    if (!ReceiptImageValidator.isSupportedPath(path)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.expenseReceiptInvalidType)));
      return;
    }
    onLocalFileChanged(File(path));
  }
}
