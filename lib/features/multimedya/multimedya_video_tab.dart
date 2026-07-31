import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_model.dart';

class VideoTab extends StatelessWidget {
  final Map<String, List<MultimediaItem>> grouped;
  const VideoTab({super.key, required this.grouped});

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
        return _CategoryRow(category: entry.key, items: entry.value);
      }).toList(),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String category;
  final List<MultimediaItem> items;
  const _CategoryRow({required this.category, required this.items});

  @override
  Widget build(BuildContext context) {
    Color textColor = AppTheme.getTextColor(context);
    final cardWidth = MediaQuery.of(context).size.width * 0.45;
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
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => context.push('/multimedya/video', extra: item),
                child: Container(
                  width: cardWidth,
                  margin: const EdgeInsets.only(right: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.grey.shade800,
                                image: item.displayThumbnail.isEmpty
                                    ? null
                                    : DecorationImage(
                                        image:
                                            NetworkImage(item.displayThumbnail),
                                        fit: BoxFit.cover,
                                        onError: (exception, stackTrace) =>
                                            debugPrint(
                                                "Kapak görseli yüklenemedi: $exception"),
                                      ),
                              ),
                            ),
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_fill,
                                    color: Colors.redAccent, size: 44),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
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
