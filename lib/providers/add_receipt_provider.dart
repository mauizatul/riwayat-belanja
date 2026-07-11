import 'package:flutter/material.dart';

import '../models/receipt_item.dart';
import '../services/receipt_service.dart';
import '../utils/formatters.dart';

/// Representasi 1 baris input barang di form (belum tersimpan ke DB).
class ReceiptItemInput {
  final Key key = UniqueKey();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  double qty;

  ReceiptItemInput({this.qty = 1});

  double get unitPrice => parseCurrencyToDouble(priceController.text);
  double get totalPrice => qty * unitPrice;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class AddReceiptProvider extends ChangeNotifier {
  final ReceiptService _receiptService = ReceiptService();

  final TextEditingController merchantController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final List<ReceiptItemInput> items = [ReceiptItemInput()];

  bool isSaving = false;
  String? errorMessage;

  List<String> merchantSuggestions = [];
  bool isLoadingMerchants = false;

  /// Ambil daftar nama merchant yang sudah pernah dipakai, buat suggestion
  /// di autocomplete. Kalau gagal (mis. offline), diamkan saja karena ini
  /// cuma fitur bantu, bukan hal yang wajib berhasil.
  Future<void> loadMerchantSuggestions() async {
    isLoadingMerchants = true;
    notifyListeners();

    try {
      merchantSuggestions = await _receiptService.getMerchantNames();
    } catch (_) {
      merchantSuggestions = [];
    }

    isLoadingMerchants = false;
    notifyListeners();
  }

  double get totalAmount =>
      items.fold<double>(0, (sum, item) => sum + item.totalPrice);

  void setDate(DateTime date) {
    selectedDate = date;
    notifyListeners();
  }

  void addItem() {
    items.add(ReceiptItemInput());
    notifyListeners();
  }

  void removeItem(int index) {
    if (items.length == 1) return; // minimal 1 barang
    items[index].dispose();
    items.removeAt(index);
    notifyListeners();
  }

  void incrementQty(int index) {
    items[index].qty += 1;
    notifyListeners();
  }

  void decrementQty(int index) {
    if (items[index].qty > 1) {
      items[index].qty -= 1;
      notifyListeners();
    }
  }

  /// Dipanggil dari onChanged text field (nama/harga) agar total ter-update.
  void onItemFieldChanged() {
    notifyListeners();
  }

  String? _validate() {
    if (merchantController.text.trim().isEmpty) {
      return 'Nama merchant tidak boleh kosong.';
    }
    for (final item in items) {
      if (item.nameController.text.trim().isEmpty) {
        return 'Nama barang tidak boleh kosong.';
      }
      if (item.unitPrice <= 0) {
        return 'Harga barang harus lebih dari 0.';
      }
    }
    return null;
  }

  Future<bool> saveReceipt() async {
    final validationError = _validate();
    if (validationError != null) {
      errorMessage = validationError;
      notifyListeners();
      return false;
    }

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final receiptItems = items
          .map(
            (item) => ReceiptItem(
              itemName: item.nameController.text.trim(),
              qty: item.qty,
              unitPrice: item.unitPrice,
            ),
          )
          .toList();

      await _receiptService.saveReceipt(
        merchantName: merchantController.text.trim(),
        receiptDate: selectedDate,
        items: receiptItems,
      );

      isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSaving = false;
      errorMessage = 'Gagal menyimpan receipt: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    merchantController.dispose();
    for (final item in items) {
      item.dispose();
    }
    super.dispose();
  }
}
