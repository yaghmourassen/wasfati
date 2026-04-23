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
    if (id == null) return "";

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

  Future<File?> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked != null ? File(picked.path) : null;
  }

  // ================= ADD RECIPE =================
  void _showAddDialog() {
    final t = AppLocalizations.of(context)!;

    final title = TextEditingController();
    final desc = TextEditingController();

    String? dialogCategory;
    File? image;

    List<String> ingredientsList = [];
    TextEditingController ingredientCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(t.addRecipe),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      onChanged: (value) {
                        setStateDialog(() => dialogCategory = value);
                      },
                      decoration: InputDecoration(labelText: t.selectCategory),
                    ),

                    TextField(
                      controller: title,
                      decoration: InputDecoration(labelText: t.title),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: desc,
                      maxLines: 4,
                      minLines: 2,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        labelText: t.description,
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // INGREDIENTS INPUT
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ingredientCtrl,
                            decoration: InputDecoration(
                              labelText: t.ingredients,
                            ),
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
                          .map((e) => Chip(label: Text(e)))
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
                      Image.file(image!, height: 100),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.cancel),
                ),

                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (title.text.isEmpty ||
                        desc.text.isEmpty ||
                        dialogCategory == null) return;

                    setState(() => _isLoading = true);

                    String? imageUrl;
                    if (image != null) {
                      imageUrl = await controller.uploadToCloudinary(image!);
                    }

                    await controller.addRecipe(
                      title: title.text,
                      description: desc.text,
                      categoryId: dialogCategory!,
                      ingredients: ingredientsList,
                      imageUrl: imageUrl,
                    );

                    setState(() => _isLoading = false);
                    Navigator.pop(context);
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
        onPressed: _showAddDialog,
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
                      ? Image.network(recipe.imageUrl!, width: 50, fit: BoxFit.cover)
                      : const Icon(Icons.fastfood),

                  title: Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      Text(
                        "${recipe.ingredients.length} ingredients",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        _catName(context, recipe.categoryId),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteRecipe(recipe.id!),
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