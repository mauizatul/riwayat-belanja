import 'package:flutter/material.dart';
import 'package:my_app_1/providers/receipt_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TotalExpenseCard extends StatelessWidget {
  const TotalExpenseCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final totalExpense = provider.totalExpense;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Semua Pengeluaran",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            formatter.format(totalExpense),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 30,
            ),
          ),
        ],
      ),
    );
  }
}
