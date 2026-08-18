import 'package:flutter/material.dart';
import 'theme.dart';

class GradientScaffold extends StatelessWidget {
  const GradientScaffold({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark ? const [Color(0xFF05080E), Color(0xFF0A111B), Color(0xFF111927)] : const [Color(0xFFF4F6FA), Color(0xFFE8EDF4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class ZCard extends StatelessWidget {
  const ZCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0F1622).withValues(alpha: .96) : Colors.white.withValues(alpha: .95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: .055) : Colors.black.withValues(alpha: .06)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dark ? .28 : .08), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFD56A), Color(0xFFB87710)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .32)),
          boxShadow: [BoxShadow(color: ZTheme.gold.withValues(alpha: .18), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, color: const Color(0xFF251707), size: 18), const SizedBox(width: 7)], Text(label, style: const TextStyle(color: Color(0xFF251707), fontWeight: FontWeight.w900, fontSize: 12))]),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))), if (trailing != null) trailing!]);
}

class MetricChip extends StatelessWidget {
  const MetricChip({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: ZTheme.gold.withValues(alpha: .10)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: ZTheme.gold), const SizedBox(width: 8), Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]));
}
