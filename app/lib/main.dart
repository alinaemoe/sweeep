import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'platform/messages.g.dart' show PermissionState;
import 'providers.dart';

void main() {
  runApp(const ProviderScope(child: SweeepApp()));
}

class SweeepApp extends StatelessWidget {
  const SweeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sweeep',
      debugShowCheckedModeBanner: false,
      theme: SweeepTheme.dark(),
      home: const _Gate(),
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
    return const HomeScreen();
  }
}
