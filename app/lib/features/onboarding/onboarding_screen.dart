import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/l10n.dart';
import '../../core/widgets.dart';
import '../../platform/messages.g.dart' show PermissionState;
import '../../providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// Show the "access is off" hint only after the user has actually been asked.
  bool _asked = false;

  Future<void> _onPressed() async {
    final notifier = ref.read(permissionProvider.notifier);
    if (_asked) {
      await notifier.check();
    } else {
      await notifier.request();
      if (mounted) setState(() => _asked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionProvider);
    final denied = _asked && state == PermissionState.denied;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SweeepWordmark(size: 28),
              const Spacer(),
              Text(l10n.onbTitle,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -0.8)),
              const SizedBox(height: 20),
              _Point(l10n.onbPoint1),
              _Point(l10n.onbPoint2),
              _Point(l10n.onbPoint3),
              const Spacer(),
              if (denied)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.onbDenied,
                    style: const TextStyle(color: SweeepColors.trash, fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              PillButton(
                label: denied ? l10n.onbCheckAgain : l10n.onbAllow,
                onPressed: _onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 12),
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: SweeepColors.brand.withValues(alpha: .14), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 14, color: SweeepColors.brand),
            ),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SweeepColors.text))),
          ],
        ),
      );
}
