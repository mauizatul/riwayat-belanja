import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/add_receipt_provider.dart';
import '../../../utils/formatters.dart';
import '../widgets/add_receipt_footer.dart';
import '../widgets/merchant_autocomplete_field.dart';
import '../widgets/receipt_item_form_card.dart';

class AddReceiptScreen extends StatelessWidget {
  const AddReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddReceiptProvider()..loadMerchantSuggestions(),
      child: const _AddReceiptView(),
    );
  }
}

class _AddReceiptView extends StatelessWidget {
  const _AddReceiptView();

  Future<void> _pickDate(BuildContext context) async {
    final provider = context.read<AddReceiptProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      provider.setDate(picked);
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final provider = context.read<AddReceiptProvider>();
    final success = await provider.saveReceipt();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt berhasil disimpan')),
      );
      Navigator.of(context).pop(true);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddReceiptProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Receipt')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama merchant (autocomplete + bisa ketik manual)
                  MerchantAutocompleteField(provider: provider),
                  const SizedBox(height: 16),

                  // Tanggal
                  InkWell(
                    onTap: () => _pickDate(context),
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tanggal',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(formatDate(provider.selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Daftar Barang',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Daftar input barang
                  ...List.generate(provider.items.length, (index) {
                    final item = provider.items[index];
                    return ReceiptItemFormCard(
                      key: item.key,
                      index: index,
                      item: item,
                      canDelete: provider.items.length > 1,
                      onIncrement: () => provider.incrementQty(index),
                      onDecrement: () => provider.decrementQty(index),
                      onDelete: () => provider.removeItem(index),
                      onChanged: provider.onItemFieldChanged,
                    );
                  }),

                  OutlinedButton.icon(
                    onPressed: provider.addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Barang'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Total + tombol simpan
          AddReceiptFooter(
            total: provider.totalAmount,
            isSaving: provider.isSaving,
            onSave: () => _handleSave(context),
          ),
        ],
      ),
    );
  }
}
