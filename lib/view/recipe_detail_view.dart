import 'package:flutter/material.dart';
import '../controller/recipe_controller.dart';
import '../core/user_session.dart';
import '../model/recipe_model.dart';
import '../generated/l10n/app_localizations.dart';

class RecipeDetailView extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailView({
    super.key,
    required this.recipe,
  });

  // 🌍 SIMPLE L18N RESOLVER (uses existing system)
  String _getLang(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  String _getTitle(BuildContext context) {
    final lang = _getLang(context);

    if (lang == 'ar' && recipe.titleAr != null && recipe.titleAr!.isNotEmpty) {
      return recipe.titleAr!;
    }

    if (recipe.titleEn != null && recipe.titleEn!.isNotEmpty) {
      return recipe.titleEn!;
    }

    return recipe.title;
  }

  String _getDescription(BuildContext context) {
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

  List<String> _getIngredients(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final title = _getTitle(context);
    final description = _getDescription(context);
    final ingredients = _getIngredients(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [

          // ================= HERO IMAGE =================
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Colors.black,

            actions: [
              StreamBuilder<bool>(
                stream: RecipeController()
                    .isFavorite(UserSession.userId, recipe.id!),
                builder: (context, snapshot) {
                  final isFav = snapshot.data ?? false;

                  return IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isFav),
                        color: isFav ? Colors.red : Colors.white,
                        size: 26,
                      ),
                    ),
                    onPressed: () async {
                      if (UserSession.userId.isEmpty) return;

                      await RecipeController().toggleFavorite(
                        userId: UserSession.userId,
                        recipeId: recipe.id!,
                      );
                    },
                  );
                },
              ),
            ],

            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 8),
                  ],
                ),
              ),

              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 🖼 Image
                  recipe.imageUrl != null
                      ? Image.network(
                    recipe.imageUrl!,
                    fit: BoxFit.cover,
                  )
                      : Container(color: Colors.grey),

                  // 🌑 Gradient overlay (احترافي)
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black54,
                          Colors.black87,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= CONTENT =================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🍽 TITLE
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= INGREDIENTS =================
                  Text(
                    t.ingredients,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ingredients.map((item) {
                      return Chip(
                        label: Text(item),
                        backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                        labelStyle: TextStyle(
                          color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 25),

                  // ================= STEPS =================
                  Text(
                    t.howToPrepare,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  _buildSteps(context, description),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= STEPS PARSER =================
  Widget _buildSteps(BuildContext context, String text) {
    final steps = text
        .split(RegExp(r'\n|\d+\.\s'))
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Column(
      children: List.generate(steps.length, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  steps[index].trim(),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}