import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isUppercase;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const NeoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.isUppercase = true,
    this.padding,
    this.fontSize,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;
    final bgColor = widget.backgroundColor ?? (isDark ? AppColorsDark.terracotta : AppColorsLight.terracotta);
    final fgColor = widget.foregroundColor ?? Colors.white;

    final textWidget = Text(
      widget.isUppercase ? widget.text.toUpperCase() : widget.text,
      style: AppTypography.heading(
        fontSize: widget.fontSize ?? 13,
        fontWeight: FontWeight.w800,
        color: fgColor,
        letterSpacing: 1.0,
      ),
    );

    // Interactive elements depress +2px down and right on tap/click with shadow reducing to zero
    final offset = _isPressed ? NeoConstants.shadowOffset : Offset.zero;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: Transform.translate(
        offset: offset,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            border: Border.all(
              color: borderColor,
              width: NeoConstants.borderWidth,
            ),
            boxShadow: _isPressed
                ? null
                : [
                    BoxShadow(
                      color: shadowColor,
                      offset: NeoConstants.shadowOffset,
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
          ),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fgColor, size: (widget.fontSize ?? 13) + 4),
                const SizedBox(width: 8),
              ],
              textWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class NeoOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isUppercase;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const NeoOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isUppercase = true,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return NeoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor,
      foregroundColor: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
      icon: icon,
      isUppercase: isUppercase,
      padding: padding,
      fontSize: fontSize,
    );
  }
}
