import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
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
      accentColor: isDark ? AppColorsDark.infoColor : AppColorsLight.infoColor,
      icon: Icons.info_outline,
    );
  }

  Future<void> _showDialog(BuildContext context,
      {required String title, required String message, required Color accentColor, required IconData icon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColorsDark.borderColor : AppColorsLight.borderColor;
    final surfaceColor = isDark ? AppColorsDark.surfaceColor : AppColorsLight.surfaceColor;
    
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: NeoConstants.borderWidth,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: NeoColors.hardShadowColor,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(icon, size: 40, color: Colors.black),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: NeoButton(
                  text: 'ACEPTAR',
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
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
