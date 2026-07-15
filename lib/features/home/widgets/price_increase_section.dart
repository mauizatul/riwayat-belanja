import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/price_change.dart';
import '../../../providers/price_insight_provider.dart';
import '../../../utils/formatters.dart';

/// Section opsional di Home yang nampilin barang-barang yang harganya
/// naik (dibanding pembelian sebelumnya, DI MERCHANT YANG SAMA).
/// Sengaja disembunyikan total (bukan nampilin "tidak ada data") kalau
/// tidak ada insight, supaya tidak bikin Home penuh section kosong.
class PriceIncreaseSection extends StatelessWidget {
  const PriceIncreaseSection({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceInsightProvider>();

    if (provider.priceIncreases.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final topChanges = provider.priceIncreases.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, size: 20, color: theme.colorScheme.error),
            const SizedBox(width: 6),
            const Text(
              "Kenaikan Harga",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: topChanges
                .map((change) => _PriceChangeTile(change: change))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PriceChangeTile extends StatelessWidget {
  final PriceChange change;

  const _PriceChangeTile({required this.change});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.itemName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${change.merchantName} · ${formatRupiah(change.oldPrice)} → ${formatRupiah(change.newPrice)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${change.percentChange.toStringAsFixed(0)}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
