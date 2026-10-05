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
  final bool showShadow;

  const NeoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.onTap,
    this.padding,
    this.width,
    this.height,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;
    final bgColor = backgroundColor ?? (isDark ? AppColorsDark.surfaceColor : AppColorsLight.cardColor);

    final decoration = BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
      border: Border.all(
        color: borderColor,
        width: NeoConstants.borderWidth,
      ),
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: shadowColor,
                offset: NeoConstants.shadowOffset,
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ]
          : null,
    );

    if (onTap == null) {
      return Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16.0),
        decoration: decoration,
        child: child,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            (NeoConstants.borderRadius - NeoConstants.borderWidth).clamp(0.0, double.infinity),
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }
}
