import 'package:flutter/material.dart';
import '../utils/color_schemes.dart';

/// 검색 필터 토글 위젯
class SearchFilterToggle extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Function(String) onOptionSelected;

  const SearchFilterToggle({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColorSchemes.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        // 토글 버튼들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedOption == option;
            return _buildToggleButton(option, isSelected);
          }).toList(),
        ),
      ],
    );
  }

  /// 개별 토글 버튼 위젯
  Widget _buildToggleButton(String option, bool isSelected) {
    return GestureDetector(
      onTap: () => onOptionSelected(option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? _getColorForOption(option)
            : AppColorSchemes.backgroundPrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
              ? _getColorForOption(option)
              : AppColorSchemes.borderPrimary,
            width: 1,
          ),
          boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: _getColorForOption(option).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        ),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected 
              ? AppColorSchemes.backgroundPrimary
              : AppColorSchemes.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 옵션에 따른 색상 반환
  Color _getColorForOption(String option) {
    switch (option) {
      case '빨강':
        return const Color(0xFFEF4444);
      case '파랑':
        return const Color(0xFF3B82F6);
      case '초록':
        return const Color(0xFF10B981);
      case '노랑':
        return const Color(0xFFF59E0B);
      case '보라':
        return const Color(0xFF8B5CF6);
      default:
        return AppColorSchemes.accentBlue;
    }
  }
} 