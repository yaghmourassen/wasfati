import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';
import '../generated/l10n/app_localizations.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({super.key});

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  final RecipeController controller = RecipeController();

  bool _isLoading = false;
  String? selectedCategoryId;

  // ================= CATEGORY IDS ONLY =================
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

  // ================= TRANSLATION =================
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

  // ================= IMAGE PICK =================
  Future<File?> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    return picked != null ? File(picked.path) : null;
  }

  // ================= ADD =================
  void _showAddDialog() {
    final t = AppLocalizations.of(context)!;

    final title = TextEditingController();
    final desc = TextEditingController();
    final ingredients = TextEditingController();

    String? dialogCategory;
    File? image;

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
                      decoration: InputDecoration(
                        labelText: t.selectCategory,
                      ),
                    ),

                    TextField(
                      controller: title,
                      decoration: InputDecoration(labelText: t.title),
                    ),

                    TextField(
                      controller: desc,
                      decoration: InputDecoration(labelText: t.description),
                    ),

                    TextField(
                      controller: ingredients,
                      decoration: InputDecoration(labelText: t.ingredients),
                    ),

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
                      ingredients: ingredients.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList(),
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

  // ================= EDIT =================
  void _showEditDialog(RecipeModel recipe) {
    final t = AppLocalizations.of(context)!;

    final title = TextEditingController(text: recipe.title);
    final desc = TextEditingController(text: recipe.description);
    final ingredients =
    TextEditingController(text: recipe.ingredients.join(','));

    String? editCategory = recipe.categoryId;
    File? newImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(t.editRecipe),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    DropdownButtonFormField<String>(
                      value: editCategory,
                      items: categories.map((cat) {
                        final id = cat["id"]!;
                        return DropdownMenuItem(
                          value: id,
                          child: Text(_catName(context, id)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() => editCategory = value);
                      },
                      decoration: InputDecoration(
                        labelText: t.selectCategory,
                      ),
                    ),

                    TextField(
                      controller: title,
                      decoration: InputDecoration(labelText: t.title),
                    ),

                    TextField(
                      controller: desc,
                      decoration: InputDecoration(labelText: t.description),
                    ),

                    TextField(
                      controller: ingredients,
                      decoration: InputDecoration(labelText: t.ingredients),
                    ),

                    TextButton(
                      onPressed: () async {
                        newImage = await pickImage();
                        setStateDialog(() {});
                      },
                      child: Text(t.pickImage),
                    ),

                    if (newImage != null)
                      Image.file(newImage!, height: 100)
                    else if (recipe.imageUrl != null)
                      Image.network(recipe.imageUrl!, height: 100),
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
                    if (editCategory == null) return;

                    String? updatedImageUrl = recipe.imageUrl;

                    if (newImage != null) {
                      updatedImageUrl =
                      await controller.uploadToCloudinary(newImage!);
                    }

                    await controller.updateRecipe(
                      id: recipe.id!,
                      title: title.text,
                      description: desc.text,
                      categoryId: editCategory!,
                      ingredients: ingredients.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList(),
                      imageUrl: updatedImageUrl,
                    );

                    Navigator.pop(context);
                  },
                  child: Text(t.update),
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
                  leading: recipe.imageUrl != null
                      ? Image.network(recipe.imageUrl!, width: 50)
                      : const Icon(Icons.fastfood),

                  title: Text(recipe.title),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipe.description),
                      const SizedBox(height: 4),
                      Text(
                        _catName(context, recipe.categoryId),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(recipe),
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