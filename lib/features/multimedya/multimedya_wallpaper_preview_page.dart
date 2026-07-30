import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:ezan_vakti_uygulamasi/core/widgets/glass_button.dart';
import 'package:ezan_vakti_uygulamasi/features/multimedya/multimedya_model.dart';

class WallpaperPreviewPage extends StatefulWidget {
  final MultimediaItem item;
  const WallpaperPreviewPage({super.key, required this.item});

  @override
  State<WallpaperPreviewPage> createState() => _WallpaperPreviewPageState();
}

class _WallpaperPreviewPageState extends State<WallpaperPreviewPage> {
  bool _isSetting = false;
  bool _isSharing = false;

  Future<void> _share() async {
    setState(() => _isSharing = true);
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/duvar_kagidi_${widget.item.id}.jpg';
      await Dio().download(widget.item.fullImageUrl, filePath);
      await SharePlus.instance
          .share(ShareParams(files: [XFile(filePath)]));
    } catch (e) {
      // Görsel indirilemedi (ör. internet yok) — en azından linki paylaşabilsin.
      await SharePlus.instance
          .share(ShareParams(text: widget.item.fullImageUrl));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _pickTargetAndSet() async {
    final target = await showModalBottomSheet<WallpaperTarget>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        Widget option(String label, IconData icon, WallpaperTarget target) {
          return ListTile(
            leading: Icon(icon, color: Colors.white),
            title: Text(label, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.of(context).pop(target),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text("Duvar Kağıdı Olarak Ayarla",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              option("Ana Ekran", Icons.home_rounded, WallpaperTarget.home),
              option("Kilit Ekranı", Icons.lock_rounded, WallpaperTarget.lock),
              option("Her İkisi", Icons.smartphone_rounded,
                  WallpaperTarget.both),
            ],
          ),
        );
      },
    );

    if (target == null || !mounted) return;
    setState(() => _isSetting = true);
    try {
      final result = await AsyncWallpaper.setWallpaper(
        WallpaperRequest(
          target: target,
          sourceType: WallpaperSourceType.url,
          source: widget.item.fullImageUrl,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isSuccess
              ? "Duvar kağıdı ayarlandı."
              : "Duvar kağıdı ayarlanamadı."),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Duvar kağıdı ayarlanırken hata oluştu.")),
      );
    } finally {
      if (mounted) setState(() => _isSetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.item.fullImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey.shade900),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      _isSharing
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : GlassButton(
                              icon: Icons.ios_share_rounded, onTap: _share),
                      if (Platform.isAndroid) ...[
                        const SizedBox(width: 10),
                        _isSetting
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                              )
                            : GlassButton(
                                icon: Icons.wallpaper_rounded,
                                onTap: _pickTargetAndSet,
                              ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
