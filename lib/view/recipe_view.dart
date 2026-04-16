import 'dart:ui';
import 'package:flutter/material.dart';
import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';

class RecipeView extends StatelessWidget {
  const RecipeView({super.key});

  @override
  Widget build(BuildContext context) {
    final RecipeController controller = RecipeController();
    final Color accentColor = const Color(0xFFD3756B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: accentColor,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDFCFB), Color(0xFFE2D1C3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<RecipeModel>>(
            stream: controller.getRecipesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No recipes found.'));
              }

              final recipes = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recipe.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ingredients: ${recipe.ingredients.join(', ')}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showRecipeDialog(context, controller, recipe: recipe);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    controller.deleteRecipe(recipe.id!);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentColor,
        child: const Icon(Icons.add),
        onPressed: () {
          _showRecipeDialog(context, controller);
        },
      ),
    );
  }

  /// Dialog for Add / Edit Recipe
  void _showRecipeDialog(BuildContext context, RecipeController controller, {RecipeModel? recipe}) {
    final TextEditingController titleController =
    TextEditingController(text: recipe?.title ?? '');
    final TextEditingController descriptionController =
    TextEditingController(text: recipe?.description ?? '');
    final TextEditingController ingredientsController =
    TextEditingController(text: recipe?.ingredients.join(', ') ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(recipe == null ? 'Add Recipe' : 'Edit Recipe'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: ingredientsController,
                decoration: const InputDecoration(labelText: 'Ingredients (comma separated)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final description = descriptionController.text.trim();
              final ingredients = ingredientsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              if (recipe == null) {
                // Add new recipe
                controller.addRecipe(
                  title: title,
                  description: description,
                  ingredients: ingredients,
                );
              } else {
                // Update existing recipe
                controller.updateRecipe(
                  id: recipe.id!,
                  title: title,
                  description: description,
                  ingredients: ingredients,
                );
              }

              Navigator.pop(context);
            },
            child: Text(recipe == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }
}
