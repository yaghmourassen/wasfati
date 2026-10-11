
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controller/auth_controller.dart';
import '../generated/l10n/app_localizations.dart';
import 'auth_view.dart';
import 'category_view.dart';
import 'favorites_view .dart';
import 'setting_view.dart';
import 'restaurent_view.dart';
import 'shopping_plan_view.dart';

class HomeView extends StatefulWidget {
const HomeView({super.key});

@override
State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
late BannerAd _bannerAd;
bool _isBannerReady = false;

final authController = AuthController();

static const Color green = Color(0xFF2E7D32);
static const Color orange = Color(0xFFEF6C00);
static const Color favoriteRed = Color(0xFFE53935);
static const Color shoppingTeal = Color(0xFF009688);

@override
void initState() {
super.initState();

_bannerAd = BannerAd(
adUnitId: 'ca-app-pub-3185716051823285/7834634897',
size: AdSize.banner,
request: const AdRequest(),
listener: BannerAdListener(
onAdLoaded: (ad) {
debugPrint('BANNER LOADED SUCCESSFULLY');

if (mounted) {
setState(() {
_isBannerReady = true;
});
}
},
onAdFailedToLoad: (ad, error) {
ad.dispose();
debugPrint('Banner failed: $error');
},
),
);

_bannerAd.load();
}

@override
void dispose() {
_bannerAd.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final t = AppLocalizations.of(context)!;
final theme = Theme.of(context);

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
// HEADER
Row(
children: [
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
Expanded(
child: Text(
t.welcomeHome,
style: theme.textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
),
),
),
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

// 1. YOUR KITCHEN HUB
_buildKitchenHub(
context: context,
title: t.kitchenHub,
description: t.homeDescription,
buttonText: t.exploreRecipes,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const CategoryView(),
),
);
},
),

const SizedBox(height: 22),

// 2. RESTAURANTS
_buildRestaurantCard(
context: context,
title: t.restaurantsTitle,
description: t.restaurantsDesc,
buttonText: t.exploreRestaurants,
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const RestaurantView(),
),
);
},
),

const SizedBox(height: 22),

// 3. YOUR FAVORITES
_buildFeatureCard(
context: context,
icon: Icons.favorite_rounded,
iconColor: Colors.white,
cardColor: favoriteRed,
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

// 4. SHOPPING PLAN
_buildFeatureCard(
context: context,
icon: Icons.shopping_cart_rounded,
iconColor: Colors.white,
cardColor: shoppingTeal,
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

// LOGOUT
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

// ADMOB BANNER
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

// KITCHEN HUB CARD
Widget _buildKitchenHub({
required BuildContext context,
required String title,
required String description,
required String buttonText,
required VoidCallback onPressed,
}) {
const green = Color(0xFF2E7D32);

return Container(
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
child: ClipRRect(
borderRadius: BorderRadius.circular(28),
child: Stack(
children: [
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
title,
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.white,
fontSize: 21,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 10),
Text(
description,
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white.withOpacity(0.88),
fontSize: 14,
height: 1.5,
),
),
const SizedBox(height: 22),
SizedBox(
width: double.infinity,
height: 50,
child: ElevatedButton.icon(
onPressed: onPressed,
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
buttonText,
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
);
}

// RESTAURANT CARD
Widget _buildRestaurantCard({
required BuildContext context,
required String title,
required String description,
required String buttonText,
required VoidCallback onPressed,
}) {
const orange = Color(0xFFEF6C00);

return Container(
width: double.infinity,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(26),
gradient: const LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
Color(0xFFFFA726),
Color(0xFFEF6C00),
],
),
boxShadow: [
BoxShadow(
color: orange.withOpacity(0.18),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(26),
child: Stack(
children: [
Positioned(
right: -20,
top: -25,
child: Icon(
Icons.storefront_rounded,
size: 145,
color: Colors.white.withOpacity(0.10),
),
),
Positioned(
right: 18,
bottom: 55,
child: Icon(
Icons.location_on_rounded,
size: 55,
color: Colors.white.withOpacity(0.08),
),
),
Padding(
padding: const EdgeInsets.all(22),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
  Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
            ),
          ),
          child: const Icon(
            Icons.restaurant_rounded,
            size: 34,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  ),
const SizedBox(height: 18),
Text(
description,
style: TextStyle(
color: Colors.white.withOpacity(0.94),
fontSize: 14,
height: 1.6,
),
),
const SizedBox(height: 22),
SizedBox(
width: double.infinity,
height: 49,
child: ElevatedButton.icon(
onPressed: onPressed,
icon: const Icon(
Icons.location_on_rounded,
size: 20,
),
label: Text(
buttonText,
style: const TextStyle(
fontWeight: FontWeight.w800,
),
),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.white,
foregroundColor: orange,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
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
);
}

// FAVORITES AND SHOPPING PLAN CARDS
Widget _buildFeatureCard({
required BuildContext context,
required IconData icon,
required Color iconColor,
required Color cardColor,
required String title,
required String description,
required String buttonText,
required IconData buttonIcon,
required VoidCallback onPressed,
}) {
final darkColor = Color.lerp(
cardColor,
Colors.black,
0.18,
)!;

return Container(
width: double.infinity,
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
cardColor,
darkColor,
],
),
borderRadius: BorderRadius.circular(26),
boxShadow: [
BoxShadow(
color: cardColor.withOpacity(0.22),
blurRadius: 20,
offset: const Offset(0, 8),
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(26),
child: Stack(
children: [
Positioned(
right: -20,
top: -25,
child: Icon(
icon,
size: 145,
color: Colors.white.withOpacity(0.10),
),
),
Padding(
padding: const EdgeInsets.all(22),
child: Column(
children: [
Container(
width: 62,
height: 62,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.18),
borderRadius: BorderRadius.circular(19),
border: Border.all(
color: Colors.white.withOpacity(0.20),
),
),
child: Icon(
icon,
size: 34,
color: iconColor,
),
),
const SizedBox(height: 18),
Text(
title,
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.white,
fontSize: 20,
fontWeight: FontWeight.w800,
),
),
const SizedBox(height: 10),
Text(
description,
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white.withOpacity(0.94),
fontSize: 14,
height: 1.6,
),
),
const SizedBox(height: 22),
SizedBox(
width: double.infinity,
height: 49,
child: ElevatedButton.icon(
onPressed: onPressed,
icon: Icon(
buttonIcon,
size: 20,
),
label: Text(
buttonText,
style: const TextStyle(
fontWeight: FontWeight.w800,
),
),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.white,
foregroundColor: darkColor,
elevation: 0,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
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
);
}

// HEADER ICON BUTTON
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
color: green,
),
),
),
);
}
}
