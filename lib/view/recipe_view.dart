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
  String sortBy = "date"; // ✅ RESTORED
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
        title: Text(t.appTitle),
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () => _showAddRecipeDialog(context, t),
        child: const Icon(Icons.add),
      )
          : null,

      body: Column(
        children: [

          // ================= SEARCH + FILTER (RESTORED) =================
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
                          hintText: t.searchRecipes,
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
                          child: Text(t.newest),
                        ),
                        PopupMenuItem(
                          value: "rating",
                          child: Text(t.topRated),
                        ),
                        PopupMenuItem(
                          value: "views",
                          child: Text(t.mostViewed),
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
                if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
                  recipes = recipes
                      .where((r) => r.categoryId == widget.categoryId)
                      .toList();
                }
                // ================= SEARCH (RESTORED) =================
                recipes = recipes
                    .where((r) =>
                    r.title.toLowerCase().contains(searchText))
                    .toList();

                // ================= SORT (RESTORED) =================
                if (!isAdmin) {
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
                            ? Image.network(
                          recipe.imageUrl!,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.fastfood),

                        title: Text(recipe.title),

                          subtitle: Text(
                            "${recipe.ingredients.length} ${t.ingredients}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),

                        // ================= ADMIN / USER FIX =================
                        trailing: isAdmin
                            ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "edit") {
                              _showEditRecipeDialog(context, t, recipe);
                            }

                            if (value == "delete") {
                              controller.deleteRecipe(recipe.id!);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "edit",
                              child: Text(t.editRecipe),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: Text(t.delete),
                            ),
                          ],
                        ):
                        StatefulBuilder(
                          builder: (context, setStateLocal) {
                            int hoveredRating = 0;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...List.generate(5, (i) {
                                  final userId = UserSession.userId;
                                  final userRating = recipe.userRatings[userId] ?? 0;

                                  final isFilled = i < userRating.round();

                                  return GestureDetector(
                                    onTap: () async {
                                      if (userId.isEmpty) return;

                                      final alreadyRated =
                                      recipe.userRatings.containsKey(userId);

                                      if (alreadyRated) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("You already rated this recipe"),
                                          ),
                                        );
                                        return;
                                      }

                                      await controller.rateRecipe(
                                        recipeId: recipe.id!,
                                        rating: (i + 1).toDouble(),
                                        userId: userId,
                                      );

                                      setState(() {});
                                    },
                                    child: Icon(
                                      Icons.star,
                                      size: 20,
                                      color: isFilled
                                          ? Colors.amber
                                          : Colors.grey.shade400,
                                    ),
                                  );
                                }),

                                const SizedBox(width: 6),

                                Text(
                                  recipe.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),

                                const SizedBox(width: 4),

                                Text(
                                  "(${recipe.ratingCount})",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        )
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

  // ================= ADD (UNCHANGED) =================
  // ================= ADD (UPDATED ONLY THIS PART) =================
  void _showAddRecipeDialog(BuildContext context, AppLocalizations t) {
    final titleCtrl = TextEditingController();
    final stepCtrl = TextEditingController();

    // ✅ FIX: initialize with incoming category
    String? selectedCategoryId = widget.categoryId;

    List<String> ingredients = [];
    File? image;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(t.addRecipe),
            content: SingleChildScrollView(
              child: Column(
                children: [

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: t.title),
                  ),

                  TextField(
                    controller: stepCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: t.howToPrepare),
                  ),

                  // 🔥 NEW: CATEGORY DROPDOWN
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    hint: const Text("Select Category"),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat["id"],
                        child: Text(
                          getCategoryName(cat["id"]!, t),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 6,
                    children: ingredients
                        .map((e) => Chip(
                      label: Text(e),
                      onDeleted: () {
                        setState(() {
                          ingredients.remove(e);
                        });
                      },
                    ))
                        .toList(),
                  ),

                  TextField(
                    onSubmitted: (value) {
                      setState(() {
                        ingredients.add(value.trim());
                      });
                    },
                    decoration: InputDecoration(
                      hintText: t.ingredients,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (image != null)
                    Image.file(image!, height: 100),

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );

                      if (picked != null) {
                        setState(() {
                          image = File(picked.path);
                        });
                      }
                    },
                    child: Text(t.pickImage),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? imageUrl;

                  if (image != null) {
                    imageUrl =
                    await controller.uploadToCloudinary(image!);
                  }

                  // ✅ FIX: use selectedCategoryId
                  await controller.addRecipe(
                    title: titleCtrl.text.trim(),
                    description: stepCtrl.text.trim(),
                    categoryId: selectedCategoryId ?? "",
                    ingredients: ingredients,
                    imageUrl: imageUrl,
                  );

                  Navigator.pop(context);
                },
                child: Text(t.save),
              ),
            ],
          );
        },
      ),
    );
  }
  // ================= EDIT (UNCHANGED) =================
  void _showEditRecipeDialog(
      BuildContext context,
      AppLocalizations t,
      RecipeModel recipe,
      ) {
    final titleCtrl = TextEditingController(text: recipe.title);
    final stepCtrl =
    TextEditingController(text: recipe.description);

    // ✅ FIX: allow editing category
    String? selectedCategoryId = recipe.categoryId;

    List<String> ingredients =
    List.from(recipe.ingredients);

    File? image;
    String? imageUrl = recipe.imageUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(t.editRecipe),
            content: SingleChildScrollView(
              child: Column(
                children: [

                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(labelText: t.title),
                  ),

                  TextField(
                    controller: stepCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(labelText: t.howToPrepare),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 CATEGORY DROPDOWN (NEW)
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    hint: const Text("Select Category"),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat["id"],
                        child: Text(getCategoryName(cat["id"]!, t)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 6,
                    children: ingredients
                        .map((e) => Chip(
                      label: Text(e),
                      onDeleted: () {
                        setState(() {
                          ingredients.remove(e);
                        });
                      },
                    ))
                        .toList(),
                  ),

                  TextField(
                    onSubmitted: (value) {
                      setState(() {
                        ingredients.add(value.trim());
                      });
                    },
                    decoration: InputDecoration(
                      hintText: t.ingredients,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (image != null)
                    Image.file(image!, height: 100)
                  else if (imageUrl != null)
                    Image.network(imageUrl!, height: 100),

                  ElevatedButton(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );

                      if (picked != null) {
                        setState(() {
                          image = File(picked.path);
                        });
                      }
                    },
                    child: Text(t.pickImage),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),

              ElevatedButton(
                onPressed: () async {
                  if (image != null) {
                    imageUrl =
                    await controller.uploadToCloudinary(image!);
                  }

                  // ✅ FIX: use selectedCategoryId instead of recipe.categoryId
                  await controller.updateRecipe(
                    id: recipe.id!,
                    title: titleCtrl.text.trim(),
                    description: stepCtrl.text.trim(),
                    categoryId: selectedCategoryId ?? "",
                    ingredients: ingredients,
                    imageUrl: imageUrl,
                  );

                  Navigator.pop(context);
                },
                child: Text(t.update),
              ),
            ],
          );
        },
      ),
    );
  }
}