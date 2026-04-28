import 'package:flutter/material.dart';

import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';
import '../core/user_session.dart';
import 'recipe_detail_view.dart';

class FavoritesView extends StatelessWidget {
  FavoritesView({super.key});

  final RecipeController controller = RecipeController();

  @override
  Widget build(BuildContext context) {
    final userId = UserSession.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorites ❤️"),
        centerTitle: true,
      ),

      body: StreamBuilder<List<RecipeModel>>(
        stream: controller.getFavoriteRecipes(userId),

        builder: (context, snapshot) {
          // 🔵 loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 🔴 error
          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong ❌"),
            );
          }

          final recipes = snapshot.data ?? [];

          // ⚪ empty state
          if (recipes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    "No favorites yet ❤️",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 🟢 list
          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              return Card(
                margin:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),

                  // 🖼 image
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: recipe.imageUrl != null
                        ? Image.network(
                      recipe.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.fastfood),
                    ),
                  ),

                  // 📝 title
                  title: Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // 📄 subtitle
                  subtitle: Text(
                    recipe.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 🔥 open details
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RecipeDetailView(recipe: recipe),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}