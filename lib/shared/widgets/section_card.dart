import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.style,
    required this.icon,
    required this.title,
    required this.child,
    this.headerTrailing,
    this.expanded,
    this.onExpansionChanged,
    this.summary,
    super.key,
  });

  final AppSectionStyle style;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? headerTrailing;
  final bool? expanded;
  final ValueChanged<bool>? onExpansionChanged;
  final Widget? summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: style.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: style.border, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: expanded == null
                  ? null
                  : () {
                      if (!expanded!) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                      onExpansionChanged?.call(!expanded!);
                    },
              borderRadius: BorderRadius.circular(12),
              child: Semantics(
                button: expanded != null,
                expanded: expanded,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Icon(icon, color: style.icon),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      ?headerTrailing,
                      if (expanded != null)
                        Icon(expanded! ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
            ),
            if (expanded == false && summary != null) summary!,
            if (expanded != false) ...[const SizedBox(height: 12), child],
          ],
        ),
      ),
    );
  }
}
