import 'package:flutter/material.dart';
import '../../data/repositories/kutuphane_repository.dart';
import '../../utils/assets_constants.dart';
import 'kutuphane_model.dart';
import 'kutuphane_icerik_page.dart';

class KutuphanePage extends StatelessWidget {
  const KutuphanePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;

    final repository = KutuphaneRepository();
    final List<LibraryNode> kitaplar = repository.getLibraryItems();

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text("Kütüphane",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. ÜST KISIM: SON OKUNAN (Videodaki 00:02)
          SliverToBoxAdapter(
            child: _buildSonOkunanKarti(context, isDark, textColor),
          ),

          // 2. IZGARA: KİTAP KAPAKLARI (3 Sütun)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 20,
                crossAxisSpacing: 15,
                childAspectRatio: 0.65, // Dikey kitap formu
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final kitap = kitaplar[index];
                  return InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => KutuphaneIcerikPage(node: kitap))),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4))
                              ],
                              image: DecorationImage(
                                  image: AssetImage(kitap.imagePath),
                                  fit: BoxFit.cover),
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

  Widget _buildSonOkunanKarti(
      BuildContext context, bool isDark, Color textColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(Assets.fotografCamiteMa,
                width: 70, height: 100, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Son Okunan",
                    style: TextStyle(
                        color: textColor.withOpacity(0.5), fontSize: 12)),
                const SizedBox(height: 4),
                Text("Bakara Suresi\n17. Ayet",
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconBtn(Icons.menu_book, "Sureler", isDark),
                    _buildIconBtn(Icons.bookmark, "Yer İmleri", isDark),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.teal),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: isDark ? Colors.white70 : Colors.black54)),
      ],
    );
  }
}
