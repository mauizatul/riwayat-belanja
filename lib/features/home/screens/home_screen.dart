import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:my_app_1/core/theme/app_text_styles.dart';
import 'package:my_app_1/features/home/screens/history_list_screen.dart';
import 'package:my_app_1/features/home/screens/scan_receipt_screen.dart';
import 'package:my_app_1/features/receipt/screens/add_receipt_screen.dart';
import 'package:my_app_1/providers/receipt_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/system_ui.dart';
import '../widgets/greeting_section.dart';
import '../widgets/history_section.dart';
import '../widgets/menu_card.dart';
import '../widgets/total_expense_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data pertama kali screen ini dibuka.
    // addPostFrameCallback dipakai karena context.read tidak boleh
    // dipanggil langsung di initState sebelum frame pertama selesai build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().loadReceipts();
    });
  }

  Future<void> _openScanReceipt() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ScanReceiptScreen()));

    if (result == true && mounted) {
      context.read<ReceiptProvider>().loadReceipts();
    }
  }

  Future<void> _openAddReceipt() async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddReceiptScreen()));

    // AddReceiptScreen pop(true) kalau simpan sukses.
    if (result == true && mounted) {
      context.read<ReceiptProvider>().loadReceipts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle(AppColors.background),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const GreetingSection(),

              const SizedBox(height: 24),

              const TotalExpenseCard(),

              const SizedBox(height: 32),

              const HistorySection(),

              const SizedBox(height: 32),

              const Text("Menu", style: AppTextStyles.heading2),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: MenuCard(
                      icon: Icons.document_scanner,
                      title: "Scan",
                      color: AppColors.primary,
                      onTap: _openScanReceipt,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MenuCard(
                      icon: Icons.history,
                      title: "Riwayat",
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HistoryListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MenuCard(
                      icon: Icons.add,
                      title: "Tambah",
                      color: AppColors.success,
                      onTap: _openAddReceipt,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
