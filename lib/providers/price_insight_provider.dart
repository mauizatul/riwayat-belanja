import 'package:flutter/material.dart';

import '../models/price_change.dart';
import '../services/receipt_service.dart';

class PriceInsightProvider extends ChangeNotifier {
  final ReceiptService _service = ReceiptService();

  List<PriceChange> priceIncreases = [];
  bool loading = false;
  String? errorMessage;

  Future<void> loadPriceIncreases() async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      priceIncreases = await _service.getPriceIncreases();
    } catch (e) {
      errorMessage = 'Gagal memuat data harga: ${e.toString()}';
    }

    loading = false;
    notifyListeners();
  }
}
