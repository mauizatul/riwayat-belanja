import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/receipt_model.dart';
import '../models/receipt_item.dart';
import '../models/scan_receipt_result.dart';
import '../models/item_purchase.dart';
import '../models/price_change.dart';

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
    String? imagePath,
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
      imageUrl: imagePath,
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

  /// Upload foto struk ke bucket `receipt-images`.
  /// Path yang dipakai: `{user_id}/{timestamp}.{ext}`, sesuai RLS policy
  /// yang sudah kita setup (folder pertama harus = auth.uid()).
  /// Mengembalikan PATH-nya (bukan URL), karena bucket-nya private.
  Future<String> uploadReceiptImage(File imageFile) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login.');
    }

    final fileExt = imageFile.path.split('.').last.toLowerCase();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = '$userId/$fileName';

    await _client.storage.from('receipt-images').upload(path, imageFile);

    return path;
  }

  /// Generate signed URL (berlaku 1 jam) dari path yang tersimpan di
  /// `image_url`, dipakai untuk benar-benar menampilkan foto struk
  /// (karena bucket-nya private, tidak bisa diakses lewat URL biasa).
  Future<String> getReceiptImageUrl(String path) {
    return _client.storage.from('receipt-images').createSignedUrl(path, 3600);
  }

  /// Kirim foto struk ke Edge Function `scan-receipt`, dapat balik hasil
  /// ekstraksi AI: nama merchant, tanggal, dan daftar barang.
  Future<ScanReceiptResult> scanReceipt(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _guessMimeType(imageFile.path);

    final response = await _client.functions.invoke(
      'scan-receipt',
      body: {'image_base64': base64Image, 'mime_type': mimeType},
    );

    if (response.status != 200) {
      final data = response.data;
      final errorMessage = (data is Map && data['error'] != null)
          ? data['error']
          : null;
      throw Exception(
        errorMessage ?? 'Gagal memindai struk (status ${response.status}).',
      );
    }

    final data = response.data as Map<String, dynamic>;
    return ScanReceiptResult.fromJson(data['data'] as Map<String, dynamic>);
  }

  String _guessMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Cari histori pembelian barang berdasarkan nama (partial match,
  /// case-insensitive), lengkap dengan tanggal & merchant-nya.
  /// Diurutkan dari yang terbaru dibeli.
  Future<List<ItemPurchase>> searchItemHistory(String query) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login.');
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final data = await _client
        .from('receipt_items')
        .select(
          'item_name, qty, unit_price, receipts!inner(receipt_date, user_id, merchants(name))',
        )
        .eq('receipts.user_id', userId)
        .ilike('item_name', '%$trimmed%');

    final items = (data as List)
        .map((json) => ItemPurchase.fromJson(json as Map<String, dynamic>))
        .toList();

    // Urutkan terbaru dulu. Yang tanpa tanggal ditaruh paling akhir.
    items.sort((a, b) {
      if (a.receiptDate == null && b.receiptDate == null) return 0;
      if (a.receiptDate == null) return 1;
      if (b.receiptDate == null) return -1;
      return b.receiptDate!.compareTo(a.receiptDate!);
    });

    return items;
  }

  /// Deteksi barang yang harganya naik, dibandingkan 2 pembelian
  /// TERAKHIR di merchant yang SAMA (bukan sekadar nama barang sama),
  /// supaya tidak salah kaprah membandingkan harga antar toko berbeda.
  /// Diurutkan dari kenaikan persentase terbesar.
  Future<List<PriceChange>> getPriceIncreases() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User belum login.');
    }

    final data = await _client
        .from('receipt_items')
        .select(
          'item_name, qty, unit_price, receipts!inner(receipt_date, user_id, merchants(name))',
        )
        .eq('receipts.user_id', userId);

    final items = (data as List)
        .map((json) => ItemPurchase.fromJson(json as Map<String, dynamic>))
        .where(
          (item) =>
              item.receiptDate != null &&
              item.merchantName != null &&
              item.merchantName!.isNotEmpty &&
              item.unitPrice > 0,
        )
        .toList();

    // Kelompokkan per (nama barang + merchant), case-insensitive.
    final Map<String, List<ItemPurchase>> grouped = {};
    for (final item in items) {
      final key =
          '${item.itemName.trim().toLowerCase()}|${item.merchantName!.trim().toLowerCase()}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final List<PriceChange> changes = [];

    for (final group in grouped.values) {
      if (group.length < 2) continue;

      group.sort((a, b) => a.receiptDate!.compareTo(b.receiptDate!));

      final latest = group.last;
      final previous = group[group.length - 2];

      if (latest.unitPrice > previous.unitPrice) {
        changes.add(
          PriceChange(
            itemName: latest.itemName,
            merchantName: latest.merchantName!,
            oldPrice: previous.unitPrice,
            newPrice: latest.unitPrice,
            oldDate: previous.receiptDate!,
            newDate: latest.receiptDate!,
          ),
        );
      }
    }

    changes.sort((a, b) => b.percentChange.compareTo(a.percentChange));

    return changes;
  }
}
