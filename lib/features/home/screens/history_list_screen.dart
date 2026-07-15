import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/receipt_model.dart';
import '../../../providers/receipt_provider.dart';
import '../../../utils/formatters.dart';
import '../widgets/history_item.dart';
import 'history_detail_screen.dart';

/// 1 kelompok receipt dalam bulan yang sama, lengkap dengan total belanja
/// bulan itu.
class _MonthGroup {
  final String label;
  final List<ReceiptModel> receipts;
  final double total;

  _MonthGroup({required this.label, required this.receipts})
    : total = receipts.fold(0, (sum, r) => sum + r.totalAmount);
}

/// Kelompokkan receipt berdasarkan bulan+tahun dari receiptDate.
/// Receipt tanpa tanggal dikumpulkan di grup "Tanpa Tanggal" dan selalu
/// diletakkan paling akhir.
///
/// Catatan: fungsi ini mengasumsikan [receipts] sudah terurut dari yang
/// terbaru (sesuai query ReceiptService.getReceipts()), supaya urutan
/// grup bulan juga otomatis dari yang terbaru.
List<_MonthGroup> _groupByMonth(List<ReceiptModel> receipts) {
  final Map<String, List<ReceiptModel>> grouped = {};
  final List<String> orderedKeys = [];
  const undatedKey = 'Tanpa Tanggal';

  for (final receipt in receipts) {
    final key = receipt.receiptDate != null
        ? formatMonthYear(receipt.receiptDate!)
        : undatedKey;

    if (!grouped.containsKey(key)) {
      grouped[key] = [];
      orderedKeys.add(key);
    }
    grouped[key]!.add(receipt);
  }

  final hasUndated = orderedKeys.remove(undatedKey);

  final result = orderedKeys
      .map((key) => _MonthGroup(label: key, receipts: grouped[key]!))
      .toList();

  if (hasUndated) {
    result.add(_MonthGroup(label: undatedKey, receipts: grouped[undatedKey]!));
  }

  return result;
}

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().loadReceipts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Semua Riwayat"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => context.read<ReceiptProvider>().loadReceipts(),
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(ReceiptProvider provider) {
    final receipts = provider.receipts;

    if (provider.loading && receipts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && receipts.isEmpty) {
      return _scrollableMessage(
        icon: Icons.error_outline,
        message: provider.errorMessage!,
      );
    }

    if (receipts.isEmpty) {
      return _scrollableMessage(
        icon: Icons.receipt_long_outlined,
        message: 'Belum ada riwayat receipt.\nYuk mulai catat belanjaanmu!',
      );
    }

    final groups = _groupByMonth(receipts);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, index) =>
          _buildMonthSection(context, groups[index]),
    );
  }

  /// Wrapper ListView (bukan Center biasa) supaya RefreshIndicator tetap
  /// bisa ditarik walau isinya cuma pesan kosong/error.
  Widget _scrollableMessage({required IconData icon, required String message}) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(icon, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSection(BuildContext context, _MonthGroup group) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatRupiah(group.total),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...group.receipts.map(
          (receipt) => Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryDetailScreen(receipt: receipt),
                    ),
                  );
                },
                child: HistoryItem(receipt: receipt),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ],
    );
  }
}
