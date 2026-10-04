import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/recipe_controller.dart';
import '../core/user_session.dart';
import '../model/recipe_model.dart';
import '../model/comment_model.dart';
import '../generated/l10n/app_localizations.dart';

class RecipeDetailView extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailView({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailView> createState() => _RecipeDetailViewState();
}

class _RecipeDetailViewState extends State<RecipeDetailView> {
  final TextEditingController _commentController = TextEditingController();
  final RecipeController _recipeController = RecipeController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 🌍 SIMPLE L18N RESOLVER (uses existing system)
  String _getLang(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  String _getTitle(BuildContext context) {
    final lang = _getLang(context);

    if (lang == 'ar' && widget.recipe.titleAr != null && widget.recipe.titleAr!.isNotEmpty) {
      return widget.recipe.titleAr!;
    }

    if (widget.recipe.titleEn != null && widget.recipe.titleEn!.isNotEmpty) {
      return widget.recipe.titleEn!;
    }

    return widget.recipe.title;
  }

  String _getDescription(BuildContext context) {
    final lang = _getLang(context);

    if (lang == 'ar' &&
        widget.recipe.descriptionAr != null &&
        widget.recipe.descriptionAr!.isNotEmpty) {
      return widget.recipe.descriptionAr!;
    }

    if (widget.recipe.descriptionEn != null &&
        widget.recipe.descriptionEn!.isNotEmpty) {
      return widget.recipe.descriptionEn!;
    }

    return widget.recipe.description;
  }

  List<String> _getIngredients(BuildContext context) {
    final lang = _getLang(context);

    if (lang == 'ar' &&
        widget.recipe.ingredientsAr != null &&
        widget.recipe.ingredientsAr!.isNotEmpty) {
      return widget.recipe.ingredientsAr!;
    }

    if (widget.recipe.ingredientsEn != null &&
        widget.recipe.ingredientsEn!.isNotEmpty) {
      return widget.recipe.ingredientsEn!;
    }

    return widget.recipe.ingredients;
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
                stream: _recipeController
                    .isFavorite(UserSession.userId, widget.recipe.id!),
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

                      await _recipeController.toggleFavorite(
                        userId: UserSession.userId,
                        recipeId: widget.recipe.id!,
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
                  widget.recipe.imageUrl != null
                      ? Image.network(
                    widget.recipe.imageUrl!,
                    fit: BoxFit.cover,
                  )
                      : Container(color: Colors.grey),

                  // 🌑 Gradient overlay
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
                        Theme.of(context).colorScheme.surfaceContainerHighest,
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

                  const SizedBox(height: 20),

                  // ================= WATCH VIDEO SECTION (UPDATED WITH L10N) =================
                  if (widget.recipe.videoUrl != null && widget.recipe.videoUrl!.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse(widget.recipe.videoUrl!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.error)),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                        label: Text(
                          t.watchVideo, // 👈 Utilisation de la traduction dynamique
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],

                  // ================= COMMENTS SECTION =================
                  Text(
                    t.comments,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 💬 Dynamic Comments List StreamBuilder
                  StreamBuilder<List<CommentModel>>(
                    stream: _recipeController.getCommentsStream(widget.recipe.id!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final comments = snapshot.data!;
                      final currentUserId = UserSession.userId;

                      // Check if current user already commented
                      CommentModel? myComment;
                      try {
                        myComment = comments.firstWhere((c) => c.userId == currentUserId);
                      } catch (_) {
                        myComment = null;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📝 Add / Update Comment Input Field
                          if (currentUserId.isNotEmpty) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _commentController,
                                    decoration: InputDecoration(
                                      hintText: myComment == null ? t.writeComment : "Update your comment...",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () async {
                                    final text = _commentController.text.trim();
                                    if (text.isEmpty || widget.recipe.id == null) return;

                                    // 🚀 Uses saveOrUpdateComment to enforce 1 comment per user
                                    await _recipeController.saveOrUpdateComment(
                                      recipeId: widget.recipe.id!,
                                      userId: currentUserId,
                                      text: text,
                                    );

                                    _commentController.clear();
                                    FocusScope.of(context).unfocus();
                                    setState(() {});
                                  },
                                  icon: Icon(myComment == null ? Icons.send : Icons.check),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (comments.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                t.noComments,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                final comment = comments[index];
                                final isMe = comment.userId == currentUserId;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(comment.userName),
                                  subtitle: Text(comment.text),
                                  // 🛠 Edit & Delete options visible ONLY for the comment owner
                                  trailing: isMe
                                      ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                                        onPressed: () {
                                          _commentController.text = comment.text;
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () async {
                                          await _recipeController.deleteComment(
                                            recipeId: widget.recipe.id!,
                                            userId: currentUserId,
                                          );
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  )
                                      : null,
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),

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
