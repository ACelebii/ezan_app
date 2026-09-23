import '../../core/i18n/cevir.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/features/kutuphane/providers/kutuphane_provider.dart';
import 'kutuphane_model.dart';
import 'kutuphane_pdf_page.dart';

class KutuphanePage extends StatelessWidget {
  const KutuphanePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KutuphaneProvider(),
      child: const _KutuphanePageContent(),
    );
  }
}

class _KutuphanePageContent extends StatefulWidget {
  const _KutuphanePageContent();

  @override
  State<_KutuphanePageContent> createState() => _KutuphanePageContentState();
}

class _KutuphanePageContentState extends State<_KutuphanePageContent> {
  ({LibraryNode item, int page})? _sonOkunan;

  @override
  void initState() {
    super.initState();
    _sonOkunaniYukle();
  }

  Future<void> _sonOkunaniYukle() async {
    final data = await KutuphaneSonOkunan.load();
    if (mounted) setState(() => _sonOkunan = data);
  }

  Future<void> _openItem(LibraryNode kitap) async {
    await context.push(kitap.isKitap ? '/kutuphane/pdf' : '/kutuphane/icerik',
        extra: kitap);
    // Bir PDF okunmuş olabileceğinden, dönüşte "Son Okunan" kartını
    // güncel tut.
    _sonOkunaniYukle();
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = AppTheme.getTextColor(context);
    final provider = context.watch<KutuphaneProvider>();

    if (provider.isLoading) {
      return Scaffold(
          backgroundColor: AppTheme.getBgColor(context),
          body: const Center(child: CircularProgressIndicator()));
    }

    final kitaplar = provider.items;

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      appBar: AppBar(
        title: Text(context.t("Kütüphane"),
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.getBgColor(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildSonOkunanKarti(context, textColor),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 15,
                childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final kitap = kitaplar[index];
                  return InkWell(
                    onTap: () => _openItem(kitap),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade300,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4))
                              ],
                              image: kitap.imageUrl.isEmpty
                                  ? null
                                  : DecorationImage(
                                      image: NetworkImage(kitap.imageUrl),
                                      fit: BoxFit.cover,
                                      onError: (exception, stackTrace) {},
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(kitap.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
                childCount: kitaplar.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSonOkunanKarti(BuildContext context, Color textColor) {
    final sonOkunan = _sonOkunan;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: sonOkunan == null ? null : () => _openItem(sonOkunan.item),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: sonOkunan != null && sonOkunan.item.imageUrl.isNotEmpty
                  ? Image.network(sonOkunan.item.imageUrl,
                      width: 70,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                          width: 70,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.menu_book_rounded)))
                  : Container(
                      width: 70,
                      height: 100,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.menu_book_rounded)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t("Son Okunan"),
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                      sonOkunan != null
                          ? context.t("${sonOkunan.item.title}\n${sonOkunan.page}. Sayfa")
                          : context.t("Henüz bir kitap okumadınız."),
                      style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconBtn(context, Icons.menu_book, "Sureler"),
                      _buildIconBtn(context, Icons.bookmark, "Yer İmleri"),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t("$label özelliği yakında eklenecek.")),
        duration: const Duration(seconds: 2),
      )),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.getSubTextColor(context))),
        ],
      ),
    );
  }
}
