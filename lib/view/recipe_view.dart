import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/recipe_controller.dart';

import '../generated/l10n/app_localizations.dart';
import '../core/user_session.dart';
import '../model/recipe_model.dart';
import 'recipe_detail_view.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RecipeView extends StatefulWidget {
  final String? categoryId;

  const RecipeView({super.key, this.categoryId});

  @override
  State<RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends State<RecipeView> {
  @override
  void dispose() {
    bannerAd?.dispose();
    interstitialAd?.dispose();
    super.dispose();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: "ca-app-pub-3185716051823285/5008108652",
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;

          interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  interstitialAd = null;
                  loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  ad.dispose();
                  interstitialAd = null;
                  loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          interstitialAd = null;
          Future.delayed(const Duration(seconds: 3), loadInterstitialAd);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    loadInterstitialAd();

    bannerAd = BannerAd(
      adUnitId: "ca-app-pub-3185716051823285/7834634897",
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Banner failed: $error");
        },
      ),
    );

    bannerAd!.load();
  }

  String _getLang(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  BannerAd? bannerAd;
  bool isAdLoaded = false;
  InterstitialAd? interstitialAd;
  int openCount = 0;

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

  List<String> _getIngredients(BuildContext context, RecipeModel recipe) {
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

  final RecipeController controller = RecipeController();

  String searchText = "";
  String sortBy = "date";
  final List<Map<String, String>> categories = const [
    {"id": "breakfast"},
    {"id": "lunch"},
    {"id": "dinner"},
    {"id": "dessert"},
    {"id": "healthy"},
    {"id": "fastfood"},
    {"id": "traditional"},
    {"id": "drinks"},
  ];

  String getCategoryName(String id, AppLocalizations t) {
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isAdmin = UserSession.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: () => _showAddRecipeDialog(context, t),
        child: const Icon(Icons.add),
      )
          : null,
      body: Column(
        children: [
          if (!isAdmin)
            SafeArea(
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: t.searchRecipes,
                          border: InputBorder.none,
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchText = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.tune),
                      onSelected: (value) {
                        setState(() {
                          sortBy = value;
                        });
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: "date",
                          child: Text(t.newest),
                        ),
                        PopupMenuItem(
                          value: "rating",
                          child: Text(t.topRated),
                        ),
                        PopupMenuItem(
                          value: "views",
                          child: Text(t.mostViewed),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<RecipeModel>>(
              stream: controller.getRecipesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<RecipeModel> recipes = snapshot.data!;
                if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
                  recipes = recipes
                      .where((r) => r.categoryId == widget.categoryId)
                      .toList();
                }

                recipes = recipes.where((r) {
                  final query = searchText.toLowerCase();

                  final title = r.title.toLowerCase();
                  final titleEn = r.titleEn?.toLowerCase() ?? "";
                  final titleAr = r.titleAr?.toLowerCase() ?? "";

                  final ingredientsEn = r.ingredientsEn ?? [];
                  final ingredientsAr = r.ingredientsAr ?? [];

                  return title.contains(query) ||
                      titleEn.contains(query) ||
                      titleAr.contains(query) ||
                      ingredientsEn.any((i) => i.toLowerCase().contains(query)) ||
                      ingredientsAr.any((i) => i.toLowerCase().contains(query));
                }).toList();

                if (!isAdmin) {
                  if (sortBy == "rating") {
                    recipes.sort((a, b) => b.rating.compareTo(a.rating));
                  } else if (sortBy == "views") {
                    recipes.sort((a, b) => b.views.compareTo(a.views));
                  }
                }

                return ListView.builder(
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        onTap: () async {
                          openCount++;

                          await controller.increaseViews(recipe.id!);

                          if (openCount % 3 == 0 && interstitialAd != null) {
                            final ad = interstitialAd;
                            interstitialAd = null;

                            ad!.fullScreenContentCallback = FullScreenContentCallback(
                              onAdDismissedFullScreenContent: (ad) {
                                ad.dispose();
                                loadInterstitialAd();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailView(recipe: recipe),
                                  ),
                                );
                              },
                              onAdFailedToShowFullScreenContent: (ad, error) {
                                ad.dispose();
                                loadInterstitialAd();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailView(recipe: recipe),
                                  ),
                                );
                              },
                            );

                            ad.show();
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailView(recipe: recipe),
                            ),
                          );
                        },
                        leading: recipe.imageUrl != null
                            ? Image.network(
                          recipe.imageUrl!,
                          width: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.fastfood),
                        title: Text(
                          _getTitle(context, recipe),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "${_getIngredients(context, recipe).length} ${t.ingredients}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                        trailing: isAdmin
                            ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == "edit") {
                              _showEditRecipeDialog(context, t, recipe);
                            }

                            if (value == "delete") {
                              controller.deleteRecipe(recipe.id!);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: "edit",
                              child: Text(t.editRecipe),
                            ),
                            PopupMenuItem(
                              value: "delete",
                              child: Text(t.delete),
                            ),
                          ],
                        )
                            : StatefulBuilder(
                          builder: (context, setStateLocal) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ...List.generate(5, (i) {
                                  final userId = UserSession.userId;
                                  final avgRating = recipe.rating;
                                  final isFilled = i < avgRating.round();

                                  return GestureDetector(
                                    onTap: () async {
                                      if (userId.isEmpty) return;

                                      final alreadyRated =
                                      recipe.userRatings.containsKey(userId);

                                      if (alreadyRated) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("You already rated this recipe"),
                                          ),
                                        );
                                        return;
                                      }

                                      await controller.rateRecipe(
                                        recipeId: recipe.id!,
                                        rating: (i + 1).toDouble(),
                                        userId: userId,
                                      );

                                      setState(() {});
                                    },
                                    child: Icon(
                                      Icons.star,
                                      size: 20,
                                      color: isFilled
                                          ? Colors.amber
                                          : Colors.grey.shade400,
                                    ),
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  recipe.rating.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "(${recipe.views})",
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: isAdLoaded && bannerAd != null
          ? SizedBox(
        width: bannerAd!.size.width.toDouble(),
        height: bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: bannerAd!),
      )
          : null,
    );
  }

  // ================= ADD RECIPE DIALOG =================
  void _showAddRecipeDialog(BuildContext context, AppLocalizations t) {
    final titleEnCtrl = TextEditingController();
    final titleArCtrl = TextEditingController();
    final videoUrlCtrl = TextEditingController();
    String? selectedCategoryId = widget.categoryId;

    List<String> ingredientsEn = [];
    List<String> ingredientsAr = [];
    bool isArabicIngredient = false;

    // Steps lists (supporting text + optional image per step)
    List<Map<String, dynamic>> stepsEn = [];
    List<Map<String, dynamic>> stepsAr = [];
    bool isArabicStep = false;
    final stepTextCtrl = TextEditingController();
    File? currentStepImage;

    File? image;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(t.addRecipe),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleEnCtrl,
                      decoration: const InputDecoration(labelText: "Title (EN)"),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleArCtrl,
                      decoration: const InputDecoration(labelText: "Title (AR)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: videoUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: "Video URL (YouTube / MP4)",
                        prefixIcon: Icon(Icons.video_library),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      hint: const Text("Select Category"),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat["id"],
                          child: Text(getCategoryName(cat["id"]!, t)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Ingredients Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Ingredients", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(isArabicIngredient ? "AR" : "EN"),
                            Switch(
                              value: isArabicIngredient,
                              onChanged: (value) {
                                setState(() {
                                  isArabicIngredient = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        ...ingredientsEn.map((e) => Chip(
                          label: Text(e),
                          onDeleted: () {
                            setState(() {
                              ingredientsEn.remove(e);
                            });
                          },
                        )),
                        ...ingredientsAr.map((e) => Chip(
                          label: Text(e),
                          onDeleted: () {
                            setState(() {
                              ingredientsAr.remove(e);
                            });
                          },
                        )),
                      ],
                    ),
                    TextField(
                      onSubmitted: (value) {
                        setState(() {
                          final text = value.trim();
                          if (text.isEmpty) return;

                          if (isArabicIngredient) {
                            ingredientsAr.add(text);
                          } else {
                            ingredientsEn.add(text);
                          }
                        });
                      },
                      decoration: InputDecoration(hintText: t.ingredients),
                    ),
                    const SizedBox(height: 20),

                    // Steps / Description Section with Images per step
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recipe Steps & Images", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(isArabicStep ? "AR" : "EN"),
                            Switch(
                              value: isArabicStep,
                              onChanged: (value) {
                                setState(() {
                                  isArabicStep = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Display current EN steps
                    ...stepsEn.asMap().entries.map((entry) => ListTile(
                      dense: true,
                      leading: Text("EN ${entry.key + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(entry.value['text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => setState(() => stepsEn.removeAt(entry.key)),
                      ),
                    )),
                    // Display current AR steps
                    ...stepsAr.asMap().entries.map((entry) => ListTile(
                      dense: true,
                      leading: Text("AR ${entry.key + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(entry.value['text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => setState(() => stepsAr.removeAt(entry.key)),
                      ),
                    )),
                    TextField(
                      controller: stepTextCtrl,
                      decoration: InputDecoration(
                        labelText: isArabicStep ? "أضف خطوة (AR)" : "Add Step Instruction (EN)",
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: Text(currentStepImage == null ? "Step Image" : "Image Selected"),
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setState(() => currentStepImage = File(picked.path));
                            }
                          },
                        ),
                        if (currentStepImage != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            onPressed: () => setState(() => currentStepImage = null),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final text = stepTextCtrl.text.trim();
                            if (text.isEmpty) return;

                            String? stepImgUrl;
                            if (currentStepImage != null) {
                              stepImgUrl = await controller.uploadToCloudinary(currentStepImage!);
                            }

                            setState(() {
                              final stepData = {'text': text, 'imageUrl': stepImgUrl};
                              if (isArabicStep) {
                                stepsAr.add(stepData);
                              } else {
                                stepsEn.add(stepData);
                              }
                              stepTextCtrl.clear();
                              currentStepImage = null;
                            });
                          },
                          child: const Text("Add Step"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Main Recipe Image
                    if (image != null) Image.file(image!, height: 100, fit: BoxFit.cover),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setState(() {
                            image = File(picked.path);
                          });
                        }
                      },
                      child: Text(t.pickImage),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  String? imageUrl;
                  if (image != null) {
                    imageUrl = await controller.uploadToCloudinary(image!);
                  }

                  await controller.addRecipe(
                    title: titleEnCtrl.text.trim().isNotEmpty ? titleEnCtrl.text.trim() : (titleArCtrl.text.trim()),
                    description: stepsEn.isNotEmpty ? stepsEn.first['text'] : '',
                    categoryId: selectedCategoryId ?? "",
                    imageUrl: imageUrl,
                    videoUrl: videoUrlCtrl.text.trim().isEmpty ? null : videoUrlCtrl.text.trim(),
                    titleEn: titleEnCtrl.text.trim(),
                    titleAr: titleArCtrl.text.trim(),
                    descriptionEn: stepsEn.isNotEmpty ? stepsEn.first['text'] : '',
                    descriptionAr: stepsAr.isNotEmpty ? stepsAr.first['text'] : '',
                    ingredientsEn: ingredientsEn,
                    ingredientsAr: ingredientsAr,
                    ingredients: ingredientsEn.isNotEmpty ? ingredientsEn : ingredientsAr,
                    stepsEn: stepsEn,
                    stepsAr: stepsAr,
                    steps: stepsEn.isNotEmpty ? stepsEn : stepsAr,
                  );

                  Navigator.pop(context);
                },
                child: Text(t.save),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= EDIT RECIPE DIALOG =================
  void _showEditRecipeDialog(
      BuildContext context,
      AppLocalizations t,
      RecipeModel recipe,
      ) {
    final titleEnCtrl = TextEditingController(text: recipe.titleEn ?? recipe.title);
    final titleArCtrl = TextEditingController(text: recipe.titleAr ?? "");
    final videoUrlCtrl = TextEditingController(text: recipe.videoUrl ?? "");

    String? selectedCategoryId = recipe.categoryId;

    List<String> ingredientsEn = List.from(recipe.ingredientsEn ?? recipe.ingredients);
    List<String> ingredientsAr = List.from(recipe.ingredientsAr ?? []);
    bool isArabicIngredient = false;

    // Steps lists initialized from existing recipe data
    List<Map<String, dynamic>> stepsEn = List.from(recipe.stepsEn ?? recipe.steps ?? []);
    List<Map<String, dynamic>> stepsAr = List.from(recipe.stepsAr ?? []);
    bool isArabicStep = false;
    final stepTextCtrl = TextEditingController();
    File? currentStepImage;

    File? image;
    String? imageUrl = recipe.imageUrl;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(t.editRecipe),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleEnCtrl,
                      decoration: const InputDecoration(labelText: "Title (EN)"),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleArCtrl,
                      decoration: const InputDecoration(labelText: "Title (AR)"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: videoUrlCtrl,
                      decoration: const InputDecoration(
                        labelText: "Video URL (YouTube / MP4)",
                        prefixIcon: Icon(Icons.video_library),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      hint: const Text("Select Category"),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat["id"],
                          child: Text(getCategoryName(cat["id"]!, t)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 15),

                    // Ingredients Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Ingredients", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(isArabicIngredient ? "AR" : "EN"),
                            Switch(
                              value: isArabicIngredient,
                              onChanged: (value) {
                                setState(() {
                                  isArabicIngredient = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 6,
                      children: [
                        ...ingredientsEn.map((e) => Chip(
                          label: Text(e),
                          onDeleted: () {
                            setState(() {
                              ingredientsEn.remove(e);
                            });
                          },
                        )),
                        ...ingredientsAr.map((e) => Chip(
                          label: Text(e),
                          onDeleted: () {
                            setState(() {
                              ingredientsAr.remove(e);
                            });
                          },
                        )),
                      ],
                    ),
                    TextField(
                      onSubmitted: (value) {
                        setState(() {
                          final text = value.trim();
                          if (text.isEmpty) return;

                          if (isArabicIngredient) {
                            ingredientsAr.add(text);
                          } else {
                            ingredientsEn.add(text);
                          }
                        });
                      },
                      decoration: InputDecoration(hintText: t.ingredients),
                    ),
                    const SizedBox(height: 20),

                    // Steps Section with Images per step
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Recipe Steps & Images", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            Text(isArabicStep ? "AR" : "EN"),
                            Switch(
                              value: isArabicStep,
                              onChanged: (value) {
                                setState(() {
                                  isArabicStep = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...stepsEn.asMap().entries.map((entry) => ListTile(
                      dense: true,
                      leading: Text("EN ${entry.key + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(entry.value['text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => setState(() => stepsEn.removeAt(entry.key)),
                      ),
                    )),
                    ...stepsAr.asMap().entries.map((entry) => ListTile(
                      dense: true,
                      leading: Text("AR ${entry.key + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
                      title: Text(entry.value['text'], maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () => setState(() => stepsAr.removeAt(entry.key)),
                      ),
                    )),
                    TextField(
                      controller: stepTextCtrl,
                      decoration: InputDecoration(
                        labelText: isArabicStep ? "أضف خطوة (AR)" : "Add Step Instruction (EN)",
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: Text(currentStepImage == null ? "Step Image" : "Image Selected"),
                          onPressed: () async {
                            final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (picked != null) {
                              setState(() => currentStepImage = File(picked.path));
                            }
                          },
                        ),
                        if (currentStepImage != null)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 18),
                            onPressed: () => setState(() => currentStepImage = null),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () async {
                            final text = stepTextCtrl.text.trim();
                            if (text.isEmpty) return;

                            String? stepImgUrl;
                            if (currentStepImage != null) {
                              stepImgUrl = await controller.uploadToCloudinary(currentStepImage!);
                            }

                            setState(() {
                              final stepData = {'text': text, 'imageUrl': stepImgUrl};
                              if (isArabicStep) {
                                stepsAr.add(stepData);
                              } else {
                                stepsEn.add(stepData);
                              }
                              stepTextCtrl.clear();
                              currentStepImage = null;
                            });
                          },
                          child: const Text("Add Step"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (image != null)
                      Image.file(image!, height: 100, fit: BoxFit.cover)
                    else if (imageUrl != null)
                      Image.network(imageUrl!, height: 100, fit: BoxFit.cover),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setState(() {
                            image = File(picked.path);
                          });
                        }
                      },
                      child: Text(t.pickImage),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(t.cancel),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    String? newImageUrl = imageUrl;
                    if (image != null) {
                      newImageUrl = await controller.uploadToCloudinary(image!);
                    }

                    final result = await controller.updateRecipe(
                      id: recipe.id!,
                      title: titleEnCtrl.text.trim().isNotEmpty ? titleEnCtrl.text.trim() : titleArCtrl.text.trim(),
                      description: stepsEn.isNotEmpty ? stepsEn.first['text'] : '',
                      categoryId: selectedCategoryId ?? "",
                      titleEn: titleEnCtrl.text.trim(),
                      titleAr: titleArCtrl.text.trim(),
                      descriptionEn: stepsEn.isNotEmpty ? stepsEn.first['text'] : '',
                      descriptionAr: stepsAr.isNotEmpty ? stepsAr.first['text'] : '',
                      ingredients: ingredientsEn.isNotEmpty ? ingredientsEn : ingredientsAr,
                      ingredientsEn: ingredientsEn,
                      ingredientsAr: ingredientsAr,
                      stepsEn: stepsEn,
                      stepsAr: stepsAr,
                      steps: stepsEn.isNotEmpty ? stepsEn : stepsAr,
                      imageUrl: newImageUrl,
                      videoUrl: videoUrlCtrl.text.trim().isEmpty
                          ? null
                          : videoUrlCtrl.text.trim(),
                    );

                    if (result != null) {
                      print("❌ UPDATE FAILED: $result");
                      return;
                    }

                    Navigator.pop(context);
                    setState(() {});
                  } catch (e) {
                    print("🔥 UPDATE ERROR: $e");
                  }
                },
                child: Text(t.update),
              ),
            ],
          );
        },
      ),
    );
  }

}
