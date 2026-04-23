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

                  // 🍽 TITLE (small secondary title)
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
                        backgroundColor: Colors.green.shade50,
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

                  _buildSteps(recipe.description),

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
  Widget _buildSteps(String text) {
    // نحاول نفصل الخطوات حسب الأرقام أو السطور
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
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                child: Text("${index + 1}"),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  steps[index].trim(),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}