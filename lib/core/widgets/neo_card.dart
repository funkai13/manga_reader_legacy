import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';

class NeoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.onTap,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final bgColor = backgroundColor ?? theme.cardColor;

    Widget card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
        border: Border.all(
          color: borderColor,
          width: NeoConstants.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: NeoColors.hardShadowColor,
            offset: NeoConstants.shadowOffset,
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius - NeoConstants.borderWidth),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) {
      card = Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(
            color: borderColor,
            width: NeoConstants.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: NeoColors.hardShadowColor,
              offset: NeoConstants.shadowOffset,
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: child,
      );
    }

    return card;
  }
}
