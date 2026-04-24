import 'package:flutter/material.dart';
import '../model/recipe_model.dart';
import '../generated/l10n/app_localizations.dart';

class RecipeDetailView extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailView({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [

          // ================= HERO IMAGE =================
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.black), // 👈 FIX

            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
              background: recipe.imageUrl != null
                  ? Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
              )
                  : Container(color: Colors.grey),
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
                    recipe.title,
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
                    children: recipe.ingredients.map((item) {
                      return Chip(
                        label: Text(item),
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

                  _buildSteps(context, recipe.description),

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