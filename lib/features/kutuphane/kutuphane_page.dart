import 'package:flutter/material.dart';
import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/features/kutuphane/data/kutuphane_repository.dart';
import 'package:ezan_vakti_uygulamasi/core/utils/assets_constants.dart';
import 'package:ezan_vakti_uygulamasi/features/kutuphane/kutuphane_model.dart';
import 'package:ezan_vakti_uygulamasi/features/kutuphane/kutuphane_icerik_page.dart';

class KutuphanePage extends StatelessWidget {
  const KutuphanePage({super.key});

  @override
  Widget build(BuildContext context) {
    Color textColor = AppTheme.getTextColor(context);

    final repository = KutuphaneRepository();

    return Scaffold(
      backgroundColor: AppTheme.getBgColor(context),
      appBar: AppBar(
        title: Text("Kütüphane",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.getBgColor(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<LibraryNode>>(
          future: repository.getLibraryItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final kitaplar = snapshot.data!;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildSonOkunanKarti(context, textColor),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 15,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final kitap = kitaplar[index];
                        return InkWell(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      KutuphaneIcerikPage(node: kitap))),
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
            );
          }),
    );
  }

  Widget _buildSonOkunanKarti(BuildContext context, Color textColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
                    _buildIconBtn(context, Icons.menu_book, "Sureler"),
                    _buildIconBtn(context, Icons.bookmark, "Yer İmleri"),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconBtn(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: AppTheme.getSubTextColor(context))),
      ],
    );
  }
}


