import 'dart:ui';
import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';
import '../generated/l10n/app_localizations.dart';
import 'auth_view.dart';
import 'category_view.dart'; // ✅ IMPORT OK
import 'setting_view.dart';
import 'restaurent_view.dart';
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final authController = AuthController();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),

          child: Column(
            children: [

              // ================= HEADER =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  IconButton(
                    icon: const Icon(
                      Icons.storefront_rounded,
                      size: 30,
                      color: Color(0xFF2E7D32),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RestaurantView(),
                        ),
                      );
                    },
                  ),

                  // 🍲 CATEGORY BUTTON
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
                          builder: (_) => const CategoryView(), // ✅ FIXED
                        ),
                      );
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

              const SizedBox(height: 20),

              // ================= TITLE =================
              Text(
                t.welcomeHome,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                      color: Theme.of(context).cardColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                      ),
                    ),

                    child: Column(
                      children: [

                        const Icon(
                          Icons.local_dining_rounded,
                          size: 60,
                          color: Color(0xFF2E7D32),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          t.kitchenHub,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          t.homeDescription,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),

                        const SizedBox(height: 20),

                        // ================= BUTTON =================
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CategoryView(), // ✅ FIXED
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
                            label: Text(
                              t.exploreRecipes,
                              style: const TextStyle(
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
                  label: Text(
                    t.logout,
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
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

