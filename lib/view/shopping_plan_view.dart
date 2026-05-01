import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../generated/l10n/app_localizations.dart';
import 'package:wasfati_fb/controller/shopping_plan_controller.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(t.shoppingPlan),
        backgroundColor: const Color(0xFF2E7D32),
        centerTitle: true,
      ),

      body: Consumer<ShoppingPlanController>(
        builder: (context, controller, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // ================= INPUT =================
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [

                      Expanded(
                        child: TextField(
                          controller: itemController,
                          decoration: InputDecoration(
                            hintText: t.addIngredient,
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          final text = itemController.text.trim();

                          if (text.isEmpty) return;

                          controller.addItem(text);
                          itemController.clear();

                          FocusScope.of(context).unfocus(); // close keyboard
                        },
                        icon: const Icon(
                          Icons.add_circle,
                          color: Color(0xFF2E7D32),
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ================= LIST =================
                Expanded(
                  child: controller.items.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 70,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.emptyList,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    itemCount: controller.items.length,
                    itemBuilder: (context, index) {
                      final item = controller.items[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            activeColor: const Color(0xFF2E7D32),
                            value: item.isDone,
                            onChanged: (_) {
                              controller.toggleItem(item);
                            },
                          ),

                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: item.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),

                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              controller.deleteItem(item.id);
                            },
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