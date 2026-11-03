import 'package:flutter/material.dart';
import 'package:lembur/app/theme/neumorphic_styles.dart';

class NeumorphicCard extends StatelessWidget {
  const NeumorphicCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = NeumorphicStyles.radius,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: NeumorphicStyles.soft(blur: 12, offset: 4),
        border: Border.all(color: Colors.white.withAlpha(179)),
      ),
      child: child,
    );
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
