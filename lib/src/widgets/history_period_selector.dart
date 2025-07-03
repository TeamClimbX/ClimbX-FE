import 'package:flutter/material.dart';
import '../utils/tier_colors.dart';
import 'history_widget.dart';

class HistoryPeriodSelector extends StatelessWidget {
  final HistoryPeriod selectedPeriod;
  final Function(HistoryPeriod) onPeriodChanged;
  final TierColorScheme colorScheme;

  const HistoryPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    const periods = HistoryPeriod.values;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: periods.map((period) {
          final isSelected = period == selectedPeriod;
          return GestureDetector(
            onTap: () => onPeriodChanged(period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? colorScheme.gradient : null,
                color: isSelected ? null : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Text(
                period.label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
