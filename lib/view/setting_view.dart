import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/setting_controller.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SettingsController>(context);
    final isDark = controller.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: const Text("Settings"),
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
                  isDark ? "Dark Mode" : "Light Mode",
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
                title: const Text("Language"),
                subtitle: Text(controller.language),

                trailing: DropdownButton<String>(
                  value: controller.language,
                  items: const [
                    DropdownMenuItem(
                      value: "EN",
                      child: Text("English"),
                    ),
                    DropdownMenuItem(
                      value: "AR",
                      child: Text("Arabic"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      controller.setLanguage(value);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}