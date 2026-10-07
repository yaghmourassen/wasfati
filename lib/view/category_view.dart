
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n/app_localizations.dart';
import 'recipe_view.dart';

class CategoryView extends StatelessWidget {
const CategoryView({super.key});

final List<Map<String, String>> categories = const [
{
"id": "breakfast",
"image":
"https://images.unsplash.com/photo-1525351484163-7529414344d8"
},
{
"id": "lunch",
"image":
"https://images.unsplash.com/photo-1540189549336-e6e99c3679fe"
},
{
"id": "dinner",
"image":
"https://images.unsplash.com/photo-1476224203421-9ac39bcb3327"
},
{
"id": "dessert",
"image":
"https://images.unsplash.com/photo-1551024601-bec78aea704b"
},
{
"id": "healthy",
"image":
"https://images.unsplash.com/photo-1512621776951-a57141f2eefd"
},
{
"id": "fastfood",
"image":
"https://images.unsplash.com/photo-1561758033-d89a9ad46330"
},
{
"id": "traditional",
"image":
"https://images.unsplash.com/photo-1604152135912-04a022e23696"
},
{
"id": "drinks",
"image":
"https://images.unsplash.com/photo-1551024709-8f23befc6f87"
},
];

@override
Widget build(BuildContext context) {
final t = AppLocalizations.of(context)!;
final theme = Theme.of(context);

const green = Color(0xFF2E7D32);

String getName(String id) {
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

return Scaffold(
backgroundColor: theme.scaffoldBackgroundColor,

// =========================================================
// APP BAR
// =========================================================
appBar: AppBar(
title: Text(
t.categories,
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
body: Padding(
padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
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
Icons.category_rounded,
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
t.categories,
style: theme.textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.w800,
letterSpacing: -0.3,
),
),
const SizedBox(height: 3),
Text(
'${categories.length} ${t.categories}',
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

const SizedBox(height: 20),

// =====================================================
// CATEGORY GRID
// =====================================================
Expanded(
child: GridView.builder(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.only(
bottom: 4,
),
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
mainAxisSpacing: 14,
crossAxisSpacing: 14,
childAspectRatio: 0.92,
),
itemCount: categories.length,
itemBuilder: (context, index) {
final cat = categories[index];
final id = cat["id"]!;
final image = cat["image"]!;

return Material(
color: theme.cardColor,
borderRadius: BorderRadius.circular(22),
clipBehavior: Clip.antiAlias,
elevation: 0,
child: InkWell(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => RecipeView(categoryId: id),
),
);
},
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(22),
border: Border.all(
color: green.withOpacity(0.08),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),
child: Stack(
children: [
// =================================================
// IMAGE
// =================================================
Positioned.fill(
child: CachedNetworkImage(
imageUrl: image,
fit: BoxFit.cover,
placeholder: (context, url) {
return Container(
color: green.withOpacity(0.06),
child: const Center(
child: SizedBox(
width: 25,
height: 25,
child: CircularProgressIndicator(
strokeWidth: 2.2,
color: green,
),
),
),
);
},
errorWidget: (context, url, error) {
return Container(
color: green.withOpacity(0.06),
child: const Center(
child: Icon(
Icons.broken_image_outlined,
color: Colors.grey,
size: 32,
),
),
);
},
),
),

// =================================================
// IMAGE OVERLAY
// =================================================
Positioned.fill(
child: DecoratedBox(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topCenter,
end: Alignment.bottomCenter,
colors: [
Colors.transparent,
Colors.black.withOpacity(0.08),
Colors.black.withOpacity(0.78),
],
stops: const [
0.25,
0.50,
1.0,
],
),
),
),
),

// =================================================
// TOP CATEGORY ICON
// =================================================
Positioned(
top: 12,
right: 12,
child: Container(
width: 34,
height: 34,
decoration: BoxDecoration(
color: Colors.white.withOpacity(0.90),
shape: BoxShape.circle,
),
child: const Icon(
Icons.restaurant_rounded,
color: green,
size: 18,
),
),
),

// =================================================
// CATEGORY NAME
// =================================================
Positioned(
left: 12,
right: 12,
bottom: 12,
child: Text(
getName(id),
textAlign: TextAlign.center,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
color: Colors.white,
fontSize: 17,
fontWeight: FontWeight.w800,
height: 1.15,
shadows: [
Shadow(
color: Colors.black54,
blurRadius: 5,
),
],
),
),
),
],
),
),
),
);
},
),
),
],
),
),
);
}
}
