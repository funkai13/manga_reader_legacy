import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../utils/constants.dart';
import 'neo_button.dart';

class NeoLoadingIndicator extends StatefulWidget {
  final double size;

  const NeoLoadingIndicator({super.key, this.size = 50.0});

  @override
  State<NeoLoadingIndicator> createState() => _NeoLoadingIndicatorState();
}

class _NeoLoadingIndicatorState extends State<NeoLoadingIndicator> with SingleTickerProviderStateMixin {
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
    final primaryColor = isDark ? AppColorsDark.accentColor : AppColorsLight.accentColor;

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
          boxShadow: const [
            BoxShadow(
              color: NeoColors.hardShadowColor,
              offset: Offset(3, 3),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: widget.size * 0.4,
            height: widget.size * 0.4,
            decoration: BoxDecoration(
              color: borderColor,
              shape: BoxShape.circle,
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

class _NeoShimmerState extends State<NeoShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.3, end: 0.8).animate(
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
    final baseColor = isDark ? AppColorsDark.dividerColor : AppColorsLight.dividerColor;

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
                  color: isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor,
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
              child: const Icon(Icons.error_outline, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
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
    final infoColor = isDark ? AppColorsDark.infoColor : AppColorsLight.infoColor;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: infoColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor,
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
              child: Icon(icon, size: 48, color: Colors.black),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
      : (isDark ? AppColorsDark.successColor : AppColorsLight.successColor);
      
  final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
  final textColor = isError ? Colors.white : Colors.black;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'),
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

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NeoLoadingIndicator(size: 60),
              const SizedBox(height: 24),
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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
