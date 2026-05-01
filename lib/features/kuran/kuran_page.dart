import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/kuran_provider.dart';
import 'surah_detail_page.dart';
import '../vakitler/vakitler_page.dart';
import '../main/main_navigation_page.dart';

// PROVIDER SARMALAYICISI: ProviderNotFound hatasını çözer
class KuranPage extends StatelessWidget {
  const KuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KuranProvider(),
      child: const KuranView(),
    );
  }
}

class KuranView extends StatelessWidget {
  const KuranView({super.key});

  void _showMainMenu(BuildContext context, KuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF202020),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.white),
              title: const Center(
                  child: Text("Menü",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18))),
              trailing: const SizedBox(width: 24),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildMenuTile(Icons.menu_book, "Sureler", context,
                onTap: () => Navigator.pop(context)),
            _buildMenuTile(Icons.library_books, "Cüzler", context,
                onTap: () => Navigator.pop(context)),
            _buildMenuTile(Icons.list, "Fihrist", context),
            const Divider(color: Colors.white12, height: 24),
            _buildMenuTile(
                Icons.bookmark_border,
                provider.savedBookmarkTitle != null
                    ? "Yer İmi (${provider.savedBookmarkTitle})"
                    : "Yer İmi",
                context, onTap: () async {
              Navigator.pop(context);
              bool success = await provider.goToBookmark();
              if (success) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                            value: provider, child: const SurahDetailPage())));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Kaydedilmiş bir yer imi bulunamadı.",
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Color(0xFF2C2C2C),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }),
            _buildMenuTile(Icons.favorite_border, "Favori", context),
            _buildMenuTile(Icons.edit_outlined, "Not", context),
            const Divider(color: Colors.white12, height: 24),
            _buildMenuTile(Icons.playlist_play, "Okuma Listesi", context),
          ],
        );
      },
    );
  }

  Widget _buildMenuTile(IconData icon, String title, BuildContext context,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F4C3A),
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () {
              // Alt menülerin olduğu EN ANA SAYFAYA yönlendiriyoruz.
              // DİKKAT: Aşağıdaki "MainPage()" kısmını, uygulamanın alt butonlarını (BottomNavigationBar)
              // içeren sınıfın adı neyse (Örn: AnaEkran, Dashboard, Home vb.) onunla değiştir!

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const MainNavigationPage()), // Burayı kendi ana sayfanla değiştir
                (route) => false,
              );
            },
          ),
          title: const Text("Kuran-ı Kerim",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                final provider =
                    Provider.of<KuranProvider>(context, listen: false);
                showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF2C2C2C),
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (context) => SearchBottomSheet(
                        provider: provider, isFromMainPage: true));
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _showMainMenu(
                  context, Provider.of<KuranProvider>(context, listen: false)),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.amber,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(icon: Icon(Icons.menu_book), text: "SURELER"),
              Tab(icon: Icon(Icons.library_books), text: "CÜZLER"),
            ],
          ),
        ),
        body: Consumer<KuranProvider>(
          builder: (context, provider, child) {
            if (provider.isSurahListLoading || provider.isJuzListLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F4C3A)));
            }

            return Column(
              children: [
                // KALDIGIM YER (YER İMİ) KARTI
                if (provider.savedBookmarkTitle != null)
                  GestureDetector(
                    onTap: () async {
                      bool success = await provider.goToBookmark();
                      if (success) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider.value(
                                    value: provider,
                                    child: const SurahDetailPage())));
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B3B24), Color(0xFF2A5936)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded,
                              color: Colors.white70, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Kaldığım Yer",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(provider.savedBookmarkTitle!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_fill_rounded,
                              color: Colors.amber, size: 36),
                        ],
                      ),
                    ),
                  ),

                Expanded(
                  child: TabBarView(
                    children: [
                      // SURELER LİSTESİ
                      ListView.separated(
                        itemCount: provider.surahs.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final surah = provider.surahs[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF8BA59B), width: 1),
                              ),
                              child: Text("${surah.id}",
                                  style: const TextStyle(
                                      color: Color(0xFF0F4C3A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            title: Text(surah.nameSimple,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87)),
                            subtitle: Text("${surah.versesCount} Ayet",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 20),
                            onTap: () {
                              // ANİMASYON KURTARICISI: Arayüz kasmasın diye gecikmeli yükleme
                              Future.delayed(const Duration(milliseconds: 150),
                                  () {
                                provider.loadSurahDetails(surah);
                              });

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ChangeNotifierProvider.value(
                                              value: provider,
                                              child: const SurahDetailPage())));
                            },
                          );
                        },
                      ),

                      // CÜZLER LİSTESİ
                      ListView.separated(
                        itemCount: provider.juzs.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Colors.black12),
                        itemBuilder: (context, index) {
                          final juz = provider.juzs[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF8BA59B), width: 1),
                              ),
                              child: Text("$juz",
                                  style: const TextStyle(
                                      color: Color(0xFF0F4C3A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                            title: Text("$juz. Cüz",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 20),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 150),
                                  () {
                                provider.loadJuzDetails(juz);
                              });

                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ChangeNotifierProvider.value(
                                              value: provider,
                                              child: const SurahDetailPage())));
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
