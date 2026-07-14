/// Hasil ekstraksi 1 barang dari scan struk (belum final, masih perlu
/// dikoreksi user sebelum disimpan).
class ScannedItem {
  final String itemName;
  final double qty;
  final double unitPrice;

  ScannedItem({
    required this.itemName,
    required this.qty,
    required this.unitPrice,
  });

  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      itemName: json['item_name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Hasil ekstraksi 1 struk secara keseluruhan dari Edge Function
/// `scan-receipt`.
class ScanReceiptResult {
  final String merchantName;
  final DateTime? receiptDate;
  final List<ScannedItem> items;

  ScanReceiptResult({
    required this.merchantName,
    this.receiptDate,
    required this.items,
  });

  factory ScanReceiptResult.fromJson(Map<String, dynamic> json) {
    DateTime? date;
    final dateStr = json['receipt_date'] as String?;
    if (dateStr != null && dateStr.isNotEmpty) {
      date = DateTime.tryParse(dateStr);
    }

    final itemsJson = json['items'] as List<dynamic>? ?? [];

    return ScanReceiptResult(
      merchantName: json['merchant_name'] as String? ?? '',
      receiptDate: date,
      items: itemsJson
          .map((e) => ScannedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
