import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../utils/constants.dart';
import 'neo_button.dart';

class DialogService {
  final Ref ref;

  DialogService(this.ref);

  Future<void> showErrorDialog(BuildContext context,
      {required String title, required String message}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await _showDialog(
      context,
      title: title,
      message: message,
      accentColor: isDark ? AppColorsDark.errorColor : AppColorsLight.errorColor,
      icon: Icons.error_outline,
    );
  }

  Future<void> showInfoDialog(BuildContext context,
      {required String title, required String message}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await _showDialog(
      context,
      title: title,
      message: message,
      accentColor: isDark ? AppColorsDark.indigo : AppColorsLight.indigo,
      icon: Icons.info_outline,
    );
  }

  Future<void> _showDialog(BuildContext context,
      {required String title,
      required String message,
      required Color accentColor,
      required IconData icon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final surfaceColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;
    final textColor = isDark ? AppColorsDark.textColor : AppColorsLight.textColor;
    final shadowColor = isDark ? NeoColors.darkShadow : NeoColors.hardShadowColor;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.all(14),
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
                child: Icon(icon, size: 36, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.heading(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body(
                  fontSize: 14,
                  color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  text: 'ACEPTAR',
                  backgroundColor: AppColorsLight.terracotta,
                  foregroundColor: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final dialogServiceProvider = Provider((ref) => DialogService(ref));
