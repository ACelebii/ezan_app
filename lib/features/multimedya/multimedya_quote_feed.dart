import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_model.dart';

// Ayet ve Hadis sekmeleri aynı görsel yapıyı kullandığı için ortak widget.
class QuoteFeed extends StatelessWidget {
  final List<MultimediaItem> items;
  const QuoteFeed({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          "Bu bölümde henüz içerik yok.",
          style: TextStyle(color: AppTheme.getSubTextColor(context)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Kart yüksekliği ekranın tamamına değil, bu sekmeye ayrılan gerçek
        // alana göre hesaplanır — aksi halde başlık+sekme çubuğunun kapladığı
        // yükseklik yüzünden kart taşıp paylaş ikonu görünür alanın dışına düşer.
        final cardHeight = constraints.maxHeight * 0.88;
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _QuoteCard(item: items[index], height: cardHeight),
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final MultimediaItem item;
  final double height;
  const _QuoteCard({required this.item, required this.height});

  void _share() {
    final message = item.subtitle.isEmpty
        ? '"${item.text}"'
        : '"${item.text}"\n\n- ${item.subtitle}';
    SharePlus.instance.share(ShareParams(text: message));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade900,
        image: item.imageUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(item.imageUrl),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 76),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${item.text}"',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: IconButton(
                onPressed: _share,
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
