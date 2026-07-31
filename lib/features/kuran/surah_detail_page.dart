import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/kuran_provider.dart';
import 'kuran_models.dart';
import 'kuran_download_service.dart';
import '../auth/auth_service.dart';
import '../../core/widgets/glass_button.dart';

class SearchBottomSheet extends StatefulWidget {
  final KuranProvider provider;
  final bool isFromMainPage;
  const SearchBottomSheet(
      {super.key, required this.provider, this.isFromMainPage = false});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  int selectedTab = 2;
  String query = "";
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> getFilteredItems() {
    if (selectedTab == 2) {
      if (query.isEmpty) return widget.provider.surahs;
      return widget.provider.surahs
          .where((s) =>
              s.nameSimple.toLowerCase().contains(query.toLowerCase()) ||
              s.id.toString().contains(query))
          .toList();
    } else if (selectedTab == 1) {
      List<int> allJuzs = List.generate(30, (i) => i + 1);
      if (query.isEmpty) return allJuzs;
      return allJuzs.where((j) => j.toString().contains(query)).toList();
    } else if (selectedTab == 0) {
      List<int> allPages = List.generate(604, (i) => i + 1);
      if (query.isEmpty) return allPages;
      return allPages.where((p) => p.toString().contains(query)).toList();
    } else if (selectedTab == 3) {
      // Meal (çeviri) araması yalnızca o an açık olan sure/cüz/sayfanın
      // ayetleri içinde çalışır; Kuran ana sayfasından açıldığında henüz
      // yüklü ayet olmadığından boş liste döner.
      if (query.isEmpty) return widget.provider.currentAyahs;
      return widget.provider.currentAyahs
          .where((a) =>
              a.translation.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    return [];
  }

  void _onItemTapped(dynamic item) {
    if (selectedTab == 2) {
      widget.provider.loadSurahDetails(item as SurahModel);
    } else if (selectedTab == 1) {
      widget.provider.loadJuzDetails(item as int);
    } else if (selectedTab == 0) {
      widget.provider.loadPageDetails(item as int);
    } else if (selectedTab == 3) {
      final ayah = item as AyahModel;
      final index = widget.provider.currentAyahs.indexOf(ayah);
      if (index != -1) widget.provider.playSingleAyah(index);
    }

    Navigator.of(context).pop();

    if (widget.isFromMainPage && selectedTab != 3) {
      context.push('/kuran/surah-detail', extra: widget.provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> items = getFilteredItems();

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 500,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSearchTab("Sayfa", 0),
                _buildSearchTab("Cüz", 1),
                _buildSearchTab("Sure", 2),
                _buildSearchTab("Meal", 3),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => query = val),
                decoration: InputDecoration(
                  hintText: "Ara (İsim veya Numara)",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white12,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => query = "");
                      }),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Expanded(
              child: selectedTab == 3 && items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.provider.currentAyahs.isEmpty
                              ? "Meal araması için önce bir sure, cüz veya sayfa açın."
                              : "Sonuç bulunamadı.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        String title = "";
                        if (selectedTab == 2) {
                          title =
                              "${(item as SurahModel).id}. ${item.nameSimple}";
                        } else if (selectedTab == 1) {
                          title = "$item. Cüz";
                        } else if (selectedTab == 0) {
                          title = "$item. Sayfa";
                        } else if (selectedTab == 3) {
                          final ayah = item as AyahModel;
                          title = "${ayah.verseKey}  ${ayah.translation}";
                        }

                        return ListTile(
                          title: Text(title,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: selectedTab == 3
                                  ? TextAlign.left
                                  : TextAlign.center,
                              maxLines: selectedTab == 3 ? 2 : 1,
                              overflow: selectedTab == 3
                                  ? TextOverflow.ellipsis
                                  : TextOverflow.clip),
                          onTap: () => _onItemTapped(item),
                        );
                      }),
            ),
            Container(
              width: double.infinity,
              height: 60,
              color: Colors.black,
              child: TextButton(
                  onPressed: () {
                    if (items.isNotEmpty) _onItemTapped(items.first);
                  },
                  child: const Text("Git!",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab(String text, int index) {
    bool isActive = index == selectedTab;
    return GestureDetector(
      onTap: () => setState(() {
        selectedTab = index;
        query = "";
        _searchController.clear();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: isActive ? Colors.grey.shade700 : Colors.transparent,
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(color: isActive ? Colors.white : Colors.white54)),
      ),
    );
  }
}

class SurahDetailPage extends StatelessWidget {
  const SurahDetailPage({super.key});

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
            _buildMenuTile(Icons.menu_book, "Sureler", context, onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            }),
            _buildMenuTile(Icons.library_books, "Cüzler", context, onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            }),
            _buildMenuTile(Icons.list, "Fihrist", context,
                onTap: () => _showComingSoon(context, "Fihrist")),
            const Divider(color: Colors.white12, height: 24),
            _buildMenuTile(
                Icons.bookmark_border,
                provider.savedBookmarkTitle != null
                    ? "Yer İmi (${provider.savedBookmarkTitle})"
                    : "Yer İmi",
                context, onTap: () async {
              Navigator.pop(context);
              bool success = await provider.goToBookmark();
              if (!context.mounted) return;
              if (!success) {
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
            _buildMenuTile(Icons.favorite_border, "Favori", context,
                onTap: () => _showComingSoon(context, "Favori")),
            _buildMenuTile(Icons.edit_outlined, "Not", context,
                onTap: () => _showComingSoon(context, "Not")),
            const Divider(color: Colors.white12, height: 24),
            _buildMenuTile(Icons.playlist_play, "Okuma Listesi", context,
                onTap: () => _showComingSoon(context, "Okuma Listesi")),
            _buildMenuTile(Icons.replay, "Ezberleme", context,
                onTap: () => _showComingSoon(context, "Ezberleme")),
            const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text("Ayarlar",
                    style: TextStyle(color: Colors.grey, fontSize: 13))),
            _buildMenuTile(Icons.settings, "Ayarlar", context, onTap: () {
              Navigator.pop(context);
              _showCombinedSettings(context, provider);
            }),
            const Padding(
                padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text("Yardım",
                    style: TextStyle(color: Colors.grey, fontSize: 13))),
            _buildMenuTile(Icons.headset_mic_outlined, "Seslendirme", context,
                onTap: () => _showComingSoon(context, "Seslendirme")),
            const SizedBox(height: 20),
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

  void _showComingSoon(BuildContext context, String feature) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$feature özelliği yakında eklenecek.",
          style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF2C2C2C),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showCombinedSettings(BuildContext context, KuranProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                ListTile(
                  title: const Text("Sayfa Görünüm Stili",
                      style: TextStyle(color: Colors.white)),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.pageStyle,
                      dropdownColor: const Color(0xFF3C3C3C),
                      icon: const Icon(Icons.unfold_more,
                          color: Colors.white70, size: 18),
                      style: const TextStyle(color: Colors.white70),
                      onChanged: (val) {
                        if (val != null) {
                          provider.setPageStyle(val);
                          setState(() {});
                        }
                      },
                      items: [
                        'Liste (Sure)',
                        'Metin (Sayfa)',
                        'Liste (Sayfa)',
                        'Resim'
                      ].map((String val) {
                        return DropdownMenuItem<String>(
                            value: val, child: Text(val));
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      const Text("Arkaplan",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const Spacer(),
                      _buildColorOption(
                          0, const Color(0xFF121212), provider, setState),
                      _buildColorOption(
                          1, const Color(0xFFEFE8D6), provider, setState),
                      _buildColorOption(
                          2, const Color(0xFF1B3B24), provider, setState),
                      _buildColorOption(
                          3, const Color(0xFFFFFFFF), provider, setState),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  title: const Text("Ayet Takibi",
                      style: TextStyle(color: Colors.white)),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: provider.ayahTrackingStyle,
                      dropdownColor: const Color(0xFF3C3C3C),
                      icon: const Icon(Icons.unfold_more,
                          color: Colors.white70, size: 18),
                      style: const TextStyle(color: Colors.white70),
                      onChanged: (val) {
                        if (val != null) {
                          provider.setAyahTrackingStyle(val);
                          setState(() {});
                        }
                      },
                      items: ['Vurgu', 'Renk', 'Kenarlık', 'Yok']
                          .map((String val) {
                        return DropdownMenuItem<String>(
                            value: val, child: Text(val));
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: Colors.lightBlueAccent, size: 28),
                  title: const Text("Hafız",
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF3C3C3C),
                        borderRadius: BorderRadius.circular(8)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.selectedHafizName,
                        dropdownColor: const Color(0xFF3C3C3C),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white70),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                        onChanged: (val) {
                          if (val != null) {
                            provider.changeHafiz(val);
                            Navigator.pop(context);
                          }
                        },
                        items: provider.hafizList.keys.map((String val) {
                          return DropdownMenuItem<String>(
                              value: val, child: Text(val.split(' ').first));
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white54),
                    Expanded(
                      child: Slider(
                        value: provider.volume,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          provider.setVolume(val);
                          setState(() {});
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white54),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.brightness_low, color: Colors.white54),
                    Expanded(
                      child: Slider(
                        value: provider.brightness,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white24,
                        onChanged: (val) {
                          provider.setBrightness(val);
                          setState(() {});
                        },
                      ),
                    ),
                    const Icon(Icons.brightness_high, color: Colors.white54),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildColorOption(
      int index, Color color, KuranProvider provider, StateSetter setState) {
    bool isSelected = provider.bgIndex == index;
    return GestureDetector(
      onTap: () {
        provider.setBgIndex(index);
        setState(() {});
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 44,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? Colors.amber : Colors.grey.shade700,
              width: isSelected ? 2 : 1),
        ),
        child: isSelected
            ? Icon(Icons.check,
                color: (index == 1 || index == 3) ? Colors.black : Colors.white,
                size: 16)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KuranProvider>();
    final authService = context.watch<AuthService>();
    final Color bgColor = provider.backgroundColor;
    final Color txtColor = provider.textColor;
    final double arabicFontSize = authService.kuranYaziBoyutu;
    const Color bottomPanelColor = Color(0xFF1E1E1E);

    if (provider.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final msg = provider.errorMessage;
        if (msg == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
        provider.clearError();
      });
    }

    return Opacity(
      opacity: 0.5 + (provider.brightness * 0.5),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leadingWidth: 100,
          leading: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                child: GlassButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  iconColor: txtColor,
                  size: 18,
                  onTap: () {
                    provider
                        .stopAudio(); // Çıkarken sesi kapat ki arka planda çalmasın
                    context.pop(); // Tertemiz, standart geri çıkış işlemi!
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                    provider.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: txtColor),
                onPressed: () => provider.toggleBookmark(),
              ),
            ],
          ),
          title: Column(
            children: [
              Text(provider.activeTitle,
                  style: TextStyle(
                      color: txtColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text("${provider.currentAyahs.length} Ayet",
                  style: TextStyle(
                      color: txtColor.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: txtColor),
              onPressed: () => showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF2C2C2C),
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  builder: (context) => SearchBottomSheet(provider: provider)),
            ),
            IconButton(
                icon: Icon(Icons.menu, color: txtColor),
                onPressed: () => _showMainMenu(context, provider)),
          ],
        ),
        body: Column(
          children: [
            if (provider.activeSurah?.id != 1 &&
                provider.activeSurah?.id != 9 &&
                provider.activeJuz == null &&
                provider.activePage == null &&
                provider.pageStyle != "Resim")
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                    child: Text("بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
                        style: TextStyle(color: txtColor, fontSize: 26))),
              ),
            Expanded(
              child: provider.isAyahsLoading
                  ? Center(child: CircularProgressIndicator(color: txtColor))
                  : provider.pageStyle == "Resim"
                      ? _buildImageView(provider)
                      : provider.pageStyle == "Metin (Sayfa)"
                          ? _buildTextPageView(provider, txtColor, arabicFontSize)
                          : _buildListView(provider, txtColor, arabicFontSize),
            ),
            Container(
              padding: const EdgeInsets.only(
                  top: 12, bottom: 24, left: 16, right: 16),
              decoration: const BoxDecoration(
                  color: bottomPanelColor,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24))),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white, size: 28),
                        onPressed: () =>
                            _showCombinedSettings(context, provider)),
                    IconButton(
                        icon: const Icon(Icons.record_voice_over_outlined,
                            color: Colors.white, size: 28),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text("Seslendirme özelliği yakında eklenecek.",
                              style: TextStyle(color: Colors.white)),
                          backgroundColor: Color(0xFF2C2C2C),
                          duration: Duration(seconds: 2),
                        ))),
                    TextButton(
                        onPressed: () => provider.changeSpeed(),
                        child: Text("${provider.speed.toStringAsFixed(1)}x",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16))),

                    // --- 2. DURDUR (STOP) TUŞU ---
                    IconButton(
                      icon: const Icon(Icons.stop_rounded,
                          color: Colors.white, size: 36),
                      onPressed: () =>
                          provider.stopAudio(), // Yeni Stop fonksiyonumuz
                    ),

                    GestureDetector(
                      onTap: provider.isAyahsLoading
                          ? null
                          : () => provider.togglePlay(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: Icon(
                            provider.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: bottomPanelColor,
                            size: 32),
                      ),
                    ),

                    // --- 3. TEKRAR (REPEAT) TUŞU ---
                    IconButton(
                      icon: Icon(Icons.repeat_rounded,
                          color: provider.isRepeatOne
                              ? Colors.amber
                              : Colors.white,
                          size: 28),
                      onPressed: () => provider
                          .toggleRepeat(), // Ayeti döngüye alır ve rengi sarı yapar
                    ),

                    // --- 4. LİSTE (GÖRÜNÜM DEĞİŞTİRME) TUŞU ---
                    IconButton(
                      icon: Icon(Icons.format_list_bulleted_rounded,
                          color: provider.pageStyle.contains('Liste')
                              ? Colors.amber
                              : Colors.white,
                          size: 28),
                      onPressed: () {
                        // Tıklandığında Resim (Mushaf) görünümü ile Liste görünümü arasında geçiş yapar
                        provider.setPageStyle(provider.pageStyle == "Resim"
                            ? "Liste (Sure)"
                            : "Resim");
                      },
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

  Widget _buildListView(
      KuranProvider provider, Color txtColor, double arabicFontSize) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.currentAyahs.length,
      separatorBuilder: (context, index) =>
          Divider(color: txtColor.withValues(alpha: 0.2), height: 32),
      itemBuilder: (context, index) {
        final ayah = provider.currentAyahs[index];
        final isActive = ayah.id == provider.activeAyahId;
        Color itemBgColor = (isActive && provider.ayahTrackingStyle == "Vurgu")
            ? txtColor.withValues(alpha: 0.1)
            : Colors.transparent;

        return InkWell(
          onTap: () => provider.playSingleAyah(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: itemBgColor,
              borderRadius: BorderRadius.circular(12),
              border: isActive && provider.ayahTrackingStyle == "Kenarlık"
                  ? Border.all(color: Colors.amber, width: 1.5)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "${ayah.textUthmani} ﴿${ayah.verseKey.split(':')[1]}﴾",
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                      color: isActive && provider.ayahTrackingStyle == "Renk"
                          ? Colors.amber
                          : txtColor,
                      fontSize: arabicFontSize,
                      height: 1.8),
                ),
                const SizedBox(height: 16),
                Text("Diyanet",
                    style: TextStyle(
                        color: txtColor.withValues(alpha: 0.4), fontSize: 11)),
                const SizedBox(height: 4),
                Text(ayah.translation,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: txtColor.withValues(alpha: 0.8),
                        fontSize: 15,
                        height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextPageView(
      KuranProvider provider, Color txtColor, double arabicFontSize) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            children: provider.currentAyahs.map((ayah) {
              bool isActive = ayah.id == provider.activeAyahId;

              return TextSpan(
                text: "${ayah.textUthmani} ﴿${ayah.verseKey.split(':')[1]}﴾ ",
                style: TextStyle(
                  fontSize: arabicFontSize,
                  height: 1.8,
                  color: isActive && provider.ayahTrackingStyle == "Renk"
                      ? Colors.amber
                      : txtColor,
                  backgroundColor:
                      isActive && provider.ayahTrackingStyle == "Vurgu"
                          ? txtColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildImageView(KuranProvider provider) {
    final Set<int> pages = provider.currentAyahs
        .map<int>((a) => int.tryParse(a.pageNumber.toString()) ?? 1)
        .toSet();
    final List<int> pageList = pages.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: pageList.length,
      itemBuilder: (context, index) {
        final pageNum = pageList[index];
        final String pageStr = pageNum.toString().padLeft(3, '0');

        final String imageUrl =
            "https://android.quran.com/data/width_1024/page$pageStr.png";

        final bool isDarkMode = provider.bgIndex == 0;
        final Color paperColor =
            isDarkMode ? const Color(0xFF242424) : const Color(0xFFF4EDD3);
        final Color inkColor =
            isDarkMode ? Colors.white70 : const Color(0xFF1A1A1A);
        final Color borderColor =
            isDarkMode ? Colors.white12 : const Color(0xFFB89B5E);

        return Container(
          margin: const EdgeInsets.only(bottom: 24.0),
          decoration: BoxDecoration(
            color: paperColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8)),
            ],
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _KuranPageImage(
              pageNumber: pageNum,
              imageUrl: imageUrl,
              inkColor: inkColor,
              borderColor: borderColor,
            ),
          ),
        );
      },
    );
  }
}

/// Sayfayı önce yerel önbellekten (daha önce indirildiyse) gösterir; yoksa
/// ağdan çeker ve başarılı yüklemenin ardından bir sonraki (olası çevrimdışı)
/// görüntüleme için sessizce diske kaydeder.
class _KuranPageImage extends StatefulWidget {
  final int pageNumber;
  final String imageUrl;
  final Color inkColor;
  final Color borderColor;

  const _KuranPageImage({
    required this.pageNumber,
    required this.imageUrl,
    required this.inkColor,
    required this.borderColor,
  });

  @override
  State<_KuranPageImage> createState() => _KuranPageImageState();
}

class _KuranPageImageState extends State<_KuranPageImage> {
  late final Future<String?> _localPathFuture;
  bool _cachingTriggered = false;

  @override
  void initState() {
    super.initState();
    _localPathFuture = KuranDownloadService.getPagePath(widget.pageNumber);
  }

  void _cacheInBackground() {
    if (_cachingTriggered) return;
    _cachingTriggered = true;
    KuranDownloadService.downloadPage(widget.pageNumber, widget.imageUrl)
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _localPathFuture,
      builder: (context, snapshot) {
        final localPath = snapshot.data;
        if (localPath != null && File(localPath).existsSync()) {
          return Image.file(File(localPath),
              fit: BoxFit.fitWidth, color: widget.inkColor);
        }

        return Image.network(
          widget.imageUrl,
          headers: const {"User-Agent": "Mozilla/5.0"},
          fit: BoxFit.fitWidth,
          color: widget.inkColor,
          loadingBuilder: (context, child, progress) {
            if (progress == null) {
              _cacheInBackground();
              return child;
            }
            return SizedBox(
                height: 400,
                child: Center(
                    child:
                        CircularProgressIndicator(color: widget.borderColor)));
          },
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded,
                        color: widget.borderColor.withValues(alpha: 0.5),
                        size: 48),
                    const SizedBox(height: 12),
                    Text("Sayfa görseli indirilemedi.",
                        style: TextStyle(
                            color: widget.inkColor.withValues(alpha: 0.5))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
