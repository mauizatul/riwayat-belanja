class ReceiptItem {
  final int? id;
  final int? receiptId;
  final String itemName;
  final double qty;
  final double unitPrice;
  final double totalPrice;

  ReceiptItem({
    this.id,
    this.receiptId,
    required this.itemName,
    required this.qty,
    required this.unitPrice,
  }) : totalPrice = double.parse((qty * unitPrice).toStringAsFixed(2));

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] as int?,
      receiptId: json['receipt_id'] as int?,
      itemName: json['item_name'] as String,
      qty: (json['qty'] as num).toDouble(),
      unitPrice: (json['unit_price'] as num).toDouble(),
    );
  }

  /// Payload untuk insert ke tabel `receipt_items`.
  /// [receiptId] wajib diisi karena baru didapat setelah receipt tersimpan.
  Map<String, dynamic> toInsertJson(int receiptId) => {
    'receipt_id': receiptId,
    'item_name': itemName,
    'qty': qty,
    'unit_price': unitPrice,
    'total_price': totalPrice,
  };
}
