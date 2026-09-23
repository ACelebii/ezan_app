import '../../core/i18n/cevir.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/kuran_provider.dart';
import 'surah_detail_page.dart' show SearchBottomSheet;
import 'kuran_kayit_sayfalari.dart';
import '../../core/widgets/glass_button.dart';
import '../auth/auth_service.dart';

class KuranPage extends StatelessWidget {
  final VoidCallback? onBack;
  const KuranPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final auth = context.read<AuthService>();
        return KuranProvider(ingilizceMi: () => auth.uygulamaDili == 'English');
      },
      child: KuranView(onBack: onBack),
    );
  }
}

class KuranView extends StatelessWidget {
  final VoidCallback? onBack;
  const KuranView({super.key, this.onBack});

  void _showMainMenu(BuildContext context, KuranProvider provider) {
    final sayfa = context;
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
              title: Center(
                  child: Text(context.t("Menü"),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18))),
              trailing: const SizedBox(width: 24),
              onTap: () => Navigator.pop(context),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildMenuTile(Icons.menu_book, context.t("Sureler"), context,
                onTap: () => Navigator.pop(context)),
            _buildMenuTile(Icons.library_books, context.t("Cüzler"), context,
                onTap: () => Navigator.pop(context)),
            _buildMenuTile(Icons.list, context.t("Fihrist"), context,
                onTap: () => _ozellikAc(
                    sayfa, context, provider, KuranOzelligi.fihrist)),
            const Divider(color: Colors.white12, height: 24),
            _buildMenuTile(
                Icons.bookmark_border,
                context.t(provider.savedBookmarkTitle != null
                    ? "Yer İmi (${provider.savedBookmarkTitle})"
                    : "Yer İmi"),
                context, onTap: () async {
              Navigator.pop(context);
              bool success = await provider.goToBookmark();
              if (!context.mounted) return;
              if (success) {
                context.push('/kuran/surah-detail', extra: provider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        context.t("Kaydedilmiş bir yer imi bulunamadı."),
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFF2C2C2C),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }),
            _buildMenuTile(Icons.favorite_border, context.t("Favori"), context,
                onTap: () =>
                    _ozellikAc(sayfa, context, provider, KuranOzelligi.favori)),
            _buildMenuTile(Icons.edit_outlined, context.t("Not"), context,
                onTap: () =>
                    _ozellikAc(sayfa, context, provider, KuranOzelligi.not)),
            const Divider(color: Colors.white12, height: 24),
            _buildMenuTile(
                Icons.playlist_play, context.t("Okuma Listesi"), context,
                onTap: () => _ozellikAc(
                    sayfa, context, provider, KuranOzelligi.okumaListesi)),
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

  /// Menüyü kapatıp [ozellik]i açar ([sayfa]: menüyü açan sayfanın context'i).
  void _ozellikAc(BuildContext sayfa, BuildContext menu, KuranProvider provider,
      KuranOzelligi ozellik) {
    Navigator.pop(menu);
    kuranOzelligiAc(sayfa, provider, ozellik, detayAcik: false);
  }

  @override
  Widget build(BuildContext context) {
    context.dilIzle();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F4C3A),
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GlassButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconColor: Colors.white,
              size: 18,
              onTap: () {
                // GÜVENLİ ÇIKIŞ MANTIĞI (Crash Engelleyici)
                try {
                  final provider = context.read<KuranProvider>();
                  if (provider.isPlaying) {
                    provider.audioPlayer
                        .pause(); // Hata fırlatırsa yoksay (catch'e düşer)
                  }
                } catch (_) {
                  // Ses motoru kapanırken oluşabilecek her türlü ANR/Crash burada engellenir.
                }

                if (onBack != null) {
                  onBack!(); // Alt menüdeysek ana menüye dön
                } else {
                  if (context.canPop()) {
                    context.pop(); // Harici açılmışsa temizce kapat
                  } else {
                    context.go('/');
                  }
                }
              },
            ),
          ),
          title: Text(context.t("Kuran-ı Kerim"),
              style: const TextStyle(
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
          bottom: TabBar(
            indicatorColor: Colors.amber,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: [
              Tab(
                  icon: const Icon(Icons.menu_book),
                  text: context.t("SURELER")),
              Tab(
                  icon: const Icon(Icons.library_books),
                  text: context.t("CÜZLER")),
            ],
          ),
        ),
        body: Consumer<KuranProvider>(
          builder: (context, provider, child) {
            if (provider.isSurahListLoading || provider.isJuzListLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F4C3A)));
            }

            if (provider.errorMessage != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!context.mounted) return;
                final msg = provider.errorMessage;
                if (msg == null) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(context.t(msg)),
                    backgroundColor: Colors.redAccent));
                provider.clearError();
              });
            }

            return Column(
              children: [
                if (provider.savedBookmarkTitle != null)
                  GestureDetector(
                    onTap: () async {
                      bool success = await provider.goToBookmark();
                      if (!context.mounted) return;
                      if (success) {
                        context.push('/kuran/surah-detail', extra: provider);
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
                              color: Colors.black.withValues(alpha: 0.15),
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
                                Text(context.t("Kaldığım Yer"),
                                    style: const TextStyle(
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
                            title: Text(provider.sureAdi(surah),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87)),
                            subtitle: Text(
                                context.t("${surah.versesCount} Ayet"),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 20),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 150),
                                  () {
                                provider.loadSurahDetails(surah);
                              });

                              context.push('/kuran/surah-detail',
                                  extra: provider);
                            },
                          );
                        },
                      ),
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
                            title: Text(context.t("$juz. Cüz"),
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

                              context.push('/kuran/surah-detail',
                                  extra: provider);
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
