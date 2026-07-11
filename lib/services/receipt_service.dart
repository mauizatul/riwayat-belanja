import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/receipt_model.dart';
import '../models/receipt_item.dart';

class ReceiptService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Cari merchant berdasarkan nama (case-insensitive).
  /// Jika belum ada, buat merchant baru dan kembalikan id-nya.
  Future<int> findOrCreateMerchantId(String merchantName) async {
    final name = merchantName.trim();

    final existing = await _client
        .from('merchants')
        .select('id')
        .ilike('name', name)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as int;
    }

    final inserted = await _client
        .from('merchants')
        .insert({'name': name})
        .select('id')
        .single();

    return inserted['id'] as int;
  }

  /// Simpan receipt beserta seluruh item-nya.
  /// Melempar [Exception] jika user belum login atau item kosong.
  /// Mengembalikan id receipt yang baru dibuat.
  Future<int> saveReceipt({
    required String merchantName,
    required DateTime? receiptDate,
    required List<ReceiptItem> items,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login.');
    }

    if (items.isEmpty) {
      throw Exception('Minimal harus ada 1 barang.');
    }

    final merchantId = await findOrCreateMerchantId(merchantName);

    final totalAmount = items.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    final receipt = ReceiptModel(
      userId: userId,
      merchantId: merchantId,
      receiptDate: receiptDate,
      totalAmount: totalAmount,
    );

    int? insertedReceiptId;

    try {
      final receiptRow = await _client
          .from('receipts')
          .insert(receipt.toInsertJson())
          .select('id')
          .single();

      insertedReceiptId = receiptRow['id'] as int;

      final itemsPayload = items
          .map((item) => item.toInsertJson(insertedReceiptId!))
          .toList();

      await _client.from('receipt_items').insert(itemsPayload);

      return insertedReceiptId;
    } catch (e) {
      // Rollback: hapus receipt yang sudah terlanjur dibuat
      // jika proses insert item gagal, agar tidak ada data "yatim".
      if (insertedReceiptId != null) {
        await _client.from('receipts').delete().eq('id', insertedReceiptId);
      }
      rethrow;
    }
  }

  /// Ambil semua nama merchant yang pernah dipakai (untuk suggestion
  /// autocomplete di form tambah receipt).
  Future<List<String>> getMerchantNames() async {
    final data = await _client
        .from('merchants')
        .select('name')
        .order('name', ascending: true);

    return (data as List).map((row) => row['name'] as String).toList();
  }

  /// Ambil daftar receipt milik user yang sedang login, lengkap dengan
  /// nama merchant (join ke tabel `merchants`), diurutkan dari yang
  /// terbaru. Dipakai untuk halaman history.
  Future<List<ReceiptModel>> getReceipts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login.');
    }

    final data = await _client
        .from('receipts')
        .select('*, merchants(name)')
        .eq('user_id', userId)
        .order('receipt_date', ascending: false);

    return (data as List)
        .map((json) => ReceiptModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Ambil semua item dari satu receipt, dipakai di halaman detail.
  Future<List<ReceiptItem>> getReceiptItems(int receiptId) async {
    final data = await _client
        .from('receipt_items')
        .select()
        .eq('receipt_id', receiptId)
        .order('id', ascending: true);

    return (data as List)
        .map((json) => ReceiptItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
