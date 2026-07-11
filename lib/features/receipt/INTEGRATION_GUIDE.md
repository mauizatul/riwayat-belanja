// INTEGRASI DENGAN HOME SCREEN
// Contoh cara memanggil AddReceiptScreen dari HomeScreen

import 'package:flutter/material.dart';
import '../receipt/screens/add_receipt_screen.dart';

// Tambahkan button di HomeScreen untuk membuka halaman Add Receipt:

class HomeScreenIntegrationExample {
// Method untuk membuka Add Receipt Screen
static void openAddReceiptScreen(BuildContext context) {
Navigator.of(context).push(
MaterialPageRoute(
builder: (context) => const AddReceiptScreen(),
fullscreenDialog: true, // Optional: untuk modal presentation
),
).then((result) {
// Handle hasil setelah add receipt screen ditutup
if (result == true) {
// Receipt berhasil ditambahkan, reload list jika diperlukan
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('Receipt berhasil ditambahkan'),
duration: Duration(seconds: 2),
),
);
}
});
}
}

// CONTOH INTEGRASI DI FLOATING ACTION BUTTON:
/\*
class HomeScreen extends StatefulWidget {
const HomeScreen({super.key});

@override
State<HomeScreen> createState() => \_HomeScreenState();
}

class \_HomeScreenState extends State<HomeScreen> {
@override
Widget build(BuildContext context) {
return Scaffold(
// ... existing code ...
floatingActionButton: FloatingActionButton(
onPressed: () {
Navigator.of(context).push(
MaterialPageRoute(
builder: (context) => const AddReceiptScreen(),
),
);
},
child: const Icon(Icons.add),
),
);
}
}
\*/

// CONTOH INTEGRASI DI APP BAR ACTION BUTTON:
/_
AppBar(
title: const Text('My Receipts'),
actions: [
IconButton(
icon: const Icon(Icons.add),
onPressed: () {
Navigator.of(context).push(
MaterialPageRoute(
builder: (context) => const AddReceiptScreen(),
),
);
},
),
],
)
_/
