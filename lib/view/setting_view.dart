
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/auth_controller.dart';
import '../controller/setting_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../view/favorites_view .dart';
import 'auth_view.dart';
import 'shopping_plan_view.dart';
import 'package:wasfati/services/account_service.dart';

class SettingsView extends StatelessWidget {
const SettingsView({super.key});

Future<void> _openWebsite() async {
final Uri url =
Uri.parse("https://yaghmourassen.github.io/My-Webpage/");
if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
throw Exception("Could not launch $url");
}
}

@override
Widget build(BuildContext context) {
final controller = Provider.of<SettingsController>(context);
final isDark = controller.isDarkMode;
final t = AppLocalizations.of(context)!;
final theme = Theme.of(context);

const green = Color(0xFF2E7D32);

return Scaffold(
backgroundColor: theme.scaffoldBackgroundColor,

// =========================================================
// APP BAR
// =========================================================
appBar: AppBar(
title: Text(
t.settings,
style: const TextStyle(
fontWeight: FontWeight.w800,
letterSpacing: -0.2,
),
),
backgroundColor: green,
foregroundColor: Colors.white,
elevation: 0,
centerTitle: true,
),

// =========================================================
// BODY
// =========================================================
body: SingleChildScrollView(
physics: const BouncingScrollPhysics(),
child: Padding(
padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
// =====================================================
// HEADER
// =====================================================
Row(
children: [
Container(
width: 52,
height: 52,
decoration: BoxDecoration(
color: green.withOpacity(0.10),
borderRadius: BorderRadius.circular(16),
),
child: const Icon(
Icons.settings_rounded,
color: green,
size: 27,
),
),
const SizedBox(width: 13),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
t.settings,
style: theme.textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
),
),
const SizedBox(height: 3),
Text(
isDark ? t.darkMode : t.lightMode,
style: theme.textTheme.bodySmall?.copyWith(
color: theme.textTheme.bodySmall?.color
    ?.withOpacity(0.55),
),
),
],
),
),
],
),

const SizedBox(height: 24),

// =====================================================
// APPEARANCE SECTION
// =====================================================
_sectionTitle(
context,
Icons.palette_outlined,
isDark ? t.darkMode : t.lightMode,
),

const SizedBox(height: 10),

_SettingsCard(
child: SwitchListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 5,
),
secondary: _iconBox(
context,
isDark
? Icons.dark_mode_rounded
    : Icons.light_mode_rounded,
green,
),
title: Text(
isDark ? t.darkMode : t.lightMode,
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
subtitle: Text(
isDark ? "Dark appearance" : "Light appearance",
style: theme.textTheme.bodySmall?.copyWith(
color: theme.textTheme.bodySmall?.color
    ?.withOpacity(0.5),
),
),
activeColor: green,
value: isDark,
onChanged: (_) => controller.toggleTheme(),
),
),

const SizedBox(height: 24),

// =====================================================
// LANGUAGE SECTION
// =====================================================
_sectionTitle(
context,
Icons.translate_rounded,
t.language,
),

const SizedBox(height: 10),

_SettingsCard(
child: ListTile(
contentPadding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 5,
),
leading: _iconBox(
context,
Icons.language_rounded,
green,
),
title: Text(
t.language,
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
subtitle: Text(
controller.locale.languageCode == "en"
? t.english
    : t.arabic,
style: theme.textTheme.bodySmall?.copyWith(
color: theme.textTheme.bodySmall?.color
    ?.withOpacity(0.5),
),
),
trailing: Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 2,
),
decoration: BoxDecoration(
color: green.withOpacity(0.06),
borderRadius: BorderRadius.circular(12),
),
child: DropdownButtonHideUnderline(
child: DropdownButton<String>(
value: controller.locale.languageCode,
icon: const Icon(
Icons.keyboard_arrow_down_rounded,
color: green,
),
borderRadius: BorderRadius.circular(14),
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
),
),

const SizedBox(height: 24),

// =====================================================
// PERSONAL FEATURES
// =====================================================
_sectionTitle(
context,
Icons.person_outline_rounded,
t.favorites,
),

const SizedBox(height: 10),

_SettingsCard(
child: _NavigationTile(
icon: Icons.favorite_rounded,
iconColor: Colors.red,
title: t.favorites,
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

const SizedBox(height: 10),

_SettingsCard(
child: _NavigationTile(
icon: Icons.shopping_cart_rounded,
iconColor: green,
title: t.shoppingPlan,
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const ShoppingPlanView(),
),
);
},
),
),

const SizedBox(height: 10),

_SettingsCard(
child: _NavigationTile(
icon: Icons.workspace_premium_rounded,
iconColor: Colors.amber.shade700,
title: t.upgradePro,
onTap: () {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(t.comingSoon)),
);
},
),
),

const SizedBox(height: 24),

// =====================================================
// ABOUT
// =====================================================
_sectionTitle(
context,
Icons.info_outline_rounded,
t.about,
),

const SizedBox(height: 10),

_SettingsCard(
child: _NavigationTile(
icon: Icons.language_rounded,
iconColor: green,
title: t.about,
trailingIcon: Icons.open_in_new_rounded,
onTap: _openWebsite,
),
),

const SizedBox(height: 24),

// =====================================================
// ACCOUNT
// =====================================================
_sectionTitle(
context,
Icons.manage_accounts_outlined,
t.deleteAccount,
),

const SizedBox(height: 10),

// DELETE ACCOUNT
_SettingsCard(
child: _NavigationTile(
icon: Icons.delete_forever_rounded,
iconColor: Colors.red,
title: t.deleteAccount,
titleColor: Colors.red,
onTap: () async {
final confirm = await showDialog(
context: context,
builder: (context) => AlertDialog(
title: Text(t.deleteAccount),
content: Text(t.deleteAccountWarning),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(context, false),
child: Text(t.cancel),
),
TextButton(
onPressed: () =>
Navigator.pop(context, true),
child: Text(
t.delete,
style: const TextStyle(
color: Colors.red,
),
),
),
],
),
);

if (confirm == true) {
try {
final service = AccountService();
await service.deleteCurrentUserAccount();

if (!context.mounted) return;

Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (_) => const AuthView(),
),
(route) => false,
);
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text("Error: $e")),
);
}
}
},
),
),

const SizedBox(height: 10),

// LOGOUT
Container(
width: double.infinity,
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: Colors.red.withOpacity(0.18),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.035),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),
child: Material(
color: Colors.transparent,
child: InkWell(
borderRadius: BorderRadius.circular(20),
onTap: () async {
final authController = AuthController();
await authController.logout();

if (context.mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(
builder: (_) => const AuthView(),
),
(route) => false,
);
}
},
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 14,
),
child: Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: Colors.red.withOpacity(0.08),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.logout_rounded,
color: Colors.red,
size: 22,
),
),
const SizedBox(width: 13),
Expanded(
child: Text(
t.logout,
style: const TextStyle(
color: Colors.red,
fontWeight: FontWeight.w800,
fontSize: 15,
),
),
),
const Icon(
Icons.arrow_forward_ios_rounded,
color: Colors.red,
size: 16,
),
],
),
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

Widget _sectionTitle(
BuildContext context,
IconData icon,
String title,
) {
final theme = Theme.of(context);
const green = Color(0xFF2E7D32);

return Row(
children: [
Container(
width: 5,
height: 20,
decoration: BoxDecoration(
color: green,
borderRadius: BorderRadius.circular(10),
),
),
const SizedBox(width: 9),
Icon(
icon,
size: 19,
color: green,
),
const SizedBox(width: 7),
Text(
title,
style: theme.textTheme.titleSmall?.copyWith(
fontWeight: FontWeight.w800,
),
),
],
);
}

Widget _iconBox(
BuildContext context,
IconData icon,
Color color,
) {
return Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: color.withOpacity(0.09),
borderRadius: BorderRadius.circular(13),
),
child: Icon(
icon,
color: color,
size: 21,
),
);
}
}

class _SettingsCard extends StatelessWidget {
final Widget child;

const _SettingsCard({
required this.child,
});

@override
Widget build(BuildContext context) {
final theme = Theme.of(context);
const green = Color(0xFF2E7D32);

return Container(
width: double.infinity,
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: green.withOpacity(0.07),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.035),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),
child: child,
);
}
}

class _NavigationTile extends StatelessWidget {
final IconData icon;
final Color iconColor;
final String title;
final Color? titleColor;
final IconData trailingIcon;
final VoidCallback onTap;

const _NavigationTile({
required this.icon,
required this.iconColor,
required this.title,
required this.onTap,
this.titleColor,
this.trailingIcon = Icons.arrow_forward_ios_rounded,
});

@override
Widget build(BuildContext context) {
return Material(
color: Colors.transparent,
child: InkWell(
borderRadius: BorderRadius.circular(20),
onTap: onTap,
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 10,
),
child: Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: iconColor.withOpacity(0.09),
borderRadius: BorderRadius.circular(14),
),
child: Icon(
icon,
color: iconColor,
size: 22,
),
),
const SizedBox(width: 13),
Expanded(
child: Text(
title,
style: TextStyle(
color: titleColor,
fontWeight: FontWeight.w700,
fontSize: 15,
),
),
),
Icon(
trailingIcon,
size: 17,
color: Theme.of(context)
    .iconTheme
    .color
    ?.withOpacity(0.45),
),
],
),
),
),
);
}
}
