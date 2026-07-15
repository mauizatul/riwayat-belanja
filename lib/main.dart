import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:riwayat_belanjaku/providers/price_insight_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'providers/receipt_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => PriceInsightProvider()), // baru
      ],
      child: const ReceiptApp(),
    ),
  );
}

class ReceiptApp extends StatelessWidget {
  const ReceiptApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      title: 'Receipt AI',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      home: session == null ? const LoginScreen() : const HomeScreen(),
    );
  }
}
