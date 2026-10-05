import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';

class NeoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool isUppercase;

  const NeoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.isUppercase = true,
  });

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final fgColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    final textWidget = Text(
      widget.isUppercase ? widget.text.toUpperCase() : widget.text,
      style: TextStyle(
        color: fgColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.translationValues(
              _isPressed ? NeoConstants.shadowOffset.dx : 0,
              _isPressed ? NeoConstants.shadowOffset.dy : 0,
              0,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
              border: Border.all(
                color: borderColor,
                width: NeoConstants.borderWidth,
              ),
              boxShadow: _isPressed
                  ? []
                  : const [
                      BoxShadow(
                        color: NeoColors.hardShadowColor,
                        offset: NeoConstants.shadowOffset,
                        blurRadius: 0,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fgColor, size: 20),
                  const SizedBox(width: 8),
                ],
                textWidget,
              ],
            ),
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

  const NeoOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isUppercase = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return NeoButton(
      text: text,
      onPressed: onPressed,
      backgroundColor: isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor,
      foregroundColor: theme.textTheme.bodyLarge?.color,
      icon: icon,
      isUppercase: isUppercase,
    );
  }
}
