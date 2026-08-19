import 'package:flutter/material.dart';
import 'package:imrpo/core/l10n/l10n_entity_strings.dart';
import 'package:imrpo/core/services/association_invite_disclaimer_prefs.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/association_invites/data/association_invite_datasource.dart';
import 'package:imrpo/features/association_invites/domain/entities/profile_search_result.dart';
import 'package:imrpo/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InviteMembersScreen extends StatefulWidget {
  const InviteMembersScreen({
    super.key,
    required this.associationId,
    required this.associationName,
  });

  final String associationId;
  final String associationName;

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  final _searchController = TextEditingController();
  final _datasource = AssociationInviteDatasource(getIt<SupabaseClient>());

  List<ProfileSearchResult> _results = [];
  bool _searching = false;
  String? _error;
  final Set<String> _invitedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _ensureDisclaimer(AppLocalizations l10n) async {
    if (await getIt<AssociationInviteDisclaimerPrefs>().isAccepted()) {
      return true;
    }
    if (!mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.associationInviteDisclaimerTitle),
        content: SingleChildScrollView(
          child: Text(
            l10n.associationInviteDisclaimerBody,
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.associationInviteDisclaimerAccept),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await getIt<AssociationInviteDisclaimerPrefs>().setAccepted();
      return true;
    }
    return false;
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final list = await _datasource.searchProfiles(q);
      if (!mounted) return;
      setState(() {
        _results = list;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = e.toString();
        _results = [];
      });
    }
  }

  Future<void> _invite(ProfileSearchResult user) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _ensureDisclaimer(l10n)) return;

    try {
      await _datasource.sendInvite(
        associationId: widget.associationId,
        inviteeUserId: user.userId,
      );
      if (!mounted) return;
      setState(() => _invitedIds.add(user.userId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.associationInviteSent(user.username))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeApiError(l10n, e.toString())),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          l10n.associationInviteTitle,
          style: TextStyle(color: AppColors.textColor, fontSize: 18),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              l10n.associationInviteSubtitle(widget.associationName),
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.associationInviteSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.trim().length >= 2
                    ? IconButton(
                        onPressed: _searching ? null : _search,
                        icon: _searching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              l10n.associationInviteLegalNote,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                localizeApiError(l10n, _error),
                style: TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          Expanded(
            child: _results.isEmpty && !_searching
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        _searchController.text.trim().length < 2
                            ? l10n.associationInviteSearchMinChars
                            : l10n.associationInviteNoResults,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _results.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      final sent = _invitedIds.contains(user.userId);
                      return Material(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: AppColors.border),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.balanceLight,
                            child: Text(
                              user.username.isNotEmpty
                                  ? user.username[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            user.username,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: sent
                              ? Text(
                                  l10n.associationInviteSentLabel,
                                  style: TextStyle(
                                    color: AppColors.incomeDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                )
                              : FilledButton(
                                  onPressed: () => _invite(user),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.onWarm,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  child: Text(l10n.associationInviteAction),
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
