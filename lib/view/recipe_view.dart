
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../controller/recipe_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../core/user_session.dart';
import '../model/recipe_model.dart';
import 'recipe_detail_view.dart';

class RecipeView extends StatefulWidget {
final String? categoryId;

const RecipeView({super.key, this.categoryId});

@override
State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
final RecipeController controller = RecipeController();

BannerAd? bannerAd;
InterstitialAd? interstitialAd;

bool isAdLoaded = false;
int openCount = 0;

String searchText = "";
String sortBy = "date";

final List<Map<String, String>> categories = const [
{"id": "breakfast"},
{"id": "lunch"},
{"id": "dinner"},
{"id": "dessert"},
{"id": "healthy"},
{"id": "fastfood"},
{"id": "traditional"},
{"id": "drinks"},
];

@override
void initState() {
super.initState();

loadInterstitialAd();

bannerAd = BannerAd(
adUnitId: "ca-app-pub-3185716051823285/7834634897",
size: AdSize.banner,
request: const AdRequest(),
listener: BannerAdListener(
onAdLoaded: (ad) {
if (!mounted) return;

setState(() {
isAdLoaded = true;
});
},
onAdFailedToLoad: (ad, error) {
ad.dispose();
debugPrint("Banner failed: $error");
},
),
);

bannerAd!.load();
}

@override
void dispose() {
bannerAd?.dispose();
interstitialAd?.dispose();
super.dispose();
}

void loadInterstitialAd() {
InterstitialAd.load(
adUnitId: "ca-app-pub-3185716051823285/5008108652",
request: const AdRequest(),
adLoadCallback: InterstitialAdLoadCallback(
onAdLoaded: (ad) {
interstitialAd = ad;

interstitialAd!.fullScreenContentCallback =
FullScreenContentCallback(
onAdDismissedFullScreenContent: (ad) {
ad.dispose();
interstitialAd = null;
loadInterstitialAd();
},
onAdFailedToShowFullScreenContent: (ad, error) {
ad.dispose();
interstitialAd = null;
loadInterstitialAd();
},
);
},
onAdFailedToLoad: (error) {
interstitialAd = null;

Future.delayed(
const Duration(seconds: 3),
loadInterstitialAd,
);
},
),
);
}

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

List<String> _getIngredients(
BuildContext context,
RecipeModel recipe,
) {
final lang = _getLang(context);

if (lang == 'ar' &&
recipe.ingredientsAr != null &&
recipe.ingredientsAr!.isNotEmpty) {
return recipe.ingredientsAr!;
}

if (recipe.ingredientsEn != null &&
recipe.ingredientsEn!.isNotEmpty) {
return recipe.ingredientsEn!;
}

return recipe.ingredients;
}

String getCategoryName(String id, AppLocalizations t) {
switch (id) {
case "breakfast":
return t.breakfast;
case "lunch":
return t.lunch;
case "dinner":
return t.dinner;
case "dessert":
return t.dessert;
case "healthy":
return t.healthy;
case "fastfood":
return t.fastfood;
case "traditional":
return t.traditional;
case "drinks":
return t.drinks;
default:
return id;
}
}

@override
Widget build(BuildContext context) {
final t = AppLocalizations.of(context)!;
final isAdmin = UserSession.isAdmin;

return Scaffold(
appBar: AppBar(
title: Text(
t.appTitle,
style: const TextStyle(
fontWeight: FontWeight.w700,
),
),
),

floatingActionButton: isAdmin
? FloatingActionButton.extended(
onPressed: () => _showAddRecipeDialog(context, t),
icon: const Icon(Icons.add),
label: Text(t.addRecipe),
)
    : null,

body: Column(
children: [
if (!isAdmin) _buildSearchAndFilter(context, t),

Expanded(
child: StreamBuilder<List<RecipeModel>>(
stream: controller.getRecipesStream(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting &&
!snapshot.hasData) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.error_outline,
size: 52,
color: Colors.red.shade300,
),
const SizedBox(height: 12),
const Text(
"Unable to load recipes",
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
),
),
const SizedBox(height: 6),
Text(
"${snapshot.error}",
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 13,
),
),
],
),
),
);
}

List<RecipeModel> recipes = snapshot.data ?? [];

if (widget.categoryId != null &&
widget.categoryId!.isNotEmpty) {
recipes = recipes
    .where(
(r) => r.categoryId == widget.categoryId,
)
    .toList();
}

recipes = recipes.where((r) {
final query = searchText.toLowerCase().trim();

if (query.isEmpty) return true;

final title = r.title.toLowerCase();
final titleEn = r.titleEn?.toLowerCase() ?? "";
final titleAr = r.titleAr?.toLowerCase() ?? "";

final ingredientsEn = r.ingredientsEn ?? [];
final ingredientsAr = r.ingredientsAr ?? [];

return title.contains(query) ||
titleEn.contains(query) ||
titleAr.contains(query) ||
ingredientsEn.any(
(i) => i.toLowerCase().contains(query),
) ||
ingredientsAr.any(
(i) => i.toLowerCase().contains(query),
);
}).toList();

if (!isAdmin) {
if (sortBy == "rating") {
recipes.sort(
(a, b) => b.rating.compareTo(a.rating),
);
} else if (sortBy == "views") {
recipes.sort(
(a, b) => b.views.compareTo(a.views),
);
}
}

if (recipes.isEmpty) {
return _buildEmptyState(t);
}

return ListView.builder(
padding: const EdgeInsets.fromLTRB(
12,
4,
12,
24,
),
itemCount: recipes.length,
itemBuilder: (context, index) {
return _buildRecipeCard(
context,
t,
recipes[index],
isAdmin,
);
},
);
},
),
),
],
),

bottomNavigationBar: isAdLoaded && bannerAd != null
? SizedBox(
width: bannerAd!.size.width.toDouble(),
height: bannerAd!.size.height.toDouble(),
child: AdWidget(ad: bannerAd!),
)
    : null,
);
}

// ============================================================
// SEARCH + FILTER
// ============================================================

Widget _buildSearchAndFilter(
BuildContext context,
AppLocalizations t,
) {
return Container(
margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
padding: const EdgeInsets.all(6),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: Colors.grey.withOpacity(0.18),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 12,
offset: const Offset(0, 4),
),
],
),
child: Row(
children: [
const SizedBox(width: 8),

Icon(
Icons.search_rounded,
color: Colors.green.shade700,
size: 23,
),

const SizedBox(width: 8),

Expanded(
child: TextField(
onChanged: (value) {
setState(() {
searchText = value.toLowerCase();
});
},
decoration: InputDecoration(
hintText: t.searchRecipes,
hintStyle: TextStyle(
color: Colors.grey.shade500,
fontSize: 14,
),
border: InputBorder.none,
isDense: true,
),
),
),

Container(
height: 38,
width: 1,
color: Colors.grey.withOpacity(0.18),
),

PopupMenuButton<String>(
tooltip: "Sort recipes",
icon: Icon(
Icons.tune_rounded,
color: Colors.green.shade700,
),
onSelected: (value) {
setState(() {
sortBy = value;
});
},
itemBuilder: (context) => [
PopupMenuItem(
value: "date",
child: Row(
children: [
const Icon(Icons.schedule_rounded, size: 20),
const SizedBox(width: 10),
Text(t.newest),
],
),
),
PopupMenuItem(
value: "rating",
child: Row(
children: [
const Icon(Icons.star_rounded, size: 20),
const SizedBox(width: 10),
Text(t.topRated),
],
),
),
PopupMenuItem(
value: "views",
child: Row(
children: [
const Icon(Icons.visibility_rounded, size: 20),
const SizedBox(width: 10),
Text(t.mostViewed),
],
),
),
],
),
],
),
);
}

// ============================================================
// RECIPE CARD
// ============================================================

Widget _buildRecipeCard(
BuildContext context,
AppLocalizations t,
RecipeModel recipe,
bool isAdmin,
) {
final title = _getTitle(context, recipe);
final ingredients = _getIngredients(context, recipe);

return Container(
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: Theme.of(context).cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: Colors.grey.withOpacity(0.14),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.045),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),
child: InkWell(
borderRadius: BorderRadius.circular(18),
onTap: () => _openRecipe(context, recipe),
child: Padding(
padding: const EdgeInsets.all(10),
child: Row(
crossAxisAlignment: CrossAxisAlignment.center,
children: [
_buildRecipeImage(recipe),

const SizedBox(width: 12),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w700,
),
),

const SizedBox(height: 7),

Row(
children: [
Icon(
Icons.restaurant_menu_rounded,
size: 15,
color: Colors.green.shade600,
),
const SizedBox(width: 5),
Expanded(
child: Text(
"${ingredients.length} ${t.ingredients}",
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(
fontSize: 12.5,
color: Colors.grey.shade600,
),
),
),
],
),

const SizedBox(height: 9),

if (!isAdmin)
_buildRecipeStats(
context,
recipe,
),
],
),
),

const SizedBox(width: 6),

if (isAdmin)
PopupMenuButton<String>(
padding: EdgeInsets.zero,
icon: const Icon(
Icons.more_vert_rounded,
),
onSelected: (value) {
if (value == "edit") {
_showEditRecipeDialog(
context,
t,
recipe,
);
}

if (value == "delete") {
_showDeleteConfirmation(
context,
t,
recipe,
);
}
},
itemBuilder: (context) => [
PopupMenuItem(
value: "edit",
child: Row(
children: [
const Icon(
Icons.edit_outlined,
size: 20,
),
const SizedBox(width: 10),
Text(t.editRecipe),
],
),
),
PopupMenuItem(
value: "delete",
child: Row(
children: [
const Icon(
Icons.delete_outline,
color: Colors.red,
size: 20,
),
const SizedBox(width: 10),
Text(t.delete),
],
),
),
],
)
else
const Icon(
Icons.chevron_right_rounded,
color: Colors.grey,
),
],
),
),
),
);
}

Widget _buildRecipeImage(RecipeModel recipe) {
if (recipe.imageUrl == null || recipe.imageUrl!.isEmpty) {
return Container(
width: 88,
height: 88,
decoration: BoxDecoration(
color: Colors.green.withOpacity(0.08),
borderRadius: BorderRadius.circular(14),
),
child: Icon(
Icons.restaurant_rounded,
size: 38,
color: Colors.green.shade600,
),
);
}

return ClipRRect(
borderRadius: BorderRadius.circular(14),
child: Image.network(
recipe.imageUrl!,
width: 88,
height: 88,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) {
return Container(
width: 88,
height: 88,
color: Colors.grey.shade100,
child: const Icon(
Icons.broken_image_outlined,
color: Colors.grey,
),
);
},
loadingBuilder: (
context,
child,
loadingProgress,
) {
if (loadingProgress == null) return child;

return Container(
width: 88,
height: 88,
color: Colors.grey.shade100,
child: const Center(
child: SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
strokeWidth: 2,
),
),
),
);
},
),
);
}

Widget _buildRecipeStats(
BuildContext context,
RecipeModel recipe,
) {
return Row(
children: [
...List.generate(5, (i) {
final userId = UserSession.userId;
final isFilled = i < recipe.rating.round();

return GestureDetector(
onTap: () async {
if (userId.isEmpty) return;

final alreadyRated =
recipe.userRatings.containsKey(userId);

if (alreadyRated) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
"You already rated this recipe",
),
),
);
return;
}

await controller.rateRecipe(
recipeId: recipe.id!,
rating: (i + 1).toDouble(),
userId: userId,
);

if (mounted) {
setState(() {});
}
},
child: Padding(
padding: const EdgeInsets.only(right: 2),
child: Icon(
isFilled
? Icons.star_rounded
    : Icons.star_outline_rounded,
size: 17,
color: isFilled
? Colors.amber.shade600
    : Colors.grey.shade400,
),
),
);
}),

const SizedBox(width: 5),

Text(
recipe.rating.toStringAsFixed(1),
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),

const SizedBox(width: 9),

Icon(
Icons.visibility_outlined,
size: 15,
color: Colors.grey.shade500,
),

const SizedBox(width: 3),

Text(
"${recipe.views}",
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade600,
),
),
],
);
}

Widget _buildEmptyState(AppLocalizations t) {
return Center(
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 90,
height: 90,
decoration: BoxDecoration(
color: Colors.green.withOpacity(0.08),
shape: BoxShape.circle,
),
child: Icon(
Icons.restaurant_menu_rounded,
size: 42,
color: Colors.green.shade600,
),
),

const SizedBox(height: 18),

const Text(
"No recipes found",
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.w700,
),
),

const SizedBox(height: 7),

Text(
"Try another search or explore another category.",
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 13,
),
),
],
),
),
);
}

// ============================================================
// OPEN RECIPE
// ============================================================

Future<void> _openRecipe(
BuildContext context,
RecipeModel recipe,
) async {
openCount++;

await controller.increaseViews(recipe.id!);

if (!mounted) return;

if (openCount % 3 == 0 && interstitialAd != null) {
final ad = interstitialAd;
interstitialAd = null;

ad!.fullScreenContentCallback =
FullScreenContentCallback(
onAdDismissedFullScreenContent: (ad) {
ad.dispose();
loadInterstitialAd();

if (!mounted) return;

Navigator.push(
context,
MaterialPageRoute(
builder: (_) => RecipeDetailView(
recipe: recipe,
),
),
);
},
onAdFailedToShowFullScreenContent: (
ad,
error,
) {
ad.dispose();
loadInterstitialAd();

if (!mounted) return;

Navigator.push(
context,
MaterialPageRoute(
builder: (_) => RecipeDetailView(
recipe: recipe,
),
),
);
},
);

ad.show();
return;
}

Navigator.push(
context,
MaterialPageRoute(
builder: (_) => RecipeDetailView(
recipe: recipe,
),
),
);
}

// ============================================================
// DELETE CONFIRMATION
// ============================================================

void _showDeleteConfirmation(
BuildContext context,
AppLocalizations t,
RecipeModel recipe,
) {
showDialog(
context: context,
builder: (dialogContext) {
return AlertDialog(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
title: Row(
children: [
Icon(
Icons.warning_amber_rounded,
color: Colors.red.shade400,
),
const SizedBox(width: 10),
Text(t.delete),
],
),
content: const Text(
"Are you sure you want to delete this recipe?",
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext),
child: Text(t.cancel),
),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red.shade600,
),
onPressed: () {
Navigator.pop(dialogContext);
controller.deleteRecipe(recipe.id!);
},
child: Text(t.delete),
),
],
);
},
);
}

// ============================================================
// ADD RECIPE
// ============================================================

void _showAddRecipeDialog(
BuildContext context,
AppLocalizations t,
) {
final titleEnCtrl = TextEditingController();
final titleArCtrl = TextEditingController();
final videoUrlCtrl = TextEditingController();

String? selectedCategoryId = widget.categoryId;

List<String> ingredientsEn = [];
List<String> ingredientsAr = [];

bool isArabicIngredient = false;

List<Map<String, dynamic>> stepsEn = [];
List<Map<String, dynamic>> stepsAr = [];

bool isArabicStep = false;

final stepTextCtrl = TextEditingController();

File? currentStepImage;
File? image;

showDialog(
context: context,
builder: (_) => StatefulBuilder(
builder: (context, setState) {
return _buildRecipeDialog(
context: context,
t: t,
title: t.addRecipe,
titleEnCtrl: titleEnCtrl,
titleArCtrl: titleArCtrl,
videoUrlCtrl: videoUrlCtrl,
selectedCategoryId: selectedCategoryId,
onCategoryChanged: (value) {
setState(() {
selectedCategoryId = value;
});
},
ingredientsEn: ingredientsEn,
ingredientsAr: ingredientsAr,
isArabicIngredient: isArabicIngredient,
onIngredientLanguageChanged: (value) {
setState(() {
isArabicIngredient = value;
});
},
stepsEn: stepsEn,
stepsAr: stepsAr,
isArabicStep: isArabicStep,
onStepLanguageChanged: (value) {
setState(() {
isArabicStep = value;
});
},
stepTextCtrl: stepTextCtrl,
currentStepImage: currentStepImage,
onStepImageChanged: (file) {
setState(() {
currentStepImage = file;
});
},
image: image,
imageUrl: null,
onImageChanged: (file) {
setState(() {
image = file;
});
},
onDeleteIngredientEn: (index) {
setState(() {
ingredientsEn.removeAt(index);
});
},
onDeleteIngredientAr: (index) {
setState(() {
ingredientsAr.removeAt(index);
});
},
onAddIngredient: (text) {
setState(() {
if (isArabicIngredient) {
ingredientsAr.add(text);
} else {
ingredientsEn.add(text);
}
});
},
onDeleteStepEn: (index) {
setState(() {
stepsEn.removeAt(index);
});
},
onDeleteStepAr: (index) {
setState(() {
stepsAr.removeAt(index);
});
},
onAddStep: () async {
final text = stepTextCtrl.text.trim();

if (text.isEmpty) return;

String? stepImgUrl;

if (currentStepImage != null) {
stepImgUrl = await controller.uploadToCloudinary(
currentStepImage!,
);
}

setState(() {
final stepData = {
'text': text,
'imageUrl': stepImgUrl,
};

if (isArabicStep) {
stepsAr.add(stepData);
} else {
stepsEn.add(stepData);
}

stepTextCtrl.clear();
currentStepImage = null;
});
},
onCancel: () {
Navigator.pop(context);
},
onSave: () async {
String? imageUrl;

if (image != null) {
imageUrl = await controller.uploadToCloudinary(
image!,
);
}

await controller.addRecipe(
title: titleEnCtrl.text.trim().isNotEmpty
? titleEnCtrl.text.trim()
    : titleArCtrl.text.trim(),
description: stepsEn.isNotEmpty
? stepsEn.first['text']
    : '',
categoryId: selectedCategoryId ?? "",
imageUrl: imageUrl,
videoUrl: videoUrlCtrl.text.trim().isEmpty
? null
    : videoUrlCtrl.text.trim(),
titleEn: titleEnCtrl.text.trim(),
titleAr: titleArCtrl.text.trim(),
descriptionEn: stepsEn.isNotEmpty
? stepsEn.first['text']
    : '',
descriptionAr: stepsAr.isNotEmpty
? stepsAr.first['text']
    : '',
ingredientsEn: ingredientsEn,
ingredientsAr: ingredientsAr,
ingredients: ingredientsEn.isNotEmpty
? ingredientsEn
    : ingredientsAr,
stepsEn: stepsEn,
stepsAr: stepsAr,
steps: stepsEn.isNotEmpty
? stepsEn
    : stepsAr,
);

if (context.mounted) {
Navigator.pop(context);
}
},
);
},
),
);
}

// ============================================================
// EDIT RECIPE
// ============================================================

void _showEditRecipeDialog(
BuildContext context,
AppLocalizations t,
RecipeModel recipe,
) {
final titleEnCtrl = TextEditingController(
text: recipe.titleEn ?? recipe.title,
);

final titleArCtrl = TextEditingController(
text: recipe.titleAr ?? "",
);

final videoUrlCtrl = TextEditingController(
text: recipe.videoUrl ?? "",
);

String? selectedCategoryId = recipe.categoryId;

List<String> ingredientsEn = List.from(
recipe.ingredientsEn ?? recipe.ingredients,
);

List<String> ingredientsAr = List.from(
recipe.ingredientsAr ?? [],
);

bool isArabicIngredient = false;

List<Map<String, dynamic>> stepsEn = List.from(
recipe.stepsEn ?? recipe.steps ?? [],
);

List<Map<String, dynamic>> stepsAr = List.from(
recipe.stepsAr ?? [],
);

bool isArabicStep = false;

final stepTextCtrl = TextEditingController();

File? currentStepImage;
File? image;

String? imageUrl = recipe.imageUrl;

showDialog(
context: context,
builder: (_) => StatefulBuilder(
builder: (context, setState) {
return _buildRecipeDialog(
context: context,
t: t,
title: t.editRecipe,
titleEnCtrl: titleEnCtrl,
titleArCtrl: titleArCtrl,
videoUrlCtrl: videoUrlCtrl,
selectedCategoryId: selectedCategoryId,
onCategoryChanged: (value) {
setState(() {
selectedCategoryId = value;
});
},
ingredientsEn: ingredientsEn,
ingredientsAr: ingredientsAr,
isArabicIngredient: isArabicIngredient,
onIngredientLanguageChanged: (value) {
setState(() {
isArabicIngredient = value;
});
},
stepsEn: stepsEn,
stepsAr: stepsAr,
isArabicStep: isArabicStep,
onStepLanguageChanged: (value) {
setState(() {
isArabicStep = value;
});
},
stepTextCtrl: stepTextCtrl,
currentStepImage: currentStepImage,
onStepImageChanged: (file) {
setState(() {
currentStepImage = file;
});
},
image: image,
imageUrl: imageUrl,
onImageChanged: (file) {
setState(() {
image = file;
});
},
onDeleteIngredientEn: (index) {
setState(() {
ingredientsEn.removeAt(index);
});
},
onDeleteIngredientAr: (index) {
setState(() {
ingredientsAr.removeAt(index);
});
},
onAddIngredient: (text) {
setState(() {
if (isArabicIngredient) {
ingredientsAr.add(text);
} else {
ingredientsEn.add(text);
}
});
},
onDeleteStepEn: (index) {
setState(() {
stepsEn.removeAt(index);
});
},
onDeleteStepAr: (index) {
setState(() {
stepsAr.removeAt(index);
});
},
onAddStep: () async {
final text = stepTextCtrl.text.trim();

if (text.isEmpty) return;

String? stepImgUrl;

if (currentStepImage != null) {
stepImgUrl = await controller.uploadToCloudinary(
currentStepImage!,
);
}

setState(() {
final stepData = {
'text': text,
'imageUrl': stepImgUrl,
};

if (isArabicStep) {
stepsAr.add(stepData);
} else {
stepsEn.add(stepData);
}

stepTextCtrl.clear();
currentStepImage = null;
});
},
onCancel: () {
Navigator.pop(context);
},
onSave: () async {
try {
String? newImageUrl = imageUrl;

if (image != null) {
newImageUrl =
await controller.uploadToCloudinary(
image!,
);
}

final result = await controller.updateRecipe(
id: recipe.id!,
title: titleEnCtrl.text.trim().isNotEmpty
? titleEnCtrl.text.trim()
    : titleArCtrl.text.trim(),
description: stepsEn.isNotEmpty
? stepsEn.first['text']
    : '',
categoryId: selectedCategoryId ?? "",
titleEn: titleEnCtrl.text.trim(),
titleAr: titleArCtrl.text.trim(),
descriptionEn: stepsEn.isNotEmpty
? stepsEn.first['text']
    : '',
descriptionAr: stepsAr.isNotEmpty
? stepsAr.first['text']
    : '',
ingredients: ingredientsEn.isNotEmpty
? ingredientsEn
    : ingredientsAr,
ingredientsEn: ingredientsEn,
ingredientsAr: ingredientsAr,
stepsEn: stepsEn,
stepsAr: stepsAr,
steps: stepsEn.isNotEmpty
? stepsEn
    : stepsAr,
imageUrl: newImageUrl,
videoUrl: videoUrlCtrl.text.trim().isEmpty
? null
    : videoUrlCtrl.text.trim(),
);

if (result != null) {
debugPrint(
"❌ UPDATE FAILED: $result",
);
return;
}

if (context.mounted) {
Navigator.pop(context);
}

if (mounted) {
setState(() {});
}
} catch (e) {
debugPrint(
"🔥 UPDATE ERROR: $e",
);
}
},
);
},
),
);
}

// ============================================================
// SHARED ADD / EDIT DIALOG UI
// ============================================================

Widget _buildRecipeDialog({
required BuildContext context,
required AppLocalizations t,
required String title,
required TextEditingController titleEnCtrl,
required TextEditingController titleArCtrl,
required TextEditingController videoUrlCtrl,
required String? selectedCategoryId,
required ValueChanged<String?> onCategoryChanged,
required List<String> ingredientsEn,
required List<String> ingredientsAr,
required bool isArabicIngredient,
required ValueChanged<bool> onIngredientLanguageChanged,
required List<Map<String, dynamic>> stepsEn,
required List<Map<String, dynamic>> stepsAr,
required bool isArabicStep,
required ValueChanged<bool> onStepLanguageChanged,
required TextEditingController stepTextCtrl,
required File? currentStepImage,
required ValueChanged<File?> onStepImageChanged,
required File? image,
required String? imageUrl,
required ValueChanged<File?> onImageChanged,
required ValueChanged<int> onDeleteIngredientEn,
required ValueChanged<int> onDeleteIngredientAr,
required ValueChanged<String> onAddIngredient,
required ValueChanged<int> onDeleteStepEn,
required ValueChanged<int> onDeleteStepAr,
required Future<void> Function() onAddStep,
required VoidCallback onCancel,
required Future<void> Function() onSave,
}) {
return AlertDialog(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(22),
),
titlePadding: const EdgeInsets.fromLTRB(
22,
20,
22,
10,
),
contentPadding: const EdgeInsets.fromLTRB(
18,
8,
18,
4,
),
actionsPadding: const EdgeInsets.fromLTRB(
18,
6,
18,
16,
),
title: Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: Colors.green.withOpacity(0.1),
borderRadius: BorderRadius.circular(12),
),
child: Icon(
title == t.editRecipe
? Icons.edit_outlined
    : Icons.restaurant_menu_rounded,
color: Colors.green.shade700,
),
),
const SizedBox(width: 12),
Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 19,
fontWeight: FontWeight.w700,
),
),
),
],
),
content: SizedBox(
width: MediaQuery.of(context).size.width * 0.92,
height: MediaQuery.of(context).size.height * 0.78,
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
_dialogSectionTitle(
Icons.title_rounded,
"Recipe Information",
),

_styledTextField(
controller: titleEnCtrl,
label: "Title (EN)",
icon: Icons.language_rounded,
),

const SizedBox(height: 10),

_styledTextField(
controller: titleArCtrl,
label: "Title (AR)",
icon: Icons.translate_rounded,
textDirection: TextDirection.rtl,
),

const SizedBox(height: 10),

_styledTextField(
controller: videoUrlCtrl,
label: "Video URL (YouTube / MP4)",
icon: Icons.video_library_outlined,
),

const SizedBox(height: 10),

DropdownButtonFormField<String>(
value: selectedCategoryId,
isExpanded: true,
decoration: InputDecoration(
labelText: "Category",
prefixIcon: const Icon(
Icons.category_outlined,
),
filled: true,
fillColor: Colors.grey.withOpacity(0.06),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
),
hint: const Text("Select Category"),
items: categories.map((cat) {
return DropdownMenuItem(
value: cat["id"],
child: Text(
getCategoryName(
cat["id"]!,
t,
),
),
);
}).toList(),
onChanged: onCategoryChanged,
),

const SizedBox(height: 22),

_dialogSectionTitle(
Icons.shopping_basket_outlined,
"Ingredients",
),

_languageSwitcher(
isArabic: isArabicIngredient,
onChanged: onIngredientLanguageChanged,
),

const SizedBox(height: 8),

if (ingredientsEn.isNotEmpty ||
ingredientsAr.isNotEmpty)
Wrap(
spacing: 6,
runSpacing: 6,
children: [
...ingredientsEn.asMap().entries.map(
(entry) => _ingredientChip(
entry.value,
onDelete: () {
onDeleteIngredientEn(
entry.key,
);
},
),
),
...ingredientsAr.asMap().entries.map(
(entry) => _ingredientChip(
entry.value,
onDelete: () {
onDeleteIngredientAr(
entry.key,
);
},
),
),
],
),

const SizedBox(height: 8),

TextField(
onSubmitted: (value) {
final text = value.trim();

if (text.isEmpty) return;

onAddIngredient(text);
},
decoration: InputDecoration(
hintText: t.ingredients,
prefixIcon: const Icon(
Icons.add_circle_outline,
),
filled: true,
fillColor: Colors.grey.withOpacity(0.06),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 22),

_dialogSectionTitle(
Icons.format_list_numbered_rounded,
"Recipe Steps",
),

_languageSwitcher(
isArabic: isArabicStep,
onChanged: onStepLanguageChanged,
),

const SizedBox(height: 10),

if (stepsEn.isNotEmpty)
...stepsEn.asMap().entries.map(
(entry) => _stepItem(
index: entry.key,
language: "EN",
text: entry.value['text'] ?? "",
hasImage:
entry.value['imageUrl'] != null &&
entry.value['imageUrl']
    .toString()
    .isNotEmpty,
onDelete: () {
onDeleteStepEn(entry.key);
},
),
),

if (stepsAr.isNotEmpty)
...stepsAr.asMap().entries.map(
(entry) => _stepItem(
index: entry.key,
language: "AR",
text: entry.value['text'] ?? "",
hasImage:
entry.value['imageUrl'] != null &&
entry.value['imageUrl']
    .toString()
    .isNotEmpty,
onDelete: () {
onDeleteStepAr(entry.key);
},
),
),

const SizedBox(height: 8),

_styledTextField(
controller: stepTextCtrl,
label: isArabicStep
? "أضف خطوة (AR)"
    : "Add Step Instruction (EN)",
icon: Icons.edit_note_rounded,
maxLines: 3,
textDirection: isArabicStep
? TextDirection.rtl
    : TextDirection.ltr,
),

const SizedBox(height: 10),

Row(
children: [
Expanded(
child: OutlinedButton.icon(
onPressed: () async {
final picked =
await ImagePicker().pickImage(
source: ImageSource.gallery,
);

if (picked != null) {
onStepImageChanged(
File(picked.path),
);
}
},
icon: Icon(
currentStepImage == null
? Icons.add_photo_alternate_outlined
    : Icons.check_circle_outline,
),
label: Text(
currentStepImage == null
? "Step Image"
    : "Image Selected",
),
),
),

if (currentStepImage != null)
IconButton(
onPressed: () {
onStepImageChanged(null);
},
icon: const Icon(
Icons.close_rounded,
color: Colors.red,
),
),
],
),

const SizedBox(height: 8),

ElevatedButton.icon(
onPressed: onAddStep,
icon: const Icon(
Icons.add_rounded,
),
label: const Text(
"Add Step",
),
),

const SizedBox(height: 22),

_dialogSectionTitle(
Icons.image_outlined,
"Recipe Image",
),

if (image != null)
ClipRRect(
borderRadius: BorderRadius.circular(15),
child: Image.file(
image,
height: 150,
fit: BoxFit.cover,
),
)
else if (imageUrl != null &&
imageUrl.isNotEmpty)
ClipRRect(
borderRadius: BorderRadius.circular(15),
child: Image.network(
imageUrl,
height: 150,
width: double.infinity,
fit: BoxFit.cover,
errorBuilder: (_, __, ___) {
return _imagePlaceholder();
},
),
)
else
_imagePlaceholder(),

const SizedBox(height: 10),

OutlinedButton.icon(
onPressed: () async {
final picked =
await ImagePicker().pickImage(
source: ImageSource.gallery,
);

if (picked != null) {
onImageChanged(
File(picked.path),
);
}
},
icon: const Icon(
Icons.photo_library_outlined,
),
label: Text(t.pickImage),
),
],
),
),
),
actions: [
TextButton(
onPressed: onCancel,
child: Text(t.cancel),
),
ElevatedButton.icon(
onPressed: onSave,
icon: const Icon(
Icons.check_rounded,
size: 19,
),
label: Text(
title == t.editRecipe
? t.update
    : t.save,
),
),
],
);
}

// ============================================================
// DIALOG COMPONENTS
// ============================================================

Widget _dialogSectionTitle(
IconData icon,
String title,
) {
return Padding(
padding: const EdgeInsets.only(bottom: 10),
child: Row(
children: [
Icon(
icon,
size: 20,
color: Colors.green.shade700,
),
const SizedBox(width: 8),
Text(
title,
style: const TextStyle(
fontSize: 15,
fontWeight: FontWeight.w700,
),
),
],
),
);
}

Widget _styledTextField({
required TextEditingController controller,
required String label,
required IconData icon,
int maxLines = 1,
TextDirection? textDirection,
}) {
return TextField(
controller: controller,
maxLines: maxLines,
textDirection: textDirection,
decoration: InputDecoration(
labelText: label,
prefixIcon: Icon(icon),
alignLabelWithHint: maxLines > 1,
filled: true,
fillColor: Colors.grey.withOpacity(0.06),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
),
);
}

Widget _languageSwitcher({
required bool isArabic,
required ValueChanged<bool> onChanged,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 6,
),
decoration: BoxDecoration(
color: Colors.green.withOpacity(0.06),
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
Icons.translate_rounded,
size: 19,
color: Colors.green.shade700,
),
const SizedBox(width: 8),
Text(
isArabic
? "Arabic (AR)"
    : "English (EN)",
style: const TextStyle(
fontWeight: FontWeight.w600,
fontSize: 13,
),
),
const Spacer(),
Switch(
value: isArabic,
onChanged: onChanged,
),
],
),
);
}

Widget _ingredientChip(
String text, {
required VoidCallback onDelete,
}) {
return Chip(
label: Text(
text,
style: const TextStyle(
fontSize: 12,
),
),
deleteIcon: const Icon(
Icons.close,
size: 15,
),
onDeleted: onDelete,
backgroundColor: Colors.green.withOpacity(0.08),
side: BorderSide.none,
);
}

Widget _stepItem({
required int index,
required String language,
required String text,
required bool hasImage,
required VoidCallback onDelete,
}) {
return Container(
margin: const EdgeInsets.only(bottom: 7),
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 8,
),
decoration: BoxDecoration(
color: Colors.grey.withOpacity(0.055),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: Colors.grey.withOpacity(0.1),
),
),
child: Row(
children: [
Container(
width: 32,
height: 32,
decoration: BoxDecoration(
color: Colors.green.withOpacity(0.1),
shape: BoxShape.circle,
),
alignment: Alignment.center,
child: Text(
"${index + 1}",
style: TextStyle(
color: Colors.green.shade700,
fontWeight: FontWeight.w700,
),
),
),

const SizedBox(width: 9),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 6,
vertical: 3,
),
decoration: BoxDecoration(
color: language == "AR"
? Colors.orange.withOpacity(0.1)
    : Colors.blue.withOpacity(0.1),
borderRadius: BorderRadius.circular(6),
),
child: Text(
language,
style: const TextStyle(
fontSize: 10,
fontWeight: FontWeight.w700,
),
),
),

const SizedBox(width: 8),

Expanded(
child: Text(
text,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 13,
),
),
),

if (hasImage)
Padding(
padding: const EdgeInsets.only(right: 4),
child: Icon(
Icons.image_outlined,
size: 18,
color: Colors.green.shade600,
),
),

IconButton(
constraints: const BoxConstraints(),
padding: const EdgeInsets.all(5),
onPressed: onDelete,
icon: const Icon(
Icons.delete_outline_rounded,
color: Colors.red,
size: 19,
),
),
],
),
);
}

Widget _imagePlaceholder() {
return Container(
height: 150,
decoration: BoxDecoration(
color: Colors.grey.withOpacity(0.07),
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: Colors.grey.withOpacity(0.15),
),
),
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.add_photo_alternate_outlined,
size: 38,
color: Colors.grey.shade500,
),
const SizedBox(height: 7),
Text(
"No image selected",
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 12,
),
),
],
),
),
);
}
}
