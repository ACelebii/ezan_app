import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_model.dart';

class WallpaperTab extends StatelessWidget {
  final Map<String, List<MultimediaItem>> grouped;
  const WallpaperTab({super.key, required this.grouped});

  @override
  Widget build(BuildContext context) {
    if (grouped.isEmpty) {
      return Center(
        child: Text(
          "Bu bölümde henüz içerik yok.",
          style: TextStyle(color: AppTheme.getSubTextColor(context)),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: grouped.entries.map((entry) {
        return _WallpaperCategoryRow(category: entry.key, items: entry.value);
      }).toList(),
    );
  }
}

class _WallpaperCategoryRow extends StatelessWidget {
  final String category;
  final List<MultimediaItem> items;
  const _WallpaperCategoryRow({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    Color textColor = AppTheme.getTextColor(context);
    final tileWidth = MediaQuery.of(context).size.width * 0.42;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Text(
              category,
              style: TextStyle(
                  color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: tileWidth * 1.4,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () =>
                    context.push('/multimedya/wallpaper', extra: item),
                child: Container(
                  width: tileWidth,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade800,
                    image: item.imageUrl.isEmpty
                        ? null
                        : DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {},
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
