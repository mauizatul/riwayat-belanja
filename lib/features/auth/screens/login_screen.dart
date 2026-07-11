import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../../home/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();

  final password = TextEditingController();

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                setState(() {
                  loading = true;
                });

                try {
                  await AuthService().login(
                    email: email.text,
                    password: password.text,
                  );

                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    // ignore: use_build_context_synchronously
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }

                setState(() {
                  loading = false;
                });
              },

              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("LOGIN"),
            ),
          ],
        ),
      ),
    );
  }
}
