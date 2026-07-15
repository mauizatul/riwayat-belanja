import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riwayat_belanjaku/providers/receipt_provider.dart';
import 'package:riwayat_belanjaku/features/home/screens/history_detail_screen.dart';
import 'package:riwayat_belanjaku/features/home/screens/history_list_screen.dart';
import 'history_item.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final receipts = provider.receipts;

    // Cuma tampilkan loading full kalau memang belum ada data sama sekali.
    // Kalau lagi refresh tapi sudah ada data lama, biarkan data lama tetap
    // kelihatan (menghindari layar "kedip" kosong pas reload).
    final showLoading = provider.loading && receipts.isEmpty;

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

        if (showLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (receipts.isEmpty)
          _buildEmptyState(context)
        else
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

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada riwayat belanja',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mulai catat struk belanjamu lewat menu Scan atau Tambah.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
