import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/item_purchase.dart';
import '../../../providers/item_search_provider.dart';
import '../../../utils/formatters.dart';

class ItemSearchScreen extends StatelessWidget {
  const ItemSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ItemSearchProvider(),
      child: const _ItemSearchView(),
    );
  }
}

class _ItemSearchView extends StatelessWidget {
  const _ItemSearchView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemSearchProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cari Harga Barang')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              onChanged: (value) =>
                  context.read<ItemSearchProvider>().onQueryChanged(value),
              decoration: InputDecoration(
                hintText: 'Ketik nama barang, mis. "Indomie"',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: provider.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => context
                            .read<ItemSearchProvider>()
                            .onQueryChanged(''),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ItemSearchProvider provider) {
    if (provider.query.trim().isEmpty) {
      return _message(
        icon: Icons.search,
        message: 'Ketik nama barang untuk lihat histori harganya.',
      );
    }

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return _message(
        icon: Icons.error_outline,
        message: provider.errorMessage!,
      );
    }

    if (provider.results.isEmpty) {
      return _message(
        icon: Icons.search_off,
        message: 'Tidak ditemukan barang "${provider.query}".',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _ItemPurchaseTile(item: provider.results[index]),
    );
  }

  Widget _message({required IconData icon, required String message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPurchaseTile extends StatelessWidget {
  final ItemPurchase item;

  const _ItemPurchaseTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qtyText = item.qty % 1 == 0
        ? item.qty.toInt().toString()
        : item.qty.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.merchantName != null) item.merchantName!,
                    if (item.receiptDate != null)
                      formatShortDate(item.receiptDate!),
                    'x$qtyText',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(item.unitPrice),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
