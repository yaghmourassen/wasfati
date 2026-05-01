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

  List<String> _getIngredients(BuildContext context, RecipeModel recipe) {
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
                          onTap: () async {
                            await controller.increaseViews(recipe.id!);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecipeDetailView(recipe: recipe),
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

                          title: Text(_getTitle(context, recipe)),

                          subtitle: Text(
                            "${_getIngredients(context, recipe).length} ${t.ingredients}",
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
                                  final avgRating = recipe.rating;
                                  final isFilled = i < avgRating.round();

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
                                  "(${recipe.views})",
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
    // 🌍 Controllers
    final titleEnCtrl = TextEditingController();
    final titleArCtrl = TextEditingController();

    final stepEnCtrl = TextEditingController();
    final stepArCtrl = TextEditingController();

    String? selectedCategoryId = widget.categoryId;

    // 🌍 Ingredients L18N
    List<String> ingredientsEn = [];
    List<String> ingredientsAr = [];
    bool isArabicIngredient = false;

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

                  // 🔵 TITLE EN
                  TextField(
                    controller: titleEnCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title (EN)",
                    ),
                  ),

                  // 🔵 TITLE AR
                  TextField(
                    controller: titleArCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title (AR)",
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔵 DESCRIPTION EN
                  TextField(
                    controller: stepEnCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description (EN)",
                    ),
                  ),

                  // 🔵 DESCRIPTION AR
                  TextField(
                    controller: stepArCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description (AR)",
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 CATEGORY
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

                  // 🔥 INGREDIENTS TOGGLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isArabicIngredient ? "AR" : "EN"),
                      Switch(
                        value: isArabicIngredient,
                        onChanged: (value) {
                          setState(() {
                            isArabicIngredient = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔥 INGREDIENTS CHIPS
                  Wrap(
                    spacing: 6,
                    children: [
                      ...ingredientsEn.map((e) {
                        return Chip(
                          label: Text(e),
                          onDeleted: () {
                            setState(() {
                              ingredientsEn.remove(e);
                            });
                          },
                        );
                      }),
                      ...ingredientsAr.map((e) {
                        return Chip(
                          label: Text(e),
                          onDeleted: () {
                            setState(() {
                              ingredientsAr.remove(e);
                            });
                          },
                        );
                      }),
                    ],
                  ),

                  // 🔥 INGREDIENT INPUT
                  TextField(
                    onSubmitted: (value) {
                      setState(() {
                        final text = value.trim();
                        if (text.isEmpty) return;

                        if (isArabicIngredient) {
                          ingredientsAr.add(text);
                        } else {
                          ingredientsEn.add(text);
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: t.ingredients,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 IMAGE
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

            // 🔥 ACTIONS
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),

              ElevatedButton(
                onPressed: () async {
                  String? imageUrl;

                  if (image != null) {
                    imageUrl = await controller.uploadToCloudinary(image!);
                  }

                  // 🚀 SAVE RECIPE (FULL L18N)
                  await controller.addRecipe(
                    title: titleEnCtrl.text.trim(),
                    description: stepEnCtrl.text.trim(),
                    categoryId: selectedCategoryId ?? "",
                    imageUrl: imageUrl,

                    // 🌍 L18N
                    titleEn: titleEnCtrl.text.trim(),
                    titleAr: titleArCtrl.text.trim(),
                    descriptionEn: stepEnCtrl.text.trim(),
                    descriptionAr: stepArCtrl.text.trim(),

                    ingredientsEn: ingredientsEn,
                    ingredientsAr: ingredientsAr,

                    // ✅ FIX REQUIRED
                    ingredients: ingredientsEn,
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
    // 🌍 EN / AR controllers (LIKE ADD METHOD)
    final titleEnCtrl =
    TextEditingController(text: recipe.titleEn ?? "");

    final titleArCtrl =
    TextEditingController(text: recipe.titleAr ?? "");

    final stepEnCtrl =
    TextEditingController(text: recipe.descriptionEn ?? "");

    final stepArCtrl =
    TextEditingController(text: recipe.descriptionAr ?? "");

    // 📂 CATEGORY
    String? selectedCategoryId = recipe.categoryId;

    // 🥗 INGREDIENTS (L18N)
    List<String> ingredientsEn =
    List.from(recipe.ingredientsEn ?? []);

    List<String> ingredientsAr =
    List.from(recipe.ingredientsAr ?? []);

    bool isArabicIngredient = false;

    // 🖼 IMAGE
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

                  // ================= TITLE EN =================
                  TextField(
                    controller: titleEnCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title (EN)",
                    ),
                  ),

                  // ================= TITLE AR =================
                  TextField(
                    controller: titleArCtrl,
                    decoration: const InputDecoration(
                      labelText: "Title (AR)",
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= DESC EN =================
                  TextField(
                    controller: stepEnCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description (EN)",
                    ),
                  ),

                  // ================= DESC AR =================
                  TextField(
                    controller: stepArCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description (AR)",
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= CATEGORY =================
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

                  // ================= INGREDIENT TOGGLE =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isArabicIngredient ? "AR" : "EN"),
                      Switch(
                        value: isArabicIngredient,
                        onChanged: (value) {
                          setState(() {
                            isArabicIngredient = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ================= INGREDIENT CHIPS =================
                  Wrap(
                    spacing: 6,
                    children: [
                      ...ingredientsEn.map((e) => Chip(
                        label: Text(e),
                        onDeleted: () {
                          setState(() {
                            ingredientsEn.remove(e);
                          });
                        },
                      )),

                      ...ingredientsAr.map((e) => Chip(
                        label: Text(e),
                        onDeleted: () {
                          setState(() {
                            ingredientsAr.remove(e);
                          });
                        },
                      )),
                    ],
                  ),

                  // ================= INGREDIENT INPUT =================
                  TextField(
                    onSubmitted: (value) {
                      setState(() {
                        final text = value.trim();
                        if (text.isEmpty) return;

                        if (isArabicIngredient) {
                          ingredientsAr.add(text);
                        } else {
                          ingredientsEn.add(text);
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: t.ingredients,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= IMAGE =================
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

            // ================= ACTIONS =================
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),

              ElevatedButton(
                onPressed: () async {
                  try {
                    String? newImageUrl = imageUrl;

                    // 📤 upload image if changed
                    if (image != null) {
                      newImageUrl =
                      await controller.uploadToCloudinary(image!);
                    }

                    // 🚀 UPDATE RECIPE (FULL L18N)
                    final result = await controller.updateRecipe(
                      id: recipe.id!,

                      // base fields (fallback)
                      title: titleEnCtrl.text.trim(),
                      description: stepEnCtrl.text.trim(),
                      categoryId: selectedCategoryId ?? "",

                      // multilingual fields
                      titleEn: titleEnCtrl.text.trim(),
                      titleAr: titleArCtrl.text.trim(),

                      descriptionEn: stepEnCtrl.text.trim(),
                      descriptionAr: stepArCtrl.text.trim(),

                      ingredients: ingredientsEn,
                      ingredientsEn: ingredientsEn,
                      ingredientsAr: ingredientsAr,

                      imageUrl: newImageUrl,
                    );

                    if (result != null) {
                      print("❌ UPDATE FAILED: $result");
                      return;
                    }

                    print("✅ UPDATE SUCCESS");

                    Navigator.pop(context);
                    setState(() {});
                  } catch (e) {
                    print("🔥 UPDATE ERROR: $e");
                  }
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