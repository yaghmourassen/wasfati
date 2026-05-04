import 'dart:ui';
import 'package:flutter/material.dart';
import '../controller/auth_controller.dart';
import '../generated/l10n/app_localizations.dart';
import 'auth_view.dart';
import 'category_view.dart'; // ✅ IMPORT OK
import 'favorites_view .dart';
import 'setting_view.dart';
import 'restaurent_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'shopping_plan_view.dart';
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {

  @override
  void initState() {
    super.initState();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3185716051823285/7834634897', // TEST ID

      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print("🔥 BANNER LOADED SUCCESSFULLY");
          setState(() {
            _isBannerReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print("Banner failed: $error");
        },
      ),
    );

    _bannerAd.load();
  }
  late BannerAd _bannerAd;
  bool _isBannerReady = false;
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

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FavoritesView(),
                    ),
                  );
                },

                child: ClipRRect(
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

                          // ❤️ BIG ICON (RED)
                          const Icon(
                            Icons.favorite,
                            size: 60,
                            color: Colors.red,
                          ),

                          const SizedBox(height: 12),

                          // TITLE (L10N)
                          Text(
                            t.favoritesTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),

                          const SizedBox(height: 8),

                          // DESCRIPTION (L10N)
                          Text(
                            t.favoritesDesc,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),

                          const SizedBox(height: 20),

                          // BUTTON (THEMED + SMALL HEART)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FavoritesView(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),

                              icon: const Icon(
                                Icons.favorite,
                                size: 18,
                                color: Colors.red,
                              ),

                              label: Text(
                                t.viewFavorites,
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
              ),
              const SizedBox(height: 25),



// ================= SHOPPING PLAN =================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShoppingPlanView(),
                    ),
                  );
                },
                child: ClipRRect(
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
                            Icons.shopping_cart_rounded,
                            size: 60,
                            color: Color(0xFF2E7D32),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            t.shoppingPlan,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            t.shoppingPlanDesc,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ShoppingPlanView(),
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
                              icon: const Icon(Icons.shopping_bag),
                              label: Text(
                                t.shoppingPlan,
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
              ),
              // ================= LOGOUT =================
              const SizedBox(height: 25),

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
              const SizedBox(height: 20),

              if (_isBannerReady)
                Center(
                  child: SizedBox(
                    width: _bannerAd.size.width.toDouble(),
                    height: _bannerAd.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

