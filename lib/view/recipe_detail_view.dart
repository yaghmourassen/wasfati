import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/recipe_controller.dart';
import '../core/user_session.dart';

import '../model/comment_model.dart';
import '../generated/l10n/app_localizations.dart';
import '../model/recipe_model.dart';

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

  // ============================================================
  // LANGUAGE
  // ============================================================

  String _getLang(BuildContext context) {
    return Localizations.localeOf(context).languageCode;
  }

  String _getTitle(BuildContext context) {
    final lang = _getLang(context);

    if (lang == 'ar' &&
        widget.recipe.titleAr != null &&
        widget.recipe.titleAr!.isNotEmpty) {
      return widget.recipe.titleAr!;
    }

    if (widget.recipe.titleEn != null &&
        widget.recipe.titleEn!.isNotEmpty) {
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

  List<dynamic> _getStepsList(BuildContext context) {
    final lang = _getLang(context);

    if (lang == 'ar' &&
        widget.recipe.stepsAr != null &&
        widget.recipe.stepsAr!.isNotEmpty) {
      return widget.recipe.stepsAr!;
    }

    if (widget.recipe.stepsEn != null &&
        widget.recipe.stepsEn!.isNotEmpty) {
      return widget.recipe.stepsEn!;
    }

    if (widget.recipe.steps != null &&
        widget.recipe.steps!.isNotEmpty) {
      return widget.recipe.steps!;
    }

    return [];
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final title = _getTitle(context);
    final description = _getDescription(context);
    final ingredients = _getIngredients(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ======================================================
          // HERO
          // ======================================================

          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildFavoriteButton(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.recipe.imageUrl != null &&
                      widget.recipe.imageUrl!.isNotEmpty)
                    Image.network(
                      widget.recipe.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return _buildHeroPlaceholder();
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildHeroPlaceholder(),
                            const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    _buildHeroPlaceholder(),

                  // Dark gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black12,
                          Colors.black26,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),

                  // Bottom accent
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 100,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black54,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ======================================================
          // CONTENT
          // ======================================================

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // TITLE + META
                  // =================================================

                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildRecipeMeta(context),

                  const SizedBox(height: 24),

                  // =================================================
                  // DESCRIPTION
                  // =================================================

                  if (description.trim().isNotEmpty)
                    _buildDescriptionCard(
                      context,
                      description,
                    ),

                  if (description.trim().isNotEmpty)
                    const SizedBox(height: 24),

                  // =================================================
                  // INGREDIENTS
                  // =================================================

                  _buildSectionHeader(
                    context,
                    icon: Icons.restaurant_menu_rounded,
                    title: t.ingredients,
                  ),

                  const SizedBox(height: 12),

                  if (ingredients.isEmpty)
                    _buildEmptySection(
                      context,
                      icon: Icons.shopping_basket_outlined,
                      text: "No ingredients available",
                    )
                  else
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: ingredients.map((item) {
                        return _buildIngredientChip(
                          context,
                          item,
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 30),

                  // =================================================
                  // STEPS
                  // =================================================

                  _buildSectionHeader(
                    context,
                    icon: Icons.menu_book_rounded,
                    title: t.howToPrepare,
                  ),

                  const SizedBox(height: 14),

                  _buildSteps(
                    context,
                    description,
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // VIDEO
                  // =================================================

                  if (widget.recipe.videoUrl != null &&
                      widget.recipe.videoUrl!.isNotEmpty) ...[
                    _buildVideoCard(context, t),
                    const SizedBox(height: 30),
                  ],

                  // =================================================
                  // COMMENTS
                  // =================================================

                  _buildSectionHeader(
                    context,
                    icon: Icons.forum_outlined,
                    title: t.comments,
                  ),

                  const SizedBox(height: 14),

                  _buildComments(context, t),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO PLACEHOLDER
  // ============================================================

  Widget _buildHeroPlaceholder() {
    return Container(
      color: Colors.green.shade700,
      child: const Center(
        child: Icon(
          Icons.restaurant_rounded,
          color: Colors.white54,
          size: 70,
        ),
      ),
    );
  }

  // ============================================================
  // FAVORITE BUTTON
  // ============================================================

  Widget _buildFavoriteButton() {
    return StreamBuilder<bool>(
      stream: _recipeController.isFavorite(
        UserSession.userId,
        widget.recipe.id!,
      ),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;

        return Material(
          color: Colors.black45,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () async {
              if (UserSession.userId.isEmpty) return;

              await _recipeController.toggleFavorite(
                userId: UserSession.userId,
                recipeId: widget.recipe.id!,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey(isFav),
                  color: isFav ? Colors.redAccent : Colors.white,
                  size: 25,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // META
  // ============================================================

  Widget _buildRecipeMeta(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildMetaItem(
            context,
            icon: Icons.star_rounded,
            value: widget.recipe.rating.toStringAsFixed(1),
            label: "Rating",
            iconColor: Colors.amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetaItem(
            context,
            icon: Icons.visibility_rounded,
            value: "${widget.recipe.views}",
            label: "Views",
            iconColor: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetaItem(
            context,
            icon: Icons.restaurant_rounded,
            value: "${_getIngredients(context).length}",
            label: "Items",
            iconColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetaItem(
      BuildContext context, {
        required IconData icon,
        required String value,
        required String label,
        required Color iconColor,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescriptionCard(
      BuildContext context,
      String description,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withOpacity(.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
      BuildContext context, {
        required IconData icon,
        required String title,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INGREDIENT CHIP
  // ============================================================

  Widget _buildIngredientChip(
      BuildContext context,
      String text,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withOpacity(.13),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 17,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEPS
  // ============================================================

  Widget _buildSteps(
      BuildContext context,
      String fallbackDescription,
      ) {
    final stepsList = _getStepsList(context);
    final colorScheme = Theme.of(context).colorScheme;

    // Legacy description fallback
    if (stepsList.isEmpty) {
      final steps = fallbackDescription
          .split(RegExp(r'\n|\d+\.\s'))
          .where((e) => e.trim().isNotEmpty)
          .toList();

      if (steps.isEmpty) {
        return _buildEmptySection(
          context,
          icon: Icons.menu_book_outlined,
          text: "No preparation steps available",
        );
      }

      return Column(
        children: List.generate(
          steps.length,
              (index) {
            return _buildStepCard(
              context,
              index: index,
              text: steps[index].trim(),
              imageUrl: null,
              isLast: index == steps.length - 1,
            );
          },
        ),
      );
    }

    return Column(
      children: List.generate(
        stepsList.length,
            (index) {
          final item = stepsList[index];

          final String stepText =
          item is Map ? (item['text'] ?? '').toString() : item.toString();

          final String? stepImage =
          item is Map && item['imageUrl'] != null
              ? item['imageUrl'].toString()
              : null;

          return _buildStepCard(
            context,
            index: index,
            text: stepText,
            imageUrl: stepImage,
            isLast: index == stepsList.length - 1,
          );
        },
      ),
    );
  }

  Widget _buildStepCard(
      BuildContext context, {
        required int index,
        required String text,
        required String? imageUrl,
        required bool isLast,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 85,
                    margin: const EdgeInsets.only(top: 5),
                    color: colorScheme.primary.withOpacity(.18),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Step card
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(.10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.035),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Step ${index + 1}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (
                              context,
                              child,
                              loadingProgress,
                              ) {
                            if (loadingProgress == null) {
                              return child;
                            }

                            return Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: colorScheme.onSurfaceVariant,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VIDEO CARD
  // ============================================================

  Widget _buildVideoCard(
      BuildContext context,
      AppLocalizations t,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final Uri url = Uri.parse(widget.recipe.videoUrl!);

          if (await canLaunchUrl(url)) {
            await launchUrl(
              url,
              mode: LaunchMode.externalApplication,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.error),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(.78),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(.20),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.watchVideo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Watch the preparation video",
                      style: TextStyle(
                        color: Colors.white.withOpacity(.82),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Widget _buildComments(
      BuildContext context,
      AppLocalizations t,
      ) {
    return StreamBuilder<List<CommentModel>>(
      stream: _recipeController.getCommentsStream(
        widget.recipe.id!,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final comments = snapshot.data!;
        final currentUserId = UserSession.userId;

        CommentModel? myComment;

        try {
          myComment = comments.firstWhere(
                (c) => c.userId == currentUserId,
          );
        } catch (_) {
          myComment = null;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentUserId.isNotEmpty)
              _buildCommentInput(
                context,
                t,
                myComment,
                currentUserId,
              ),

            if (currentUserId.isNotEmpty)
              const SizedBox(height: 18),

            if (comments.isEmpty)
              _buildEmptyComments(context, t)
            else
              Column(
                children: comments.map((comment) {
                  final isMe = comment.userId == currentUserId;

                  return _buildCommentCard(
                    context,
                    comment,
                    isMe,
                    currentUserId,
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInput(
      BuildContext context,
      AppLocalizations t,
      CommentModel? myComment,
      String currentUserId,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 7, 7),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withOpacity(.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: myComment == null
                    ? t.writeComment
                    : "Update your comment...",
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Material(
            color: colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                final text = _commentController.text.trim();

                if (text.isEmpty || widget.recipe.id == null) {
                  return;
                }

                await _recipeController.saveOrUpdateComment(
                  recipeId: widget.recipe.id!,
                  userId: currentUserId,
                  text: text,
                );

                _commentController.clear();

                FocusScope.of(context).unfocus();

                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Icon(
                  myComment == null
                      ? Icons.send_rounded
                      : Icons.check_rounded,
                  color: colorScheme.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(
      BuildContext context,
      CommentModel comment,
      bool isMe,
      String currentUserId,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: colorScheme.outline.withOpacity(.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: colorScheme.primary.withOpacity(.10),
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isMe)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        onSelected: (value) async {
                          if (value == "edit") {
                            _commentController.text = comment.text;

                            FocusScope.of(context).requestFocus(
                              FocusNode(),
                            );
                          }

                          if (value == "delete") {
                            await _recipeController.deleteComment(
                              recipeId: widget.recipe.id!,
                              userId: currentUserId,
                            );

                            setState(() {});
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: "edit",
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text("Edit"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: "delete",
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text("Delete"),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  comment.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATES
  // ============================================================

  Widget _buildEmptyComments(
      BuildContext context,
      AppLocalizations t,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 28,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withOpacity(.10),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 38,
            color: colorScheme.onSurfaceVariant.withOpacity(.5),
          ),
          const SizedBox(height: 10),
          Text(
            t.noComments,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(
      BuildContext context, {
        required IconData icon,
        required String text,
      }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(.10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant.withOpacity(.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}