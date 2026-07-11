import 'package:flutter/material.dart';
import 'package:my_app_1/core/theme/app_colors.dart';
import 'package:my_app_1/core/theme/app_text_styles.dart';

import '../../../services/profile_service.dart';

class GreetingSection extends StatelessWidget {
  const GreetingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: ProfileService().getFullName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Halo...", style: AppTextStyles.heading2),
              SizedBox(height: 6),
              Text(
                "Selamat datang kembali",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          );
        }

        if (snapshot.hasError) {
          return const Text("Gagal mengambil data");
        }

        final name = snapshot.data ?? "Guest";

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Halo, $name 👋", style: AppTextStyles.heading2),
            const SizedBox(height: 6),
            const Text(
              "Selamat datang kembali",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        );
      },
    );
  }
}
