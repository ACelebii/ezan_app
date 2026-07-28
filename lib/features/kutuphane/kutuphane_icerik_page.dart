import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'data/kutuphane_repository.dart'; // import yolu düzeltildi
import 'kutuphane_model.dart';

class KutuphaneIcerikPage extends StatelessWidget {
  final LibraryNode node;
  const KutuphaneIcerikPage({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;

    // Veritabanı bağlantımızı alıyoruz
    final repository = GetIt.instance<KutuphaneRepository>();

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
            onPressed: () => context.pop()),
      ),
      body: node.isArticle
          ? _buildOkumaEkrani(textColor, repository)
          : _buildListeEkrani(isDark, textColor, repository),
    );
  }

  // 1. LİSTE EKRANI
  Widget _buildListeEkrani(
      bool isDark, Color textColor, KutuphaneRepository repository) {
    return FutureBuilder<List<LibraryNode>>(
      future: repository.getAltKategoriler(node.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text("Bu kategoriye ait içerik henüz eklenmemiş."));
        }

        final altKategoriler = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: altKategoriler.length,
          itemBuilder: (context, index) {
            final item = altKategoriler[index];
            return InkWell(
              onTap: () => context.push('/kutuphane/icerik', extra: item),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                      image: AssetImage(item.imagePath),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) =>
                          const Icon(Icons.image_not_supported)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7)
                      ],
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
      },
    );
  }

  // 2. OKUMA EKRANI
  Widget _buildOkumaEkrani(Color textColor, KutuphaneRepository repository) {
    return FutureBuilder<String>(
      future: repository.getMakaleIcerigi(node.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        final metin = snapshot.data ?? "İçerik yüklenemedi.";

        return SingleChildScrollView(
          child: Column(
            children: [
              Image.asset(node.imagePath,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                      color: Colors.grey,
                      height: 250,
                      child: const Center(child: Icon(Icons.image)))),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  metin,
                  style: TextStyle(color: textColor, fontSize: 17, height: 1.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
