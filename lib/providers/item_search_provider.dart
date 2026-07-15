import 'dart:async';

import 'package:flutter/material.dart';

import '../models/item_purchase.dart';
import '../services/receipt_service.dart';

class ItemSearchProvider extends ChangeNotifier {
  final ReceiptService _service = ReceiptService();

  String query = '';
  List<ItemPurchase> results = [];
  bool loading = false;
  String? errorMessage;

  Timer? _debounce;

  /// Dipanggil dari onChanged text field search. Pakai debounce 400ms
  /// supaya tidak nge-hit database di setiap ketikan.
  void onQueryChanged(String value) {
    query = value;
    notifyListeners();

    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      results = [];
      errorMessage = null;
      loading = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String keyword) async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      results = await _service.searchItemHistory(keyword);
    } catch (e) {
      errorMessage = 'Gagal mencari: ${e.toString()}';
    }

    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
