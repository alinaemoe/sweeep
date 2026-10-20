import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/intro.dart';
import 'core/perf_log.dart';
import 'core/theme.dart';
import 'features/shell/app_shell.dart';
import 'l10n/l10n.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'platform/messages.g.dart' show PermissionState;
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(); // month and day names for every supported language
  startPerfLog();
  // a phone-first cleaner: portrait only, like the design
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: SweeepApp()));
}

class SweeepApp extends StatefulWidget {
  const SweeepApp({super.key});

  @override
  State<SweeepApp> createState() => _SweeepAppState();
}

class _SweeepAppState extends State<SweeepApp> {
  bool _intro = true;
  bool _reveal = false; // until then the app is built but not painted (keeps the intro smooth)

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweeep',
      debugShowCheckedModeBanner: false,
      theme: SweeepTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _Gate(),
      // The intro plays over the app, which is already loading underneath.
      builder: (context, child) {
        bindL10n(context);
        return Stack(
          fit: StackFit.expand,
          children: [
            // a language change rebuilds the whole tree so every text picks it up
            KeyedSubtree(
              key: ValueKey(AppLocalizations.of(context).localeName),
              child: Offstage(offstage: _intro && !_reveal, child: child ?? const SizedBox.shrink()),
            ),
            if (_intro) SweeepIntro(onReveal: () => setState(() => _reveal = true), onDone: () => setState(() => _intro = false)),
          ],
        );
      },
    );
  }
}

/// Onboarding until photo access is granted (full or limited), then the
/// library screen.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(permissionProvider);
    if (perm == null) return const Scaffold(body: SizedBox.shrink());
    if (perm == PermissionState.denied) return const OnboardingScreen();
    return const AppShell();
  }
}
