import 'dart:ui';
import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';
import '../controller/setting_controller.dart';
import 'auth_view.dart';
import 'recipe_view.dart';
import 'setting_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final authController = AuthController();
  final settingsController = SettingsController();

  @override
  Widget build(BuildContext context) {
    final isDark = settingsController.isDarkMode;

    final bgColor =
    isDark ? const Color(0xFF0F1B12) : const Color(0xFFF4FBF5);

    final cardColor =
    isDark ? const Color(0xFF1B2B20) : Colors.white;

    final textColor =
    isDark ? Colors.white : const Color(0xFF1B5E20);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            children: [

              // ================= HEADER (FIXED) =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // 🍲 RECIPE BUTTON
                  IconButton(
                    icon: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 30,
                      color: Color(0xFF2E7D32),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecipeView(),
                        ),
                      );
                    },
                  ),

                  Row(
                    children: [
                      // 🌙 THEME TOGGLE
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: const Color(0xFF2E7D32),
                        ),
                        onPressed: () {
                          setState(() {
                            settingsController.toggleTheme();
                          });
                        },
                      ),

                      // ⚙️ SETTINGS
                      IconButton(
                        icon: const Icon(
                          Icons.settings,
                          color: Color(0xFF2E7D32),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsView(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ================= TITLE =================
              Text(
                "Welcome to Wasfaty 🌿",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 25),

              // ================= MAIN CARD =================
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFFA5D6A7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_dining_rounded,
                          size: 60,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Your Kitchen Hub",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Explore recipes, save favorites, and share your cooking creations.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RecipeView(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text(
                              "Explore Recipes",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ================= LOGOUT =================
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await authController.logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthView(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFF2E7D32)),
                  label: const Text(
                    "Logout",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}