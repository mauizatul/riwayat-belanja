import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// TextInputFormatter agar input harga otomatis diberi pemisah ribuan.
/// Contoh: user ketik "15000" -> tampil "15.000"
class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(digitsOnly);
    final newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

/// Ubah string hasil [CurrencyInputFormatter] (mis. "15.000") menjadi double (15000).
double parseCurrencyToDouble(String text) {
  final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return 0;
  return double.parse(digitsOnly);
}

/// Format angka menjadi "Rp 15.000".
String formatRupiah(num value) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(value);
}

/// Format tanggal manual (tanpa perlu initializeDateFormatting)
/// menjadi "9 Juli 2026".
String formatDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Format angka mentah jadi teks yang cocok dipakai untuk mengisi ulang
/// text field harga yang pakai [CurrencyInputFormatter] (tanpa prefix "Rp").
/// Dipakai saat pre-fill form dari hasil scan AI.
String formatPriceInput(num value) {
  return NumberFormat.decimalPattern('id_ID').format(value.round());
}

/// Format tanggal singkat "9/7/2026", cocok untuk list/history.
String formatShortDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
