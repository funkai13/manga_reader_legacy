import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/utils/constants.dart';
import '../../core/widgets/neo_card.dart';
import '../../viewmodels/home_viewmodel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.backgroundColor : AppColorsLight.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'PERFIL & AJUSTES',
                style: AppTypography.heading(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ESTADÍSTICAS Y PREFERENCIAS DEL SISTEMA',
                style: AppTypography.mono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColorsDark.textSecondary : AppColorsLight.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Library Stats Card
              NeoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, size: 18, color: NeoColors.terracotta),
                        const SizedBox(width: 8),
                        Text(
                          'MÉTRICAS DE LA BIBLIOTECA',
                          style: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricItem(
                            'TOTAL CÓMICS',
                            '${state.allCount}',
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricItem(
                            'EN LECTURA',
                            '${state.readingCount}',
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricItem(
                            'LEÍDOS',
                            '${state.completedCount}',
                            isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reader Engine Optimization Specs
              NeoCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 18, color: NeoColors.mutedIndigo),
                        const SizedBox(width: 8),
                        Text(
                          'MOTOR DE LECTURA (BATTLE-TESTED)',
                          style: AppTypography.heading(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureRow(
                      Icons.check_circle_outline,
                      'Evicción de Páginas Activas (OOM Prevention)',
                      'Solo 5 páginas activas en RAM simultáneamente.',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      Icons.check_circle_outline,
                      'ResizeImage Inteligente',
                      'Límite de decodificación a 2x pantalla física.',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      Icons.check_circle_outline,
                      'Extracción en Isolates Nativos',
                      '0 caídas de frames o jank durante la importación.',
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureRow(
                      Icons.check_circle_outline,
                      'Ordenamiento Alfanumérico Natural',
                      'Garantía: Página 2 siempre precede a Página 10.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // App Credits
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(NeoConstants.borderRadius),
                  border: Border.all(
                    color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
                    width: 2.0,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'TINTA & PAPEL',
                      style: AppTypography.heading(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PAPER & INK MANGA SYSTEM — v1.0.0',
                      style: AppTypography.mono(fontSize: 10, color: NeoColors.terracotta),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Arquitectura MVVM reactiva diseñada para Google Play Store.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColorsDark.surfaceDeep : NeoColors.surfaceWarm,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? AppColorsDark.borderColor : NeoColors.ink,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.heading(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.mono(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: NeoColors.terracotta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF3E8E5A)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.heading(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: AppTypography.body(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
