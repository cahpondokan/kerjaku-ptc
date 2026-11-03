import 'package:flutter/material.dart';
import 'package:lembur/app/theme/app_colors.dart';
import 'package:lembur/app/theme/neumorphic_styles.dart';

class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.expand = true,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool primary;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final foreground = widget.primary ? Colors.white : AppColors.primary;
    final background =
        widget.primary ? AppColors.primary : AppColors.background;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
        boxShadow:
            _pressed
                ? NeumorphicStyles.soft(blur: 6, offset: 2)
                : NeumorphicStyles.raised(blur: 12, offset: 5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: foreground, size: 20),
            const SizedBox(width: 9),
          ],
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown:
          widget.onPressed == null
              ? null
              : (_) => setState(() => _pressed = true),
      onTapCancel:
          widget.onPressed == null
              ? null
              : () => setState(() => _pressed = false),
      onTapUp:
          widget.onPressed == null
              ? null
              : (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              },
      child: Opacity(
        opacity: widget.onPressed == null ? 0.5 : 1,
        child:
            widget.expand
                ? SizedBox(width: double.infinity, child: child)
                : child,
      ),
    );
  }
}
