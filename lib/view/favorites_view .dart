import 'package:flutter/material.dart';

import '../controller/recipe_controller.dart';
import '../model/recipe_model.dart';
import '../core/user_session.dart';
import '../generated/l10n/app_localizations.dart';
import 'recipe_detail_view.dart';

class FavoritesView extends StatelessWidget {
  FavoritesView({super.key});

  final RecipeController controller = RecipeController();

  // ================= L18N HELPERS (DYNAMIC CONTENT) =================
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

  String _getDescription(BuildContext context, RecipeModel recipe) {
    final lang = _getLang(context);

    if (lang == 'ar' &&
        recipe.descriptionAr != null &&
        recipe.descriptionAr!.isNotEmpty) {
      return recipe.descriptionAr!;
    }

    if (recipe.descriptionEn != null &&
        recipe.descriptionEn!.isNotEmpty) {
      return recipe.descriptionEn!;
    }

    return recipe.description;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final userId = UserSession.userId;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.myFavorites),
        centerTitle: true,
      ),

      body: StreamBuilder<List<RecipeModel>>(
        stream: controller.getFavoriteRecipes(userId),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(t.somethingWrong),
            );
          }

          final recipes = snapshot.data ?? [];

          if (recipes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.favorite_border,
                    size: 60,
                    color: Theme.of(context).disabledColor,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    t.noFavorites,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),

                  // IMAGE
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

                  // ✅ FIXED TITLE (L18N)
                  title: Text(
                    _getTitle(context, recipe),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // ✅ FIXED DESCRIPTION (L18N)
                  subtitle: Text(
                    _getDescription(context, recipe),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // NAVIGATION
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