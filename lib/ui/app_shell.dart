import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_theme.dart';
import 'pages.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final AppController controller;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  static List<NavigationRailDestination> _railDestinations(
    AppLocalizations l10n,
  ) => [
    NavigationRailDestination(
      icon: const Icon(Icons.home_outlined),
      selectedIcon: const Icon(Icons.home),
      label: Text(l10n.shellNavHome),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.school_outlined),
      selectedIcon: const Icon(Icons.school),
      label: Text(l10n.shellNavPractice),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.article_outlined),
      selectedIcon: const Icon(Icons.article),
      label: Text(l10n.shellNavPaper),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.history_outlined),
      selectedIcon: const Icon(Icons.history),
      label: Text(l10n.shellNavHistory),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.bookmark_outline),
      selectedIcon: const Icon(Icons.bookmark),
      label: Text(l10n.shellNavCollection),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.library_books_outlined),
      selectedIcon: const Icon(Icons.library_books),
      label: Text(l10n.shellNavBank),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.query_stats_outlined),
      selectedIcon: const Icon(Icons.query_stats),
      label: Text(l10n.shellNavStats),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.sync_outlined),
      selectedIcon: const Icon(Icons.sync),
      label: Text(l10n.shellNavSync),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.settings_outlined),
      selectedIcon: const Icon(Icons.settings),
      label: Text(l10n.shellNavSettings),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final mobile = width < 720 || size.shortestSide < 600;
    final extended = width >= 1180;
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    if (mobile) return _mobileShell(context, controller, dark, l10n);
    return Scaffold(
      backgroundColor: dark ? ExamColors.darkPaper : ExamColors.paper,
      body: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: dark
                  ? ExamColors.darkSurface
                  : Colors.white.withValues(alpha: 0.9),
              border: Border(
                right: BorderSide(
                  color: dark ? ExamColors.darkLine : ExamColors.line,
                ),
              ),
            ),
            child: NavigationRail(
              extended: extended,
              minWidth: 82,
              minExtendedWidth: 224,
              selectedIndex: index,
              groupAlignment: -1,
              onDestinationSelected: (value) => setState(() => index = value),
              labelType: extended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.fromLTRB(12, 18, 12, 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.fact_check_outlined,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    if (extended) ...[
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'EXAMFLOW · WINDOWS',
                            style: TextStyle(fontSize: 9, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              destinations: _railDestinations(l10n),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? const [
                          Color(0xff193a34),
                          ExamColors.darkCanvas,
                          ExamColors.darkPaper,
                        ]
                      : const [
                          Color(0xffdff2eb),
                          ExamColors.canvas,
                          ExamColors.paper,
                        ],
                  stops: const [0, 0.34, 1],
                ),
              ),
              child: _currentPage(controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileShell(
    BuildContext context,
    AppController controller,
    bool dark,
    AppLocalizations l10n,
  ) => Scaffold(
    backgroundColor: dark ? ExamColors.darkPaper : ExamColors.paper,
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [
                  Color(0xff193a34),
                  ExamColors.darkCanvas,
                  ExamColors.darkPaper,
                ]
              : const [Color(0xffdff2eb), ExamColors.canvas, ExamColors.paper],
          stops: const [0, 0.34, 1],
        ),
      ),
      child: _currentPage(controller),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index < 4 ? index : 4,
      onDestinationSelected: (value) {
        if (value < 4) {
          setState(() => index = value);
        } else {
          _showMorePages(context);
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.shellNavHome,
        ),
        NavigationDestination(
          icon: const Icon(Icons.school_outlined),
          selectedIcon: const Icon(Icons.school),
          label: l10n.shellTabPractice,
        ),
        NavigationDestination(
          icon: const Icon(Icons.article_outlined),
          selectedIcon: const Icon(Icons.article),
          label: l10n.shellTabPaper,
        ),
        NavigationDestination(
          icon: const Icon(Icons.history_outlined),
          selectedIcon: const Icon(Icons.history),
          label: l10n.shellTabHistory,
        ),
        NavigationDestination(
          icon: const Icon(Icons.apps_outlined),
          selectedIcon: const Icon(Icons.apps),
          label: l10n.shellTabMore,
        ),
      ],
    ),
  );

  Future<void> _showMorePages(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(l10n.appTitle),
            subtitle: const Text('EXAMFLOW · ANDROID'),
          ),
          const Divider(),
          for (final item in <({int index, IconData icon, String label})>[
            (
              index: 4,
              icon: Icons.bookmark_outline,
              label: l10n.shellSheetCollection,
            ),
            (
              index: 5,
              icon: Icons.library_books_outlined,
              label: l10n.shellSheetBank,
            ),
            (
              index: 6,
              icon: Icons.query_stats_outlined,
              label: l10n.shellNavStats,
            ),
            (
              index: 7,
              icon: Icons.sync_outlined,
              label: l10n.shellNavSync,
            ),
            (
              index: 8,
              icon: Icons.settings_outlined,
              label: l10n.shellNavSettings,
            ),
          ])
            ListTile(
              selected: index == item.index,
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing: index == item.index ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, item.index),
            ),
        ],
      ),
    );
    if (selected != null && mounted) setState(() => index = selected);
  }

  Widget _currentPage(AppController controller) => switch (index) {
    0 => HomePage(
      controller: controller,
      onNavigate: (value) => setState(() => index = value),
    ),
    1 => PracticeLauncherPage(controller: controller),
    2 => PaperLauncherPage(controller: controller),
    3 => HistoryPage(controller: controller),
    4 => CollectionPage(controller: controller),
    5 => BankPage(controller: controller),
    6 => StatsPage(controller: controller),
    7 => SyncBackupPage(controller: controller),
    8 => SettingsPage(controller: controller),
    _ => HomePage(
      controller: controller,
      onNavigate: (value) => setState(() => index = value),
    ),
  };
}
