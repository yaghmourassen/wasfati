import 'package:flutter/material.dart';
import '../model/recipe_model.dart';

class RecipeDetailView extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailView({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 📸 IMAGE
            if (recipe.imageUrl != null)
              Image.network(
                recipe.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),

            const SizedBox(height: 15),

            // 🍽 TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 🥕 INGREDIENTS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ingredients",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.ingredients.join(", "),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 👨‍🍳 DESCRIPTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "How to prepare",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}