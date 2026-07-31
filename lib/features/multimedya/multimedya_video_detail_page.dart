import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/core/widgets/glass_button.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_model.dart';

class VideoDetailPage extends StatelessWidget {
  final MultimediaItem item;
  const VideoDetailPage({super.key, required this.item});

  Future<void> _watchOnYoutube(BuildContext context) async {
    final url = Uri.tryParse(item.contentUrl);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video linki açılamadı.")),
      );
    }
  }

  void _share() {
    SharePlus.instance.share(ShareParams(text: item.contentUrl));
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppTheme.getBgColor(context);
    Color textColor = AppTheme.getTextColor(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: GlassButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade700,
                    backgroundImage: item.channelIconUrl.isEmpty
                        ? null
                        : NetworkImage(item.channelIconUrl),
                    child: item.channelIconUrl.isEmpty
                        ? const Icon(Icons.mosque, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        if (item.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                                color: AppTheme.getSubTextColor(context),
                                fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: GestureDetector(
                    onTap: () => _watchOnYoutube(context),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        image: item.displayThumbnail.isEmpty
                            ? null
                            : DecorationImage(
                                image: NetworkImage(item.displayThumbnail),
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) =>
                                    debugPrint("Kapak görseli yüklenemedi: $exception"),
                              ),
                      ),
                      child: const Center(
                        child: Icon(Icons.play_circle_fill,
                            color: Colors.redAccent, size: 64),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _share,
                      icon: const Icon(Icons.ios_share_rounded,
                          color: Colors.white),
                    ),
                    InkWell(
                      onTap: () => _watchOnYoutube(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("İzlemek için: ",
                                style: TextStyle(color: Colors.white70)),
                            SvgPicture.asset('assets/icons/youtube.svg',
                                width: 20, height: 20),
                            const SizedBox(width: 4),
                            const Text("YouTube",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
