import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_app_1/providers/receipt_provider.dart';
import 'package:my_app_1/features/home/screens/history_detail_screen.dart';
import 'package:my_app_1/features/home/screens/history_list_screen.dart';
import 'history_item.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final receipts = provider.receipts;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Riwayat Terbaru",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryListScreen()),
                );
              },
              child: const Text("See More"),
            ),
          ],
        ),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: receipts.length > 5 ? 5 : receipts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final receipt = receipts[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryDetailScreen(receipt: receipt),
                    ),
                  );
                },
                child: HistoryItem(receipt: receipt),
              );
            },
          ),
        ),
      ],
    );
  }
}
