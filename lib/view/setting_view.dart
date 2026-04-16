import 'package:flutter/material.dart';
import '../controller/setting_controller.dart';


/// ===============================
/// 🌿 SETTINGS VIEW (UI LAYER)
/// ===============================
/// Connected to SettingsController
/// - Theme toggle
/// - Language switch
/// ===============================

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final SettingsController controller = SettingsController();

  @override
  Widget build(BuildContext context) {
    final isDark = controller.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1B12)
          : const Color(0xFFF4FBF5),

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
                color: isDark ? const Color(0xFF1B2B20) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: SwitchListTile(
                title: const Text("Dark Mode"),
                secondary: const Icon(Icons.dark_mode),
                value: isDark,
                onChanged: (value) {
                  setState(() {
                    controller.toggleTheme();
                  });
                },
              ),
            ),

            const SizedBox(height: 15),

            // ================= LANGUAGE CARD =================
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2B20) : Colors.white,
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
                      setState(() {
                        controller.setLanguage(value);
                      });
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