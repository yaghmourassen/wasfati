import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n/app_localizations.dart';
import 'recipe_view.dart';

class CategoryView extends StatelessWidget {
  const CategoryView({super.key});

  final List<Map<String, String>> categories = const [
    {
      "id": "breakfast",
      "image": "https://images.unsplash.com/photo-1525351484163-7529414344d8"
    },
    {
      "id": "lunch",
      "image": "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe"
    },
    {
      "id": "dinner",
      "image": "https://images.unsplash.com/photo-1476224203421-9ac39bcb3327"
    },
    {
      "id": "dessert",
      "image": "https://images.unsplash.com/photo-1551024601-bec78aea704b"
    },
    {
      "id": "healthy",
      "image": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd"
    },
    {
      "id": "fastfood",
      "image": "https://images.unsplash.com/photo-1561758033-d89a9ad46330"
    },
    {
      "id": "traditional",
      "image": "https://images.unsplash.com/photo-1604152135912-04a022e23696"
    },
    {
      "id": "drinks",
      "image": "https://images.unsplash.com/photo-1551024709-8f23befc6f87"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    String getName(String id) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(t.categories),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final id = cat["id"]!;
          final image = cat["image"]!;

          return Material(
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeView(categoryId: id),
                  ),
                );
              },
              child: Stack(
                children: [
                  /// 🔥 Cached Image (no flicker)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image),
                    ),
                  ),

                  /// 🌑 Gradient overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// 🏷️ Category name
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        getName(id),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}