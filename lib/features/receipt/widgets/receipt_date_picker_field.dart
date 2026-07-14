import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:riwayat_belanjaku/core/theme/app_colors.dart';
import 'package:riwayat_belanjaku/core/theme/app_spacing.dart';
import 'package:riwayat_belanjaku/core/theme/app_text_styles.dart';

class ReceiptDatePickerField extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final Function(DateTime) onDateChanged;

  const ReceiptDatePickerField({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<ReceiptDatePickerField> createState() => _ReceiptDatePickerFieldState();
}

class _ReceiptDatePickerFieldState extends State<ReceiptDatePickerField> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      widget.onDateChanged(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.surface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: AppTextStyles.body,
                ),
              ],
            ),
            const Icon(Icons.calendar_today, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
