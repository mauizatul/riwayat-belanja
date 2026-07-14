import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:riwayat_belanjaku/services/receipt_service.dart';
import 'package:riwayat_belanjaku/features/receipt/screens/add_receipt_screen.dart';

/// Layar perantara untuk alur Scan:
/// 1. Otomatis buka kamera begitu screen ini dibuka.
/// 2. Kirim foto ke Edge Function (AI) buat diekstrak.
/// 3. Lanjut ke AddReceiptScreen yang sudah ke-pre-fill hasil AI.
///
/// Screen ini tidak punya UI form sendiri -- cuma loading/error state,
/// karena tujuannya cuma jembatan antara kamera dan form koreksi.
class ScanReceiptScreen extends StatefulWidget {
  const ScanReceiptScreen({super.key});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> {
  final ImagePicker _picker = ImagePicker();
  final ReceiptService _service = ReceiptService();

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Langsung buka kamera begitu screen ini muncul, tanpa perlu
    // tap tombol lagi.
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndScan());
  }

  Future<void> _captureAndScan() async {
    setState(() {
      _errorMessage = null;
    });

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // kompres, biar upload & kirim ke AI lebih cepat
      maxWidth: 2000,
    );

    if (!mounted) return;

    if (picked == null) {
      // User membatalkan kamera (tidak jadi foto).
      Navigator.of(context).pop();
      return;
    }

    final imageFile = File(picked.path);

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _service.scanReceipt(imageFile);

      if (!mounted) return;

      // Buka form koreksi, lalu TERUSKAN hasil pop-nya (true/false/null)
      // ke Home. Ini penting supaya HomeScreen tau kapan harus reload
      // data, sama seperti alur Tambah Manual.
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              AddReceiptScreen(scanResult: result, imageFile: imageFile),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(saved ?? false);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Gagal memindai struk: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Struk')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildContent(theme),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(ThemeData theme) {
    if (_errorMessage != null) {
      return [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(_errorMessage!, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _captureAndScan,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Foto Ulang'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ];
    }

    return [
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text(
        _isProcessing
            ? 'Membaca struk dengan AI...\nMohon tunggu sebentar.'
            : 'Membuka kamera...',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      ),
    ];
  }
}
