class ReceiptModel {
  final int? id;
  final String userId;
  final int? merchantId;

  /// Nama merchant. Tidak ada kolomnya di tabel `receipts`,
  /// diisi lewat join ke tabel `merchants` saat fetch data
  /// (lihat ReceiptService.fetchReceipts).
  final String? merchantName;

  final DateTime? receiptDate;
  final double totalAmount;
  final String? imageUrl;
  final DateTime? createdAt;

  ReceiptModel({
    this.id,
    required this.userId,
    this.merchantId,
    this.merchantName,
    this.receiptDate,
    required this.totalAmount,
    this.imageUrl,
    this.createdAt,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    // Nama merchant bisa datang dari join `select('*, merchants(name)')`
    // (key defaultnya = nama tabel foreign-nya), atau dari kolom alias
    // `merchant_name` kalau kamu pakai view/RPC.
    String? merchantName;
    final merchantJson = json['merchants'] ?? json['merchant'];
    if (merchantJson is Map<String, dynamic>) {
      merchantName = merchantJson['name'] as String?;
    } else if (json['merchant_name'] != null) {
      merchantName = json['merchant_name'] as String?;
    }

    return ReceiptModel(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      merchantId: json['merchant_id'] as int?,
      merchantName: merchantName,
      receiptDate: json['receipt_date'] != null
          ? DateTime.tryParse(json['receipt_date'].toString())
          : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  /// Payload untuk insert ke tabel `receipts`.
  Map<String, dynamic> toInsertJson() => {
    'user_id': userId,
    if (merchantId != null) 'merchant_id': merchantId,
    if (receiptDate != null) 'receipt_date': _formatDate(receiptDate!),
    'total_amount': totalAmount,
    if (imageUrl != null) 'image_url': imageUrl,
  };

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
