import 'package:flutter/material.dart';

import 'package:my_app_1/models/receipt_model.dart';
import 'package:my_app_1/services/receipt_service.dart';

class ReceiptProvider extends ChangeNotifier {
  final ReceiptService _service = ReceiptService();

  List<ReceiptModel> _receipts = [];
  bool _loading = false;
  String? _errorMessage;

  List<ReceiptModel> get receipts => _receipts;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;

  double get totalExpense {
    double total = 0;
    for (final receipt in _receipts) {
      total += receipt.totalAmount;
    }
    return total;
  }

  Future<void> loadReceipts() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _receipts = await _service.getReceipts();
    } catch (e) {
      _errorMessage = 'Gagal memuat receipt: ${e.toString()}';
    }

    _loading = false;
    notifyListeners();
  }
}
