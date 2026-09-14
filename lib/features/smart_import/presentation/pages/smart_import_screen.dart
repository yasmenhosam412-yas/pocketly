import 'package:flutter/material.dart';
import 'package:imrpo/core/services/service_locator.dart';
import 'package:imrpo/core/services/shared_text_import_store.dart';
import 'package:imrpo/core/utils/app_colors.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_header.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_paste_tab.dart';
import 'package:imrpo/features/smart_import/presentation/widgets/smart_import_sms_tab.dart';
import 'package:imrpo/l10n/app_localizations.dart';

class SmartImportScreen extends StatefulWidget {
  static const pasteTabIndex = 0;
  static const smsTabIndex = 1;

  final int initialTabIndex;

  const SmartImportScreen({
    super.key,
    this.initialTabIndex = pasteTabIndex,
  });

  @override
  State<SmartImportScreen> createState() => _SmartImportScreenState();
}

class _SmartImportScreenState extends State<SmartImportScreen>
    with SingleTickerProviderStateMixin {
  static const _scrollToTopThreshold = 320.0;
  static const _tabCount = 2;

  late final TabController _tabController;
  late final SharedTextImportStore _sharedTextStore;
  late final ScrollController _pasteScrollController;
  late final ScrollController _smsScrollController;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, _tabCount - 1);
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
    _pasteScrollController = ScrollController()
      ..addListener(_updateScrollToTopVisibility);
    _smsScrollController = ScrollController()
      ..addListener(_updateScrollToTopVisibility);
    _sharedTextStore = getIt<SharedTextImportStore>();
    _sharedTextStore.smartImportScreenOpen = true;
    _sharedTextStore.addListener(_onSharedTextPending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onSharedTextPending());
  }

  @override
  void dispose() {
    _sharedTextStore.removeListener(_onSharedTextPending);
    _sharedTextStore.smartImportScreenOpen = false;
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pasteScrollController.dispose();
    _smsScrollController.dispose();
    super.dispose();
  }

  ScrollController get _activeScrollController {
    return _tabController.index == SmartImportScreen.smsTabIndex
        ? _smsScrollController
        : _pasteScrollController;
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _updateScrollToTopVisibility();
  }

  void _onSharedTextPending() {
    if (!mounted || !_sharedTextStore.hasPending) return;
    if (_tabController.index != SmartImportScreen.pasteTabIndex) {
      _tabController.index = SmartImportScreen.pasteTabIndex;
    }
  }

  void _updateScrollToTopVisibility() {
    if (!mounted) return;
    final controller = _activeScrollController;
    final show =
        controller.hasClients && controller.offset > _scrollToTopThreshold;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  void _scrollToTop() {
    final controller = _activeScrollController;
    if (!controller.hasClients) return;
    controller.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              tooltip: l10n.smartImportScrollToTop,
              child: const Icon(Icons.keyboard_arrow_up_rounded),
            )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SmartImportHeader(tabController: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SmartImportPasteTab(scrollController: _pasteScrollController),
                  SmartImportSmsTab(
                    scrollController: _smsScrollController,
                    tabController: _tabController,
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
