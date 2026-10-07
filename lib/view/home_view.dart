
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
final theme = Theme.of(context);

const green = Color(0xFF2E7D32);

return Scaffold(
backgroundColor: theme.scaffoldBackgroundColor,

body: SafeArea(
child: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 18,
),

child: Column(
children: [

// =========================================================
// HEADER
// =========================================================

Row(
children: [

// APP ICON
Container(
width: 48,
height: 48,
decoration: BoxDecoration(
color: green.withOpacity(0.10),
borderRadius: BorderRadius.circular(16),
),
child: const Icon(
Icons.restaurant_rounded,
color: green,
size: 27,
),
),

const SizedBox(width: 12),

// TITLE
Expanded(
child: Text(
t.welcomeHome,
style: theme.textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
),
),
),

// RESTAURANT
_headerIconButton(
context,
Icons.storefront_rounded,
() {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const RestaurantView(),
),
);
},
),

const SizedBox(width: 7),

// CATEGORY
_headerIconButton(
context,
Icons.restaurant_menu_rounded,
() {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const CategoryView(),
),
);
},
),

const SizedBox(width: 7),

// SETTINGS
_headerIconButton(
context,
Icons.settings_rounded,
() {
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

const SizedBox(height: 26),

// =========================================================
// MAIN WELCOME CARD
// =========================================================

Container(
width: double.infinity,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(28),
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Color(0xFF388E3C),
Color(0xFF1B5E20),
],
),
boxShadow: [
BoxShadow(
color: green.withOpacity(0.20),
blurRadius: 25,
offset: const Offset(0, 10),
),
],
),

child: Stack(
children: [

// Decorative background icon
Positioned(
right: -25,
top: -25,
child: Icon(
Icons.restaurant_rounded,
size: 150,
color: Colors.white.withOpacity(0.07),
),
),

Padding(
padding: const EdgeInsets.all(24),

child: Column(
crossAxisAlignment: CrossAxisAlignment.center,
children: [

Container(
width: 72,
height: 72,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.14),
shape: BoxShape.circle,
),
child: const Icon(
Icons.local_dining_rounded,
size: 38,
color: Colors.white,
),
),

const SizedBox(height: 18),

Text(
t.kitchenHub,
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.white,
fontSize: 21,
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 10),

Text(
t.homeDescription,
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white.withOpacity(0.88),
fontSize: 14,
height: 1.5,
),
),

const SizedBox(height: 22),

// EXPLORE BUTTON
SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton.icon(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const CategoryView(),
),
);
},

style: ElevatedButton.styleFrom(
backgroundColor: Colors.white,
foregroundColor: green,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
),

icon: const Icon(
Icons.explore_rounded,
size: 21,
),

label: Text(
t.exploreRecipes,
style: const TextStyle(
fontWeight: FontWeight.w800,
),
),
),
),
],
),
),
],
),
),

const SizedBox(height: 26),

// =========================================================
// FAVORITES CARD
// =========================================================

_buildFeatureCard(
context: context,
icon: Icons.favorite_rounded,
iconColor: Colors.red,
title: t.favoritesTitle,
description: t.favoritesDesc,
buttonText: t.viewFavorites,
buttonIcon: Icons.favorite_rounded,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => FavoritesView(),
),
);
},
),

const SizedBox(height: 16),

// =========================================================
// SHOPPING PLAN CARD
// =========================================================

_buildFeatureCard(
context: context,
icon: Icons.shopping_cart_rounded,
iconColor: green,
title: t.shoppingPlan,
description: t.shoppingPlanDesc,
buttonText: t.shoppingPlan,
buttonIcon: Icons.shopping_bag_rounded,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const ShoppingPlanView(),
),
);
},
),

const SizedBox(height: 26),

// =========================================================
// LOGOUT
// =========================================================

SizedBox(
width: double.infinity,
height: 50,
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

style: OutlinedButton.styleFrom(
foregroundColor: green,
side: BorderSide(
color: green.withOpacity(0.30),
),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
),

icon: const Icon(
Icons.logout_rounded,
size: 20,
),

label: Text(
t.logout,
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
),
),

const SizedBox(height: 22),

// =========================================================
// BANNER
// =========================================================

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

// =========================================================
// HEADER ICON
// =========================================================

Widget _headerIconButton(
BuildContext context,
IconData icon,
VoidCallback onPressed,
) {
final theme = Theme.of(context);

return Material(
color: theme.cardColor,
borderRadius: BorderRadius.circular(14),

child: InkWell(
borderRadius: BorderRadius.circular(14),
onTap: onPressed,

child: SizedBox(
width: 42,
height: 42,

child: Icon(
icon,
size: 20,
color: const Color(0xFF2E7D32),
),
),
),
);
}

// =========================================================
// FEATURE CARD
// =========================================================

Widget _buildFeatureCard({
required BuildContext context,
required IconData icon,
required Color iconColor,
required String title,
required String description,
required String buttonText,
required IconData buttonIcon,
required VoidCallback onPressed,
}) {
final theme = Theme.of(context);

return Container(
width: double.infinity,

padding: const EdgeInsets.all(18),

decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(22),

border: Border.all(
color: theme.colorScheme.primary.withOpacity(0.08),
),

boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 15,
offset: const Offset(0, 6),
),
],
),

child: Column(
children: [

// ICON
Container(
width: 58,
height: 58,

decoration: BoxDecoration(
color: iconColor.withOpacity(0.10),
borderRadius: BorderRadius.circular(17),
),

child: Icon(
icon,
size: 29,
color: iconColor,
),
),

const SizedBox(height: 14),

// TITLE
Text(
title,
textAlign: TextAlign.center,
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 7),

// DESCRIPTION
Text(
description,
textAlign: TextAlign.center,
style: theme.textTheme.bodySmall?.copyWith(
height: 1.45,
color: theme.textTheme.bodySmall?.color
    ?.withOpacity(0.65),
),
),

const SizedBox(height: 17),

// BUTTON
SizedBox(
width: double.infinity,
height: 46,

child: ElevatedButton.icon(
onPressed: onPressed,

style: ElevatedButton.styleFrom(
backgroundColor:
theme.colorScheme.primary,
foregroundColor: Colors.white,
elevation: 0,

shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
),

icon: Icon(
buttonIcon,
size: 18,
),

label: Text(
buttonText,
style: const TextStyle(
fontWeight: FontWeight.w800,
),
),
),
),
],
),
);
}
}