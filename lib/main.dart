import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'ui/app_theme.dart';
import 'ui/app_shell.dart';

Locale? _resolveLocale(String tag) => switch (tag) {
  'zh' => const Locale('zh'),
  'en' => const Locale('en'),
  _ => null, // 跟随系统语言，由 Flutter 按受支持列表解析。
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.create();
  runApp(PersonalExamApp(controller: controller));
}

class PersonalExamApp extends StatefulWidget {
  const PersonalExamApp({super.key, required this.controller});
  final AppController controller;

  @override
  State<PersonalExamApp> createState() => _PersonalExamAppState();
}

class _PersonalExamAppState extends State<PersonalExamApp>
    with WidgetsBindingObserver {
  static const _windowChannel = MethodChannel('personal_exam/window');
  final navigatorKey = GlobalKey<NavigatorState>();

  AppController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows) {
      _windowChannel.setMethodCallHandler(_handleWindowCall);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows) {
      _windowChannel.setMethodCallHandler(null);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        controller.handleAppForeground();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        controller.handleAppBackground();
        break;
    }
  }

  Future<void> _handleWindowCall(MethodCall call) async {
    if (call.method != 'requestClose') return;
    controller.prepareForExit();
    final context = navigatorKey.currentContext;
    if (context == null) {
      await _windowChannel.invokeMethod<void>('allowClose');
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final pending = controller.stats.pendingSync;
    var choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          pending > 0 ? l10n.exitPendingTitle(pending) : l10n.exitQuitTitle,
        ),
        content: Text(
          pending > 0
              ? l10n.exitPendingBody
              : l10n.exitSavedBody(
                  controller.lastSyncAtUtc?.toString() ??
                      l10n.exitNeverSynced,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'direct'),
            child: Text(pending > 0 ? l10n.exitStayWithoutSync : l10n.exitQuit),
          ),
          if (pending > 0)
            FilledButton(
              onPressed: controller.canSyncBeforeExit
                  ? () => Navigator.pop(context, 'sync')
                  : null,
              child: Text(l10n.exitSyncAndQuit),
            ),
        ],
      ),
    );
    if (choice == 'sync') {
      final report = await controller.syncBeforeExit();
      if (!mounted) return;
      if (report.failed > 0) {
        choice = await showDialog<String>(
          context: navigatorKey.currentContext!,
          barrierDismissible: false,
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(l10n.syncFailedTitle),
              content: Text(l10n.syncFailedBody(report.message)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, 'cancel'),
                  child: Text(l10n.exitCancelQuit),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, 'direct'),
                  child: Text(l10n.exitQuitDirect),
                ),
              ],
            );
          },
        );
      } else {
        choice = 'direct';
      }
    }
    await _windowChannel.invokeMethod<void>(
      choice == 'direct' ? 'allowClose' : 'cancelClose',
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _resolveLocale(controller.localeTag),
      themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ExamTheme.light(),
      darkTheme: ExamTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(controller.fontScale)),
        child: child!,
      ),
      home: controller.error == null
          ? AppShell(controller: controller)
          : _StartupError(message: controller.error!),
    ),
  );
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.startupErrorTitle),
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: SelectableText(message, style: const TextStyle(color: Colors.red)),
    ),
  );
}
