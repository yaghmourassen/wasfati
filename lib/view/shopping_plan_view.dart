
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import 'package:wasfati/controller/shopping_plan_controller.dart';
import 'package:wasfati/services/account_service.dart';

class ShoppingPlanView extends StatefulWidget {
const ShoppingPlanView({super.key});

@override
State<ShoppingPlanView> createState() => _ShoppingPlanViewState();
}

class _ShoppingPlanViewState extends State<ShoppingPlanView> {
final TextEditingController itemController = TextEditingController();

@override
void initState() {
super.initState();

// ✅ Load user shopping list from DB once screen opens
Future.microtask(() {
Provider.of<ShoppingPlanController>(context, listen: false)
    .listenToUserItems();
});
}

@override
void dispose() {
itemController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
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
t.shoppingPlan,
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

body: Consumer<ShoppingPlanController>(
builder: (context, controller, child) {
return Padding(
padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
child: Column(
children: [
// =====================================================
// ADD ITEM CARD
// =====================================================
Container(
width: double.infinity,
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(20),
border: Border.all(
color: green.withOpacity(0.08),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.04),
blurRadius: 15,
offset: const Offset(0, 6),
),
],
),
child: Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: green.withOpacity(0.10),
borderRadius: BorderRadius.circular(14),
),
child: const Icon(
Icons.shopping_basket_rounded,
color: green,
size: 22,
),
),

const SizedBox(width: 10),

Expanded(
child: TextField(
controller: itemController,
textInputAction: TextInputAction.done,
onSubmitted: (_) {
final text = itemController.text.trim();

if (text.isEmpty) return;

controller.addItem(text);
itemController.clear();

FocusScope.of(context).unfocus();
},
style: theme.textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.w600,
),
decoration: InputDecoration(
hintText: t.addIngredient,
hintStyle:
theme.textTheme.bodyMedium?.copyWith(
color: theme.textTheme.bodyMedium?.color
    ?.withOpacity(0.45),
),
border: InputBorder.none,
contentPadding: const EdgeInsets.symmetric(
horizontal: 4,
vertical: 12,
),
),
),
),

const SizedBox(width: 6),

Material(
color: green,
borderRadius: BorderRadius.circular(14),
child: InkWell(
borderRadius: BorderRadius.circular(14),
onTap: () {
final text = itemController.text.trim();

if (text.isEmpty) return;

controller.addItem(text);
itemController.clear();

FocusScope.of(context).unfocus();
},
child: const SizedBox(
width: 46,
height: 46,
child: Icon(
Icons.add_rounded,
color: Colors.white,
size: 25,
),
),
),
),
],
),
),

const SizedBox(height: 20),

// =====================================================
// LIST HEADER
// =====================================================
if (controller.items.isNotEmpty)
Padding(
padding: const EdgeInsets.symmetric(
horizontal: 4,
vertical: 2,
),
child: Row(
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
Expanded(
child: Text(
t.shoppingPlan,
style: theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
),
),
),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 5,
),
decoration: BoxDecoration(
color: green.withOpacity(0.09),
borderRadius: BorderRadius.circular(20),
),
child: Text(
'${controller.items.length}',
style: const TextStyle(
color: green,
fontWeight: FontWeight.w800,
fontSize: 12,
),
),
),
],
),
),

if (controller.items.isNotEmpty)
const SizedBox(height: 10),

// =====================================================
// LIST / EMPTY STATE
// =====================================================
Expanded(
child: controller.items.isEmpty
? Center(
child: Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 28,
vertical: 34,
),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(24),
border: Border.all(
color: green.withOpacity(0.07),
),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 76,
height: 76,
decoration: BoxDecoration(
color: green.withOpacity(0.09),
shape: BoxShape.circle,
),
child: const Icon(
Icons.shopping_cart_outlined,
size: 38,
color: green,
),
),

const SizedBox(height: 18),

Text(
t.emptyList,
textAlign: TextAlign.center,
style:
theme.textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.w800,
),
),

const SizedBox(height: 7),

Text(
t.addIngredient,
textAlign: TextAlign.center,
style: theme.textTheme.bodySmall?.copyWith(
color: theme.textTheme.bodySmall?.color
    ?.withOpacity(0.55),
height: 1.4,
),
),
],
),
),
)
    : ListView.builder(
physics: const BouncingScrollPhysics(),
padding: const EdgeInsets.only(
bottom: 10,
top: 2,
),
itemCount: controller.items.length,
itemBuilder: (context, index) {
final item = controller.items[index];

return Container(
margin: const EdgeInsets.only(bottom: 10),
decoration: BoxDecoration(
color: theme.cardColor,
borderRadius: BorderRadius.circular(18),
border: Border.all(
color: item.isDone
? green.withOpacity(0.14)
    : Colors.black.withOpacity(0.05),
),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.035),
blurRadius: 12,
offset: const Offset(0, 5),
),
],
),
child: Padding(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 7,
),
child: Row(
children: [
// CHECKBOX
Theme(
data: Theme.of(context).copyWith(
checkboxTheme: CheckboxThemeData(
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(6),
),
side: BorderSide(
color: green.withOpacity(0.45),
width: 1.5,
),
),
),
child: Checkbox(
activeColor: green,
value: item.isDone,
onChanged: (_) {
controller.toggleItem(item);
},
),
),

const SizedBox(width: 3),

// ITEM NAME
Expanded(
child: Text(
item.name,
style: theme.textTheme.bodyMedium
    ?.copyWith(
fontWeight: FontWeight.w700,
color: item.isDone
? theme.textTheme.bodyMedium?.color
    ?.withOpacity(0.45)
    : null,
decoration: item.isDone
? TextDecoration.lineThrough
    : null,
decorationThickness: 1.5,
),
),
),

// DELETE
Material(
color: Colors.red.withOpacity(0.07),
borderRadius: BorderRadius.circular(12),
child: InkWell(
borderRadius:
BorderRadius.circular(12),
onTap: () {
controller.deleteItem(item.id);
},
child: const SizedBox(
width: 40,
height: 40,
child: Icon(
Icons.delete_outline_rounded,
color: Colors.red,
size: 20,
),
),
),
),
],
),
),
);
},
),
),
],
),
);
},
),
);
}
}
