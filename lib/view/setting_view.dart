import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/auth_controller.dart';
import '../controller/setting_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../view/favorites_view .dart';
import '../core/user_session.dart';
import 'auth_view.dart';
import 'favorites_view .dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  // 🌐 open website
  Future<void> _openWebsite() async {
    final Uri url = Uri.parse("https://yaghmourassen.github.io/My-Webpage/");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SettingsController>(context);
    final isDark = controller.isDarkMode;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(t.settings),
        backgroundColor: const Color(0xFF2E7D32),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ================= THEME =================
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: SwitchListTile(
                title: Text(isDark ? t.darkMode : t.lightMode),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                value: isDark,
                onChanged: (_) => controller.toggleTheme(),
              ),
            ),

            const SizedBox(height: 15),

            // ================= LANGUAGE =================
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(t.language),

                trailing: DropdownButton<String>(
                  value: controller.locale.languageCode,
                  items: [
                    DropdownMenuItem(value: "en", child: Text(t.english)),
                    DropdownMenuItem(value: "ar", child: Text(t.arabic)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setLocale(Locale(value));
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 15),

            // ================= FAVORITES =================
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text(t.favorites),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesView(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            // ================= PRO =================
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.amber),
                title: Text(t.upgradePro),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t.comingSoon)),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            // ================= ABOUT (FIXED SIZE) =================
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(t.about),

                trailing: const Icon(Icons.open_in_new),
                onTap: _openWebsite,
              ),
            ),

            const SizedBox(height: 15),

            // ================= PUSH LOGOUT TO BOTTOM =================
            const Spacer(),

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(t.logout),
                onTap: () async {
                  final authController = AuthController();

                  await authController.logout();

                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthView()),
                          (route) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}