import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/intro.dart';
import 'core/perf_log.dart';
import 'core/theme.dart';
import 'features/shell/app_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'platform/messages.g.dart' show PermissionState;
import 'providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  startPerfLog();
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
      home: const _Gate(),
      // The intro plays over the app, which is already loading underneath.
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          Offstage(offstage: _intro && !_reveal, child: child ?? const SizedBox.shrink()),
          if (_intro) SweeepIntro(onReveal: () => setState(() => _reveal = true), onDone: () => setState(() => _intro = false)),
        ],
      ),
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
