// Contoh penggunaan Add Receipt UI

import 'package:flutter/material.dart';
import 'package:my_app_1/features/receipt/screens/add_receipt_screen.dart';

// Untuk membuka halaman Add Receipt dari screen lain:

class ExampleUsage extends StatelessWidget {
const ExampleUsage({super.key});

@override
Widget build(BuildContext context) {
return ElevatedButton(
onPressed: () {
Navigator.of(context).push(
MaterialPageRoute(
builder: (context) => const AddReceiptScreen(),
),
);
},
child: const Text('Tambah Receipt'),
);
}
}

/\*
FITUR YANG TERSEDIA:

1. HALAMAN UTAMA (AddReceiptScreen):
   - Form untuk input receipt secara manual
   - Validasi input data
   - Datepicker untuk memilih tanggal receipt
   - Loading indicator saat menyimpan
   - Success/error messages

2. WIDGET REUSABLE:

   a. ReceiptFormField
   - Input field yang customizable
   - Validasi otomatis
   - Icon prefix
   - Support multiple line input
     Contoh penggunaan:

   ```
   ReceiptFormField(
     label: 'Nama Merchant',
     hint: 'Contoh: Supermarket ABC',
     prefixIcon: Icons.store,
     controller: _merchantNameController,
     validator: (value) {
       if (value?.isEmpty ?? true) return 'Tidak boleh kosong';
       return null;
     },
   )
   ```

   b. ReceiptDatePickerField
   - Datepicker yang reusable
   - Format tanggal: dd MMM yyyy
     Contoh penggunaan:

   ```
   ReceiptDatePickerField(
     label: 'Tanggal Receipt',
     initialDate: DateTime.now(),
     onDateChanged: (date) {
       print('Selected date: $date');
     },
   )
   ```

   c. ReceiptSummaryCard
   - Menampilkan summary receipt
   - Format currency otomatis
   - Support kategori dan deskripsi
     Contoh penggunaan:

   ```
   ReceiptSummaryCard(
     merchantName: 'Supermarket ABC',
     receiptDate: DateTime.now(),
     totalAmount: 125000,
     category: 'Groceries',
     description: 'Belanja mingguan',
   )
   ```

3. INTEGRASI DENGAN PROVIDER:
   Provider ini sudah tersedia: ReceiptProvider
   - loadReceipts(): Muat daftar receipt
   - receipts: Akses list receipt
   - totalExpense: Total pengeluaran

4. DESIGN SYSTEM:
   Menggunakan:
   - AppColors: Warna konsisten
   - AppTextStyles: Typography konsisten
   - AppSpacing: Spacing konsisten (xs, sm, md, lg, xl, xxl)

5. TODO - IMPLEMENTASI SELANJUTNYA:
   - Method untuk save receipt ke Supabase
   - Edit receipt functionality
   - Delete receipt functionality
   - Upload receipt image
   - OCR untuk scan receipt
     \*/
