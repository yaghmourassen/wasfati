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

  // ================= IMAGE PICK =================
  Future<File?> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) return File(picked.path);
    return null;
  }

  // ================= ADD =================
  void _showAddDialog() {
    final t = AppLocalizations.of(context)!;

    final titleController = TextEditingController();
    final descController = TextEditingController();
    final ingredientsController = TextEditingController();

    File? localImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).dialogBackgroundColor,

              title: Text(t.addRecipe),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: t.title,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),

                    TextField(
                      controller: descController,
                      decoration: InputDecoration(
                        labelText: t.description,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),

                    TextField(
                      controller: ingredientsController,
                      decoration: InputDecoration(
                        labelText: t.ingredients,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () async {
                        localImage = await pickImage();
                        setStateDialog(() {});
                      },
                      child: Text(t.pickImage),
                    ),

                    if (localImage != null)
                      Image.file(localImage!, height: 100),
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
                    if (titleController.text.isEmpty ||
                        descController.text.isEmpty) return;

                    setState(() => _isLoading = true);

                    try {
                      final ingredients = ingredientsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList();

                      String? imageUrl;

                      if (localImage != null) {
                        imageUrl = await controller.uploadToCloudinary(localImage!);
                      }

                      await controller.addRecipe(
                        title: titleController.text,
                        description: descController.text,
                        ingredients: ingredients,
                        imageUrl: imageUrl,
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${t.error}: $e")),
                      );
                    }

                    setState(() => _isLoading = false);
                  },
                  child: _isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Text(t.save),
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

    final titleController = TextEditingController(text: recipe.title);
    final descController = TextEditingController(text: recipe.description);
    final ingredientsController =
    TextEditingController(text: recipe.ingredients.join(','));

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Theme.of(context).dialogBackgroundColor,

          title: Text(t.editRecipe),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: t.title,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),

              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: t.description,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),

              TextField(
                controller: ingredientsController,
                decoration: InputDecoration(
                  labelText: t.ingredients,
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.cancel),
            ),

            ElevatedButton(
              onPressed: () async {
                final ingredients = ingredientsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList();

                await controller.updateRecipe(
                  id: recipe.id!,
                  title: titleController.text,
                  description: descController.text,
                  ingredients: ingredients,
                  imageUrl: recipe.imageUrl,
                );

                Navigator.pop(context);
              },
              child: Text(t.update),
            ),
          ],
        );
      },
    );
  }

  // ================= DELETE =================
  Future<void> _deleteRecipe(String id) async {
    final t = AppLocalizations.of(context)!;

    final confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).dialogBackgroundColor,

        title: Text(t.deleteRecipe),
        content: Text(t.deleteConfirm),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t.cancel),
          ),

          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deleteRecipe(id);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(t.appTitle),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<RecipeModel>>(
        stream: controller.getRecipesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(t.noRecipes));
          }

          final recipes = snapshot.data!;

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              return Card(
                color: Theme.of(context).cardColor,

                child: ListTile(
                  leading: recipe.imageUrl != null
                      ? Image.network(
                    recipe.imageUrl!,
                    width: 50,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.fastfood),

                  title: Text(recipe.title),
                  subtitle: Text(recipe.description),

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