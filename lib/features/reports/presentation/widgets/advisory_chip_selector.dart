import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:asisten_keuangan/core/theme/app_theme.dart';
import 'package:asisten_keuangan/features/reports/domain/advisory_preference.dart';
import 'package:asisten_keuangan/features/reports/data/monthly_ai_analysis_provider.dart';

class AdvisoryChipSelector extends ConsumerWidget {
  const AdvisoryChipSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStyle = ref.watch(advisoryStyleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GAYA PENASIHAT BANKER',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: AdvisoryStyle.values.map((style) {
              final isSelected = style == currentStyle;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    style.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryNavy,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryNavy
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  onSelected: (_) {
                    if (!isSelected) {
                      ref.read(advisoryStyleProvider.notifier).selectStyle(style);
                      ref
                          .read(monthlyAiAnalysisProvider.notifier)
                          .generateAnalysis();
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
