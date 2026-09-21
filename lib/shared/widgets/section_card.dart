import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.style,
    required this.icon,
    required this.title,
    required this.child,
    this.headerTrailing,
    super.key,
  });

  final AppSectionStyle style;
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? headerTrailing;

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
            Row(
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
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
