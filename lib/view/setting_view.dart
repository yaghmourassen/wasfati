import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/setting_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../view/favorites_view .dart';
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

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

            // ================= THEME CARD =================
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: SwitchListTile(
                title: Text(
                  isDark ? t.darkMode : t.lightMode,
                ),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                ),
                value: isDark,
                onChanged: (value) {
                  controller.toggleTheme();
                },
              ),
            ),

            const SizedBox(height: 15),

            // ================= LANGUAGE CARD =================
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(t.language),

                // 🌍 current language
                subtitle: Text(
                  controller.locale.languageCode == 'ar'
                      ? t.arabic
                      : t.english,
                ),

                trailing: DropdownButton<String>(
                  value: controller.locale.languageCode,
                  items: [
                    DropdownMenuItem(
                      value: "en",
                      child: Text(t.english),
                    ),
                    DropdownMenuItem(
                      value: "ar",
                      child: Text(t.arabic),
                    ),
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

            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: Text(t.favorites ?? "Favorites"),
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
          ],
        ),
      ),
    );

  }

}