import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';
import '../generated/l10n/app_localizations.dart';
import '../core/user_session.dart';
import 'recipe_detail_view.dart';

class RecipeView extends StatefulWidget {
  final String? categoryId;

  const RecipeView({super.key, this.categoryId});

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  final RecipeController controller = RecipeController();

  String searchText = "";
  String sortBy = "date";

  Future<File?> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isAdmin = UserSession.isAdmin;

    return Scaffold(
      appBar: AppBar(title: Text(t.appTitle)),

      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      )
          : null,

      body: Column(
        children: [

          // ================= SEARCH =================
          if (!isAdmin)
            SafeArea(
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: t.searchRecipes, // ✅ L10N
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchText = value.toLowerCase();
                          });
                        },
                      ),
                    ),

                    PopupMenuButton<String>(
                      icon: const Icon(Icons.tune),
                      onSelected: (value) {
                        setState(() {
                          sortBy = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "date",
                          child: Text(t.newest), // ✅ L10N
                        ),
                        PopupMenuItem(
                          value: "rating",
                          child: Text(t.topRated), // ✅ L10N
                        ),
                        PopupMenuItem(
                          value: "views",
                          child: Text(t.mostViewed), // ✅ L10N
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ================= LIST =================
          Expanded(
            child: StreamBuilder<List<RecipeModel>>(
              stream: controller.getRecipesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<RecipeModel> recipes = snapshot.data!;

                // SEARCH
                if (!isAdmin) {
                  recipes = recipes
                      .where((r) =>
                      r.title.toLowerCase().contains(searchText))
                      .toList();

                  if (sortBy == "rating") {
                    recipes.sort((a, b) => b.rating.compareTo(a.rating));
                  } else if (sortBy == "views") {
                    recipes.sort((a, b) => b.views.compareTo(a.views));
                  }
                }

                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipeDetailView(recipe: recipe),
                            ),
                          );
                        },

                        leading: recipe.imageUrl != null
                            ? Image.network(recipe.imageUrl!,
                            width: 50, fit: BoxFit.cover)
                            : const Icon(Icons.fastfood),

                        title: Text(recipe.title),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${recipe.ingredients.length} ${t.ingredients}"), // ✅ L10N

                            const SizedBox(height: 5),

                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  recipe.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),

                        trailing: isAdmin
                            ? const SizedBox()
                            : SizedBox(
                          width: 110,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: List.generate(5, (i) {
                              return GestureDetector(
                                onTap: () {
                                  controller.rateRecipe(
                                    recipeId: recipe.id!,
                                    rating: (i + 1).toDouble(),
                                  );
                                },
                                child: const Icon(
                                  Icons.star,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}