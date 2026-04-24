import 'package:flutter/material.dart';
import 'kutuphane_model.dart';

class KutuphaneIcerikPage extends StatelessWidget {
  final LibraryNode node;
  const KutuphaneIcerikPage({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF2F2F7),
      appBar: AppBar(
        title:
            Text(node.title, style: TextStyle(color: textColor, fontSize: 16)),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: textColor,
            onPressed: () => Navigator.pop(context)),
      ),
      body: node.isArticle
          ? _buildOkumaEkrani(textColor)
          : _buildListeEkrani(isDark, textColor),
    );
  }

  // 1. LİSTE EKRANI (Büyük resimli kartlar - Videodaki 00:05 ve 00:08)
  Widget _buildListeEkrani(bool isDark, Color textColor) {
    if (node.children == null)
      return const Center(child: Text("İçerik bulunamadı."));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: node.children!.length,
      itemBuilder: (context, index) {
        final item = node.children![index];
        return InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => KutuphaneIcerikPage(node: item))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                  image: AssetImage(item.imagePath), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Text(item.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  // 2. OKUMA EKRANI (Resim + Metin - Videodaki 00:14)
  Widget _buildOkumaEkrani(Color textColor) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Image.asset(node.imagePath,
              width: double.infinity, height: 250, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              node.content!,
              style: TextStyle(color: textColor, fontSize: 17, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}
