import 'package:flutter/material.dart';

import 'package:riwayat_belanjaku/models/receipt_model.dart';
import 'package:riwayat_belanjaku/utils/formatters.dart';

class HistoryItem extends StatelessWidget {
  final ReceiptModel receipt;

  const HistoryItem({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final date = receipt.receiptDate;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue.shade100,
        child: const Icon(Icons.receipt_long, color: Colors.blue),
      ),
      title: Text(
        receipt.merchantName ?? 'Merchant tidak diketahui',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(date != null ? formatShortDate(date) : '-'),
      trailing: Text(
        formatRupiah(receipt.totalAmount),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
