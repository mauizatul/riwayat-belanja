import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../models/scan_receipt_result.dart';
import '../../../providers/add_receipt_provider.dart';
import '../../../utils/formatters.dart';
import '../widgets/add_receipt_footer.dart';
import '../widgets/merchant_autocomplete_field.dart';
import '../widgets/receipt_item_form_card.dart';

class AddReceiptScreen extends StatelessWidget {
  /// Hasil ekstraksi AI, diisi kalau screen ini dibuka dari alur Scan.
  /// Null kalau dari Tambah Manual.
  final ScanReceiptResult? scanResult;

  /// Foto struk hasil scan, dipakai buat preview & di-upload saat simpan.
  final File? imageFile;

  const AddReceiptScreen({super.key, this.scanResult, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          AddReceiptProvider(scanResult: scanResult, imageFile: imageFile)
            ..loadMerchantSuggestions(),
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

  /// Khusus alur Tambah Manual: user bisa opsional lampirkan foto struk,
  /// baik ambil foto baru atau pilih dari galeri.
  Future<void> _pickManualImage(BuildContext context) async {
    final provider = context.read<AddReceiptProvider>();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 2000,
    );

    if (picked == null) return;
    if (!context.mounted) return;

    provider.setImageFile(File(picked.path));
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
      appBar: AppBar(
        title: Text(
          provider.isFromScan ? 'Koreksi Hasil Scan' : 'Tambah Receipt',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (provider.isFromScan) ...[
                    _ScanResultBanner(imageFile: provider.receiptImageFile),
                    const SizedBox(height: 16),
                  ],

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

                  // Lampirkan foto (opsional), cuma muncul di alur manual --
                  // kalau dari Scan, foto sudah otomatis ada (lihat banner).
                  if (!provider.isFromScan) ...[
                    const SizedBox(height: 16),
                    _ManualPhotoPicker(
                      imageFile: provider.receiptImageFile,
                      onPick: () => _pickManualImage(context),
                      onRemove: () => provider.setImageFile(null),
                    ),
                  ],
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

/// Banner peringatan + thumbnail foto struk, muncul kalau form ini
/// dibuka dari alur Scan (hasil AI, bukan input manual).
class _ScanResultBanner extends StatelessWidget {
  final File? imageFile;

  const _ScanResultBanner({required this.imageFile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageFile != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Hasil scan AI',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Mohon periksa & koreksi dulu sebelum disimpan, '
                  'terutama qty dan harga.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget lampirkan foto struk opsional, khusus alur Tambah Manual.
class _ManualPhotoPicker extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ManualPhotoPicker({
    required this.imageFile,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (imageFile == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Tambahkan Foto Struk (opsional)'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              imageFile!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Foto struk terlampir',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          TextButton(onPressed: onPick, child: const Text('Ganti')),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Hapus foto',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
