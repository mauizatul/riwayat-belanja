import 'dart:io';

import 'package:flutter/material.dart';

import '../models/receipt_item.dart';
import '../models/scan_receipt_result.dart';
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

  final List<ReceiptItemInput> items = [];

  /// Foto struk. Diisi dari hasil scan (kalau alur Scan), atau bisa juga
  /// dipilih manual belakangan lewat [setImageFile] (kalau alur Tambah
  /// Manual dan user mau tetap lampirkan foto).
  File? receiptImageFile;

  /// True kalau form ini dibuka dari alur Scan (bukan Tambah Manual),
  /// dipakai buat nampilin banner "hasil AI, mohon dicek" di UI.
  final bool isFromScan;

  bool isSaving = false;
  String? errorMessage;

  List<String> merchantSuggestions = [];
  bool isLoadingMerchants = false;

  AddReceiptProvider({ScanReceiptResult? scanResult, File? imageFile})
    : receiptImageFile = imageFile,
      isFromScan = scanResult != null {
    if (scanResult != null) {
      _prefillFromScan(scanResult);
    } else {
      items.add(ReceiptItemInput());
    }
  }

  void _prefillFromScan(ScanReceiptResult result) {
    merchantController.text = result.merchantName;

    if (result.receiptDate != null) {
      selectedDate = result.receiptDate!;
    }

    if (result.items.isEmpty) {
      items.add(ReceiptItemInput());
      return;
    }

    for (final scanned in result.items) {
      final input = ReceiptItemInput(qty: scanned.qty > 0 ? scanned.qty : 1);
      input.nameController.text = scanned.itemName;
      if (scanned.unitPrice > 0) {
        input.priceController.text = formatPriceInput(scanned.unitPrice);
      }
      items.add(input);
    }
  }

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

  /// Set/ganti/hapus foto struk secara manual (dipakai di alur Tambah
  /// Manual). Kirim null untuk menghapus foto yang sudah dipilih.
  void setImageFile(File? file) {
    receiptImageFile = file;
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
      // Upload foto dulu (kalau ada) sebelum insert ke receipts,
      // supaya kolom image_url langsung terisi path-nya.
      String? imagePath;
      if (receiptImageFile != null) {
        imagePath = await _receiptService.uploadReceiptImage(receiptImageFile!);
      }

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
        imagePath: imagePath,
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
