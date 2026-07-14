import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:riwayat_belanjaku/providers/receipt_provider.dart';
import 'package:riwayat_belanjaku/features/home/widgets/history_item.dart';
import 'package:riwayat_belanjaku/features/home/screens/history_detail_screen.dart';

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
    final receipts = provider.receipts;

    return Scaffold(
      appBar: AppBar(title: const Text("Semua Riwayat"), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () => context.read<ReceiptProvider>().loadReceipts(),
        child: _buildBody(provider, receipts),
      ),
    );
  }

  Widget _buildBody(ReceiptProvider provider, List receipts) {
    if (provider.loading && receipts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && receipts.isEmpty) {
      return ListView(
        // dibungkus ListView biar RefreshIndicator tetap bisa ditarik
        // walau isinya cuma pesan error.
        children: [
          const SizedBox(height: 120),
          Center(child: Text(provider.errorMessage!)),
        ],
      );
    }

    if (receipts.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Belum ada riwayat receipt.')),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: receipts.length,
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
    );
  }
}
