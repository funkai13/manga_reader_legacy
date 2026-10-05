import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';
import 'neo_button.dart';

class NeoLoadingIndicator extends StatefulWidget {
  final double size;

  const NeoLoadingIndicator({super.key, this.size = 46.0});

  @override
  State<NeoLoadingIndicator> createState() => _NeoLoadingIndicatorState();
}

class _NeoLoadingIndicatorState extends State<NeoLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final primaryColor = isDark ? AppColorsDark.terracotta : AppColorsLight.terracotta;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
          border: Border.all(
            color: borderColor,
            width: NeoConstants.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: NeoConstants.shadowOffset,
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: widget.size * 0.45,
            height: widget.size * 0.45,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class NeoShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double? borderRadius;

  const NeoShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<NeoShimmer> createState() => _NeoShimmerState();
}

class _NeoShimmerState extends State<NeoShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final baseColor = isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceDeep;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius ?? NeoConstants.borderRadius),
              border: Border.all(
                color: borderColor,
                width: NeoConstants.borderWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}

class NeoErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const NeoErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = isDark ? AppColorsDark.errorColor : AppColorsLight.errorColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: NeoConstants.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: NeoConstants.shadowOffset,
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Icon(Icons.error_outline, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.heading(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              NeoButton(
                text: 'REINTENTAR',
                onPressed: onRetry,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NeoEmptyWidget extends StatelessWidget {
  final String message;
  final IconData icon;

  const NeoEmptyWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark ? AppColorsDark.indigo : AppColorsLight.indigo;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: NeoConstants.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    offset: NeoConstants.shadowOffset,
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(icon, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.heading(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showNeoSnackBar(BuildContext context, String message, {bool isError = false}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final bgColor = isError
      ? (isDark ? AppColorsDark.errorColor : AppColorsLight.errorColor)
      : (isDark ? AppColorsDark.surfaceDeep : AppColorsLight.surfaceColor);

  final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
  final textColor = isError
      ? Colors.white
      : (isDark ? AppColorsDark.textColor : AppColorsLight.textColor);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: AppTypography.heading(
          fontSize: 14,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
        side: BorderSide(color: borderColor, width: NeoConstants.borderWidth),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 0,
    ),
  );
}

class NeoLoadingOverlay extends StatelessWidget {
  final String message;

  const NeoLoadingOverlay({
    super.key,
    this.message = 'CARGANDO...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
            border: Border.all(
              color: borderColor,
              width: NeoConstants.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(4, 4),
                blurRadius: 0,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NeoLoadingIndicator(size: 48),
              const SizedBox(height: 20),
              Text(
                message,
                style: AppTypography.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColorsDark.textColor : AppColorsLight.textColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
