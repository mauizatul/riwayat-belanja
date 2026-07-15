/// Representasi 1 baris histori pembelian barang, gabungan data dari
/// `receipt_items` + info merchant & tanggal dari `receipts` induknya.
/// Dipakai untuk fitur search & tracking harga.
class ItemPurchase {
  final String itemName;
  final double qty;
  final double unitPrice;
  final DateTime? receiptDate;
  final String? merchantName;

  ItemPurchase({
    required this.itemName,
    required this.qty,
    required this.unitPrice,
    this.receiptDate,
    this.merchantName,
  });

  factory ItemPurchase.fromJson(Map<String, dynamic> json) {
    final receiptJson = json['receipts'] as Map<String, dynamic>?;

    DateTime? date;
    String? merchantName;

    if (receiptJson != null) {
      final dateStr = receiptJson['receipt_date'] as String?;
      if (dateStr != null && dateStr.isNotEmpty) {
        date = DateTime.tryParse(dateStr);
      }

      final merchantJson = receiptJson['merchants'] as Map<String, dynamic>?;
      merchantName = merchantJson?['name'] as String?;
    }

    return ItemPurchase(
      itemName: json['item_name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      receiptDate: date,
      merchantName: merchantName,
    );
  }
}
