import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// A small pill of text segments (the style of the Hub language switch): the lavender
/// one is active.
class TextSegment<T> extends StatelessWidget {
  const TextSegment({super.key, required this.options, required this.value, required this.onChanged});
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: SweeepColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .08))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final o in options)
            Semantics(
              button: true,
              selected: value == o.$1,
              label: o.$2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (value == o.$1) return;
                  HapticFeedback.selectionClick();
                  onChanged(o.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 30,
                  constraints: const BoxConstraints(minWidth: 46),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: value == o.$1 ? SweeepColors.brand : Colors.transparent, borderRadius: BorderRadius.circular(15)),
                  child: Text(o.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: value == o.$1 ? SweeepColors.onAccent : SweeepColors.textMutedSmall)),
                ),
              ),
            ),
        ]),
      );
}
