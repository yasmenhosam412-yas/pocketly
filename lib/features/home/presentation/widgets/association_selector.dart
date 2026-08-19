import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:imrpo/core/helpers/supabase_auth_helper.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/association_context.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/session/user_session.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/associations/domain/entities/association_item.dart';
import 'package:imrpo/l10n/app_localizations.dart';

/// Header chip to switch the active ledger.
class AssociationSelector extends StatelessWidget {
  const AssociationSelector({
    super.key,
    this.lightStyle = true,
  });

  final bool lightStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ctx = getIt<AssociationContext>();

    return ListenableBuilder(
      listenable: ctx,
      builder: (context, _) {
        if (!SupabaseAuthHelper.isSignedIn) {
          return const SizedBox.shrink();
        }
        if (ctx.isLoaded && ctx.isOffline) {
          return _HeaderActionChip(
            lightStyle: lightStyle,
            icon: Icons.cloud_off_outlined,
            label: l10n.noInternetConnection,
            trailingIcon: Icons.refresh_rounded,
            isHighlighted: true,
            onTap: () => ctx.load(forceNetwork: true),
          );
        }
        if (ctx.isLoaded && !ctx.isAvailable) {
          return const SizedBox.shrink();
        }

        final active = ctx.activeItem;
        final label = active != null
            ? ctx.displayName(
                active,
                personalFallback: l10n.associationPersonal,
              )
            : l10n.associationPersonal;

        return _HeaderActionChip(
          lightStyle: lightStyle,
          icon: Icons.menu_book_rounded,
          label: label,
          trailingIcon: Icons.expand_more_rounded,
          isHighlighted: active != null && !active.isPersonal,
          onTap: () => _openSheet(context, ctx, l10n),
        );
      },
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    AssociationContext associationContext,
    AppLocalizations l10n,
  ) async {
    if (!associationContext.isLoaded) {
      await associationContext.load();
      if (!context.mounted) return;
    }

    final choice = await showModalBottomSheet<_AssociationSheetResult>(
      context: context,
      isScrollControlled: true,
shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _AssociationPickerSheet(
        associationContext: associationContext,
        l10n: l10n,
      ),
    );

    if (!context.mounted || choice == null) return;

    if (choice.createRequested) {
      await _createAssociation(context, associationContext, l10n);
      return;
    }

    if (choice.deleteId != null) {
      await _deleteAssociation(
        context,
        associationContext,
        l10n,
        choice.deleteId!,
      );
      return;
    }

    if (choice.selectedId != null &&
        choice.selectedId != associationContext.activeAssociationId) {
      await associationContext.selectAssociation(choice.selectedId!);
      if (!context.mounted) return;
      UserSession.reloadForAssociationSwitch(context);
    }
  }

  Future<void> _createAssociation(
    BuildContext context,
    AssociationContext associationContext,
    AppLocalizations l10n,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CreateAssociationDialog(l10n: l10n),
    );

    if (!context.mounted || name == null) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.associationNameRequired),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await associationContext.createAssociation(name);
      if (!context.mounted) return;
      UserSession.reloadForAssociationSwitch(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.associationCreated(name)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _deleteAssociation(
    BuildContext context,
    AssociationContext associationContext,
    AppLocalizations l10n,
    String associationId,
  ) async {
    AssociationItem? item;
    for (final candidate in associationContext.items) {
      if (candidate.id == associationId) {
        item = candidate;
        break;
      }
    }
    if (item == null) return;

    if (item.isPersonal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.associationCannotDeletePersonal),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await associationContext.deleteAssociation(associationId);
      if (!context.mounted) return;
      UserSession.reloadForAssociationSwitch(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.associationDeletedSnack),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (e) {
      if (!context.mounted) return;
      final message = e.message.contains('Cannot delete personal')
          ? l10n.associationCannotDeletePersonal
          : localizeApiError(l10n, e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeApiError(l10n, e.toString())),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _CreateAssociationDialog extends StatefulWidget {
  final AppLocalizations l10n;

  const _CreateAssociationDialog({required this.l10n});

  @override
  State<_CreateAssociationDialog> createState() =>
      _CreateAssociationDialogState();
}

class _CreateAssociationDialogState extends State<_CreateAssociationDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _nameController.text.trim());

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.associationCreateTitle),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: l10n.associationNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.associationCreateAction),
        ),
      ],
    );
  }
}

class _AssociationSheetResult {
  final String? selectedId;
  final bool createRequested;
  final String? deleteId;

  const _AssociationSheetResult({
    this.selectedId,
    this.createRequested = false,
    this.deleteId,
  });
}

class _AssociationPickerSheet extends StatelessWidget {
  final AssociationContext associationContext;
  final AppLocalizations l10n;

  const _AssociationPickerSheet({
    required this.associationContext,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final activeId = associationContext.activeAssociationId;
    final items = associationContext.items;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16),
              Text(
                l10n.associationPickerTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.associationPickerSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...items.map((item) {
                        final selected = item.id == activeId;
                        final label = associationContext.displayName(
                          item,
                          personalFallback: l10n.associationPersonal,
                        );
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.isPersonal
                                ? Icons.person_outline_rounded
                                : Icons.menu_book_outlined,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textColor,
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!item.isPersonal)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppColors.errorColor,
                                    size: 22,
                                  ),
                                  tooltip: l10n.associationDeleteAction,
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: Text(
                                          l10n.associationDeleteConfirmTitle,
                                        ),
                                        content: Text(
                                          l10n.associationDeleteConfirmMessage(
                                            label,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              false,
                                            ),
                                            child: Text(l10n.cancel),
                                          ),
                                          FilledButton(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: AppColors.error,
                                            ),
                                            onPressed: () => Navigator.pop(
                                              dialogContext,
                                              true,
                                            ),
                                            child: Text(
                                              l10n.associationDeleteAction,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true && context.mounted) {
                                      Navigator.pop(
                                        context,
                                        _AssociationSheetResult(
                                          deleteId: item.id,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                          onTap: () => Navigator.pop(
                            context,
                            _AssociationSheetResult(selectedId: item.id),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          l10n.associationCreateAction,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          const _AssociationSheetResult(createRequested: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mirrors home header chip styling (defined in home_screen.dart).
class _HeaderActionChip extends StatelessWidget {
  final bool lightStyle;
  final IconData icon;
  final String label;
  final IconData? trailingIcon;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _HeaderActionChip({
    required this.lightStyle,
    required this.icon,
    required this.label,
    this.trailingIcon,
    this.isHighlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = lightStyle
        ? Colors.white.withValues(alpha: isHighlighted ? 0.28 : 0.18)
        : AppColors.surface;
    final fg = lightStyle ? Colors.white : AppColors.textColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: lightStyle
                ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(trailingIcon, size: 18, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
