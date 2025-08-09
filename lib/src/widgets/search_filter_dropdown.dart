import 'package:flutter/material.dart';
import '../utils/color_schemes.dart';

/// 드롭다운 형태의 필터 선택 위젯
class SearchFilterDropdown extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? selectedOption;
  final Function(String?) onOptionSelected;

  const SearchFilterDropdown({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionSelected,
  });

  @override
  State<SearchFilterDropdown> createState() => _SearchFilterDropdownState();
}

class _SearchFilterDropdownState extends State<SearchFilterDropdown> {
  bool _isExpanded = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 100,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColorSchemes.backgroundPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColorSchemes.borderPrimary,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 전체 선택 옵션
                  _buildDropdownItem(null, '전체'),
                  const SizedBox(height: 4),
                  ...widget.options.map(
                    (option) => _buildDropdownItem(option, option),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });

          if (_isExpanded) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          // 패딩 축소
          decoration: BoxDecoration(
            color: AppColorSchemes.backgroundPrimary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColorSchemes.borderPrimary, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 11, // 폰트 크기 축소
                  fontWeight: FontWeight.w500,
                  color: AppColorSchemes.textPrimary,
                ),
              ),
              const SizedBox(width: 6), // 간격 축소
              // 선택된 색상 동그라미
              if (widget.selectedOption != null)
                Container(
                  width: 10, // 동그라미 크기 축소
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getColorForOption(widget.selectedOption!),
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 6), // 간격 축소
              Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 14, // 아이콘 크기 축소
                color: AppColorSchemes.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 드롭다운 아이템 위젯
  Widget _buildDropdownItem(String? option, String label) {
    final isSelected = widget.selectedOption == option;

    return GestureDetector(
      onTap: () {
        widget.onOptionSelected(option);
        setState(() {
          _isExpanded = false;
        });
        _removeOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        // 패딩 축소
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorSchemes.backgroundTertiary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (option != null) ...[
              Container(
                width: 10, // 동그라미 크기 축소
                height: 10,
                decoration: BoxDecoration(
                  color: _getColorForOption(option),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6), // 간격 축소
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11, // 폰트 크기 축소
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColorSchemes.textPrimary
                      : AppColorSchemes.textSecondary,
                ),
              ),
            ),
          ],
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
