
import 'package:flutter/material.dart';

import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';
import '../core/user_session.dart';
import '../generated/l10n/app_localizations.dart';
import 'recipe_detail_view.dart';

class FavoritesView extends StatelessWidget {
FavoritesView({super.key});

final RecipeController controller = RecipeController();

// ================= L18N HELPERS (DYNAMIC CONTENT) =================
String _getLang(BuildContext context) {
return Localizations.localeOf(context).languageCode;
}

String _getTitle(BuildContext context, RecipeModel recipe) {
final lang = _getLang(context);

if (lang == 'ar' &&
recipe.titleAr != null &&
recipe.titleAr!.isNotEmpty) {
return recipe.titleAr!;
}

if (recipe.titleEn != null && recipe.titleEn!.isNotEmpty) {
return recipe.titleEn!;
}

return recipe.title;
}

String _getDescription(BuildContext context, RecipeModel recipe) {
final lang = _getLang(context);

if (lang == 'ar' &&
recipe.descriptionAr != null &&
recipe.descriptionAr!.isNotEmpty) {
return recipe.descriptionAr!;
}

if (recipe.descriptionEn != null &&
recipe.descriptionEn!.isNotEmpty) {
return recipe.descriptionEn!;
}

return recipe.description;
}

// ================= UI =================
@override
Widget build(BuildContext context) {
final userId = UserSession.userId;
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
t.myFavorites,
style: const TextStyle(
fontWeight: FontWeight.w800,
letterSpacing: -0.2,
),
),
centerTitle: true,
backgroundColor: green,
foregroundColor: Colors.white,
elevation: 0,
),

// =========================================================
// FAVORITES STREAM
// =========================================================
body: StreamBuilder<List<RecipeModel>>(
stream: controller.getFavoriteRecipes(userId),
builder: (context, snapshot) {
// =======================================================
// LOADING
// =======================================================
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: SizedBox(
width: 28,
height: 28,
child: CircularProgressIndicator(
strokeWidth: 2.5,
color: green,
),
),
);
}

// =======================================================
// ERROR
// =======================================================
if (snapshot.hasError) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Container(
width: double.infinity,
padding: const EdgeInsets.all(28),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(24),
border: Border.all(
color: Colors.red.withOpacity(0.12),
),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 68,
height: 68,
decoration: BoxDecoration(
color: Colors.red.withOpacity(0.08),
shape: BoxShape.circle,
),
child: const Icon(
Icons.error_outline_rounded,
color: Colors.red,
size: 34,
),
),
const SizedBox(height: 16),
Text(
t.somethingWrong,
textAlign: TextAlign.center,
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
),
),
],
),
),
),
);
}

final recipes = snapshot.data ?? [];

// =======================================================
// EMPTY STATE
// =======================================================
if (recipes.isEmpty) {
return Padding(
padding: const EdgeInsets.all(20),
child: Center(
child: Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 28,
vertical: 36,
),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(26),
border: Border.all(
color: green.withOpacity(0.07),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.035),
blurRadius: 14,
offset: const Offset(0, 6),
),
],
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 82,
height: 82,
decoration: BoxDecoration(
color: Colors.red.withOpacity(0.08),
shape: BoxShape.circle,
),
child: const Icon(
Icons.favorite_border_rounded,
size: 42,
color: Colors.red,
),
),
const SizedBox(height: 20),
Text(
t.noFavorites,
textAlign: TextAlign.center,
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
),
),
],
),
),
),
);
}

// =======================================================
// FAVORITES LIST
// =======================================================
return ListView.builder(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
itemCount: recipes.length,
itemBuilder: (context, index) {
final recipe = recipes[index];

return Container(
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: green.withOpacity(0.07),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 14,
offset: const Offset(0, 6),
),
],
),
child: Material(
color: Colors.transparent,
borderRadius: BorderRadius.circular(20),
clipBehavior: Clip.antiAlias,
child: InkWell(
borderRadius: BorderRadius.circular(20),
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
RecipeDetailView(recipe: recipe),
),
);
},
child: Padding(
padding: const EdgeInsets.all(10),
child: Row(
children: [
// =========================================
// RECIPE IMAGE
// =========================================
ClipRRect(
borderRadius: BorderRadius.circular(15),
child: recipe.imageUrl != null
? Image.network(
recipe.imageUrl!,
width: 86,
height: 86,
fit: BoxFit.cover,
errorBuilder:
(context, error, stackTrace) {
return _imagePlaceholder();
},
)
    : _imagePlaceholder(),
),

const SizedBox(width: 13),

// =========================================
// RECIPE INFORMATION
// =========================================
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
_getTitle(context, recipe),
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: theme.textTheme.titleSmall?.copyWith(
fontWeight: FontWeight.w800,
height: 1.2,
),
),

const SizedBox(height: 7),

Text(
_getDescription(context, recipe),
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: theme.textTheme.bodySmall?.copyWith(
color: theme.textTheme.bodySmall?.color
    ?.withOpacity(0.58),
height: 1.35,
),
),

const SizedBox(height: 10),

Row(
children: [
Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 5,
),
decoration: BoxDecoration(
color: Colors.red.withOpacity(0.08),
borderRadius:
BorderRadius.circular(10),
),
child: const Icon(
Icons.favorite_rounded,
color: Colors.red,
size: 15,
),
),
const SizedBox(width: 7),
Text(
t.myFavorites,
style:
theme.textTheme.labelSmall?.copyWith(
color: green,
fontWeight: FontWeight.w700,
),
),
],
),
],
),
),

const SizedBox(width: 8),

// =========================================
// ARROW
// =========================================
Container(
width: 34,
height: 34,
decoration: BoxDecoration(
color: green.withOpacity(0.07),
shape: BoxShape.circle,
),
child: const Icon(
Icons.arrow_forward_ios_rounded,
color: green,
size: 14,
),
),
],
),
),
),
),
);
},
);
},
),
);
}

Widget _imagePlaceholder() {
const green = Color(0xFF2E7D32);

return Container(
width: 86,
height: 86,
color: green.withOpacity(0.07),
child: const Center(
child: Icon(
Icons.fastfood_rounded,
color: green,
size: 32,
),
),
);
}
}
