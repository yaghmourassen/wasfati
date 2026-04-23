import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';
import '../generated/l10n/app_localizations.dart';
import 'recipe_detail_view.dart';

class RecipeView extends StatefulWidget {
  final String? categoryId;

  const RecipeView({super.key, this.categoryId});

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  final RecipeController controller = RecipeController();

  bool _isLoading = false;
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.categoryId;
  }

  final List<Map<String, String>> categories = [
    {"id": "breakfast"},
    {"id": "lunch"},
    {"id": "dinner"},
    {"id": "dessert"},
    {"id": "healthy"},
    {"id": "fastfood"},
    {"id": "traditional"},
    {"id": "drinks"},
  ];

  String _catName(BuildContext context, String? id) {
    final t = AppLocalizations.of(context)!;
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
        return id ?? "";
    }
  }

  Future<File?> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  // ================= ADD / EDIT DIALOG =================
  void _showRecipeDialog({RecipeModel? recipe}) {
    final t = AppLocalizations.of(context)!;

    final title = TextEditingController(text: recipe?.title ?? "");
    final desc = TextEditingController(text: recipe?.description ?? "");

    String? dialogCategory = recipe?.categoryId;
    File? image;

    List<String> ingredientsList =
    recipe != null ? List.from(recipe.ingredients) : [];

    TextEditingController ingredientCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(recipe == null ? t.addRecipe : t.editRecipe),

              content: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: dialogCategory,
                      items: categories.map((cat) {
                        final id = cat["id"]!;
                        return DropdownMenuItem(
                          value: id,
                          child: Text(_catName(context, id)),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setStateDialog(() => dialogCategory = value),
                      decoration:
                      InputDecoration(labelText: t.selectCategory),
                    ),

                    TextField(
                      controller: title,
                      decoration: InputDecoration(labelText: t.title),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: desc,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: t.description,
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ingredientCtrl,
                            decoration:
                            InputDecoration(labelText: t.ingredients),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            if (ingredientCtrl.text.isNotEmpty) {
                              setStateDialog(() {
                                ingredientsList.add(ingredientCtrl.text);
                                ingredientCtrl.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    Wrap(
                      children: ingredientsList
                          .map((e) => Chip(
                        label: Text(e),
                        onDeleted: () {
                          setStateDialog(() {
                            ingredientsList.remove(e);
                          });
                        },
                      ))
                          .toList(),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () async {
                        image = await pickImage();
                        setStateDialog(() {});
                      },
                      child: Text(t.pickImage),
                    ),

                    if (image != null)
                      Image.file(image!, height: 100)
                    else if (recipe?.imageUrl != null)
                      Image.network(recipe!.imageUrl!, height: 100),
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
                    if (title.text.isEmpty ||
                        desc.text.isEmpty ||
                        dialogCategory == null) {
                      return;
                    }

                    setState(() => _isLoading = true);

                    String? imageUrl = recipe?.imageUrl;

                    if (image != null) {
                      imageUrl =
                      await controller.uploadToCloudinary(image!);
                    }

                    String? error;

                    if (recipe == null) {
                      error = await controller.addRecipe(
                        title: title.text,
                        description: desc.text,
                        categoryId: dialogCategory!,
                        ingredients: ingredientsList,
                        imageUrl: imageUrl,
                      );
                    } else {
                      error = await controller.updateRecipe(
                        id: recipe.id!,
                        title: title.text,
                        description: desc.text,
                        categoryId: dialogCategory!,
                        ingredients: ingredientsList,
                        imageUrl: imageUrl,
                      );
                    }

                    setState(() => _isLoading = false);

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(t.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= DELETE =================
  Future<void> _deleteRecipe(String id) async {
    await controller.deleteRecipe(id);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(t.appTitle)),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecipeDialog(),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<RecipeModel>>(
        stream: selectedCategoryId == null
            ? controller.getRecipesStream()
            : controller.getRecipesByCategory(selectedCategoryId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final recipes = snapshot.data!;

          if (recipes.isEmpty) {
            return Center(child: Text(t.noRecipes));
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

                  title: Text(
                    recipe.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                      "${recipe.ingredients.length} ingredients • ${_catName(context, recipe.categoryId)}"),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () =>
                            _showRecipeDialog(recipe: recipe),
                      ),
                      IconButton(
                        icon:
                        const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            _deleteRecipe(recipe.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}