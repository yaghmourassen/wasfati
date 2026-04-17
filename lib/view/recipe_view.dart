import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';

class RecipeView extends StatefulWidget {
  const RecipeView({super.key});

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  final RecipeController controller = RecipeController();

  File? selectedImage;

  // ================= PICK IMAGE =================
  Future<void> pickImage(StateSetter setStateDialog) async {
    print("OPEN IMAGE PICKER");

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      print("IMAGE SELECTED: ${picked.path}");

      setState(() {
        selectedImage = File(picked.path);
      });

      setStateDialog(() {}); // تحديث الـ dialog
    } else {
      print("NO IMAGE SELECTED");
    }
  }

  // ================= ADD RECIPE DIALOG =================
  void _showAddRecipeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final ingredientsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Recipe"),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    TextField(
                      controller: descController,
                      decoration:
                      const InputDecoration(labelText: "Description"),
                    ),
                    TextField(
                      controller: ingredientsController,
                      decoration: const InputDecoration(
                        labelText: "Ingredients (comma separated)",
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ================= IMAGE BUTTON =================
                    TextButton.icon(
                      onPressed: () async {
                        await pickImage(setStateDialog);
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Choose Image"),
                    ),

                    if (selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.file(
                          selectedImage!,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedImage = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    final ingredientsList = ingredientsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList();

                    String? imageUrl;

                    if (selectedImage != null) {
                      imageUrl =
                      await controller.uploadToCloudinary(selectedImage!);
                    }

                    await controller.addRecipe(
                      title: titleController.text,
                      description: descController.text,
                      ingredients: ingredientsList,
                      imageUrl: imageUrl,
                    );

                    setState(() {
                      selectedImage = null;
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recipes"),
        backgroundColor: const Color(0xFF2E7D32),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        onPressed: _showAddRecipeDialog,
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<List<RecipeModel>>(
        stream: controller.getRecipesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No recipes yet 🍲"),
            );
          }

          final recipes = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              return Card(
                child: ListTile(
                  leading: recipe.imageUrl != null
                      ? Image.network(
                    recipe.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                      : const Icon(Icons.fastfood),

                  title: Text(recipe.title),
                  subtitle: Text(recipe.description),
                ),
              );
            },
          );
        },
      ),
    );
  }
}