import 'package:flutter/material.dart';

import '../../../models/receipt_item.dart';
import '../../../models/receipt_model.dart';
import '../../../services/receipt_service.dart';
import '../../../utils/formatters.dart';

class HistoryDetailScreen extends StatefulWidget {
  final ReceiptModel receipt;

  const HistoryDetailScreen({super.key, required this.receipt});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  final ReceiptService _service = ReceiptService();
  late Future<List<ReceiptItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<ReceiptItem>> _loadItems() {
    final receiptId = widget.receipt.id;
    if (receiptId == null) {
      return Future.value(const []);
    }
    return _service.getReceiptItems(receiptId);
  }

  Future<void> _refresh() async {
    setState(() {
      _itemsFuture = _loadItems();
    });
    await _itemsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Receipt')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ReceiptItem>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text('Gagal memuat item: ${snapshot.error}')),
                ],
              );
            }

            final items = snapshot.data ?? const [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMerchantCard(context, receipt),
                const SizedBox(height: 24),
                Text(
                  'Daftar Barang',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Tidak ada item.')),
                  )
                else
                  ...items.map((item) => _buildItemTile(context, item)),
                const Divider(height: 32),
                _buildTotalRow(context, receipt),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMerchantCard(BuildContext context, ReceiptModel receipt) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.storefront_outlined, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchantName ?? 'Merchant tidak diketahui',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    receipt.receiptDate != null
                        ? formatDate(receipt.receiptDate!)
                        : 'Tanggal tidak diketahui',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, ReceiptItem item) {
    final theme = Theme.of(context);
    final qtyText = item.qty % 1 == 0
        ? item.qty.toInt().toString()
        : item.qty.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$qtyText x ${formatRupiah(item.unitPrice)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatRupiah(item.totalPrice),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, ReceiptModel receipt) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'TOTAL',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          formatRupiah(receipt.totalAmount),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
