import '../../core/i18n/cevir.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/kuran_provider.dart';
import 'data/arama_vurgusu.dart' show VurguluMeal, vurguluMeal;
import 'data/kuran_arama_indeksi.dart' show AramaSonucu;
import 'data/sayfa_indirici.dart' show kuranSayfaAdresi, kuranSayfaSayisi;
import 'kuran_models.dart';
import 'kuran_download_service.dart';
import 'kuran_kayit_sayfalari.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../auth/auth_service.dart';
import '../../core/utils/arama_metni.dart';
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
      // Türkçe ad ("Bakara"), Latin yazım ("Al-Baqarah") ya da numara; harf
      // aksanı ve büyük/küçük harf fark etmez ("fatiha" = "Fâtiha").
      final aranan = aramaMetni(query);
      return widget.provider.surahs
          .where((s) =>
              aramaMetni(s.turkishName).contains(aranan) ||
              aramaMetni(s.nameSimple).contains(aranan) ||
              s.id.toString().contains(query.trim()))
          .toList();
    } else if (selectedTab == 1) {
      List<int> allJuzs = List.generate(30, (i) => i + 1);
      if (query.isEmpty) return allJuzs;
      return allJuzs.where((j) => j.toString().contains(query)).toList();
    } else if (selectedTab == 0) {
      List<int> allPages = List.generate(604, (i) => i + 1);
      if (query.isEmpty) return allPages;
      return allPages.where((p) => p.toString().contains(query)).toList();
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
    }

    Navigator.of(context).pop();

    if (widget.isFromMainPage) {
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
                _buildSearchTab(context.t("Sayfa"), 0),
                _buildSearchTab(context.t("Cüz"), 1),
                _buildSearchTab(context.t("Sure"), 2),
                _buildSearchTab(context.t("Meal"), 3),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => query = val),
                decoration: InputDecoration(
                  hintText: context.t(selectedTab == 3
                      ? "Mealde ara (tüm Kur'an)"
                      : "Ara (İsim veya Numara)"),
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
              child: selectedTab == 3
                  ? _mealAramaGovdesi()
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        String title = "";
                        if (selectedTab == 2) {
                          title =
                              "${(item as SurahModel).id}. ${widget.provider.sureAdi(item)}";
                        } else if (selectedTab == 1) {
                          title = context.t("$item. Cüz");
                        } else if (selectedTab == 0) {
                          title = context.t("$item. Sayfa");
                        }

                        return ListTile(
                          title: Text(title,
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.clip),
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
                    if (selectedTab == 3) {
                      final ilk = widget.provider.mealAra(query).sonuclar;
                      if (ilk.isNotEmpty) _sonucaGit(ilk.first);
                    } else if (items.isNotEmpty) {
                      _onItemTapped(items.first);
                    }
                  },
                  child: Text(context.t("Git!"),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
            )
          ],
        ),
      ),
    );
  }

  /// Bir meal arama sonucuna gider: sure açıksa o ayete kayar, değilse sureyi
  /// o ayette açar.
  void _sonucaGit(AramaSonucu s) {
    final p = widget.provider;
    final yonlendirici = widget.isFromMainPage ? GoRouter.of(context) : null;
    Navigator.of(context).pop();
    final acik = p.activeSurah?.id == s.sureId && p.currentAyahs.isNotEmpty;
    final i =
        acik ? p.currentAyahs.indexWhere((a) => a.verseKey == s.verseKey) : -1;
    if (i >= 0) {
      p.ayeteKaydir(i);
      p.playSingleAyah(i);
    } else {
      for (final sure in p.surahs) {
        if (sure.id == s.sureId) {
          p.loadSurahDetails(sure, ayetNo: s.ayetNo);
          break;
        }
      }
    }
    yonlendirici?.push('/kuran/surah-detail', extra: p);
  }

  Widget _ortaMetin(String metin) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(metin,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54)),
        ),
      );

  /// Meal sekmesi: cihazdaki surelerin durumu ("N / 114 sure cihazda",
  /// "Tümünü indir") ve tüm Kur'an'daki sonuçlar.
  Widget _mealAramaGovdesi() {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final sayfa = p.mealAra(query);
        final Widget icerik;
        if (query.trim().isEmpty) {
          icerik = _ortaMetin(context.t('Aramak için yazın.'));
        } else if (sayfa.sonuclar.isEmpty) {
          icerik = _ortaMetin(context.t('Sonuç bulunamadı.'));
        } else {
          icerik = Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      context.t(sayfa.toplam > sayfa.sonuclar.length
                          ? '${sayfa.toplam} sonuç (ilk ${sayfa.sonuclar.length} gösteriliyor)'
                          : '${sayfa.toplam} sonuç'),
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12)),
                ),
              ),
              if (sayfa.yaklasik)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        context.t(
                            'Tam eşleşme yok; benzer sözcükler gösteriliyor.'),
                        style:
                            const TextStyle(color: Colors.amber, fontSize: 12)),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: sayfa.sonuclar.length,
                  itemBuilder: (context, i) {
                    final s = sayfa.sonuclar[i];
                    return ListTile(
                      dense: true,
                      title: Text('${p.sureAdiId(s.sureId)}  ·  ${s.verseKey}',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      subtitle: Text.rich(
                          _vurguluMetin(vurguluMeal(s.meal, s.terimler)),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70)),
                      onTap: () => _sonucaGit(s),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return Column(
          children: [_indirmeSatiri(context, p), Expanded(child: icerik)],
        );
      },
    );
  }

  /// Aranan sözcükleri (yazılan biçim ve türetilmiş gövdeleri) renkli gösterir.
  TextSpan _vurguluMetin(VurguluMeal v) {
    const vurgu = TextStyle(color: Colors.amber, fontWeight: FontWeight.bold);
    final parcalar = <TextSpan>[];
    var son = 0;
    for (final (bas, bit) in v.aralar) {
      if (bas > son) parcalar.add(TextSpan(text: v.metin.substring(son, bas)));
      parcalar.add(TextSpan(text: v.metin.substring(bas, bit), style: vurgu));
      son = bit;
    }
    if (son < v.metin.length) {
      parcalar.add(TextSpan(text: v.metin.substring(son)));
    }
    return TextSpan(children: parcalar);
  }

  Widget _indirmeSatiri(BuildContext context, KuranProvider p) {
    final hepsi = p.aramadakiSureSayisi >= 114;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                    context.t('${p.aramadakiSureSayisi} / 114 sure cihazda'),
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              if (!hepsi)
                p.tumKuranIndiriliyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.amber))
                    : TextButton(
                        onPressed: p.tumKuraniIndir,
                        child: Text(context.t('Tümünü indir')),
                      ),
            ],
          ),
          if (p.tumKuranIndiriliyor || p.aramaHazirlaniyor)
            LinearProgressIndicator(
                value:
                    p.tumKuranIndiriliyor ? p.aramadakiSureSayisi / 114 : null,
                color: Colors.amber,
                backgroundColor: Colors.white12,
                minHeight: 2),
          if (p.indirmeHatasi != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(context.t(p.indirmeHatasi!),
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
        ],
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
        if (index == 3) widget.provider.aramaIndeksiniHazirla();
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
                onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            }),
            _buildMenuTile(Icons.library_books, context.t("Cüzler"), context,
                onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            }),
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
              if (!success) {
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
            _buildMenuTile(Icons.replay, context.t("Ezberleme"), context,
                onTap: () => _ozellikAc(
                    sayfa, context, provider, KuranOzelligi.ezberleme)),
            Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(context.t("Ayarlar"),
                    style: const TextStyle(color: Colors.grey, fontSize: 13))),
            _buildMenuTile(Icons.settings, context.t("Ayarlar"), context,
                onTap: () {
              Navigator.pop(context);
              _showCombinedSettings(context, provider);
            }),
            Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                child: Text(context.t("Yardım"),
                    style: const TextStyle(color: Colors.grey, fontSize: 13))),
            _buildMenuTile(
                Icons.headset_mic_outlined, context.t("Seslendirme"), context,
                onTap: () => _ozellikAc(
                    sayfa, context, provider, KuranOzelligi.seslendirme)),
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

  /// Menüyü kapatıp [ozellik]i açar ([sayfa]: menüyü açan sayfanın context'i).
  void _ozellikAc(BuildContext sayfa, BuildContext menu, KuranProvider provider,
      KuranOzelligi ozellik) {
    Navigator.pop(menu);
    kuranOzelligiAc(sayfa, provider, ozellik, detayAcik: true);
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
                  title: Text(context.t("Sayfa Görünüm Stili"),
                      style: const TextStyle(color: Colors.white)),
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
                            value: val, child: Text(context.t(val)));
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Text(context.t("Arkaplan"),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
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
                  title: Text(context.t("Ayet Takibi"),
                      style: const TextStyle(color: Colors.white)),
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
                            value: val, child: Text(context.t(val)));
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.person_outline,
                      color: Colors.lightBlueAccent, size: 28),
                  title: Text(context.t("Hafız"),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
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
                              value: val,
                              child: Text(context.t(val.split(' ').first)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.t(msg)), backgroundColor: Colors.redAccent));
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
              Text(context.t("${provider.currentAyahs.length} Ayet"),
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
                  : provider.currentAyahs.isEmpty
                      ? _buildYuklenemedi(context, provider, txtColor)
                      : provider.pageStyle == "Resim"
                          ? _buildImageView(provider, txtColor, arabicFontSize)
                          : provider.pageStyle == "Metin (Sayfa)"
                              ? _buildTextPageView(
                                  provider, txtColor, arabicFontSize)
                              : _buildListView(
                                  provider, txtColor, arabicFontSize),
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
                  // Her düğme eşit pay alır; payına sığmazsa küçülür (dar
                  // ekranda 7 düğme yan yana sığmıyordu: 12 dp taşıyordu).
                  children: [
                    IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: Colors.white, size: 28),
                        onPressed: () =>
                            _showCombinedSettings(context, provider)),
                    IconButton(
                        icon: const Icon(Icons.record_voice_over_outlined,
                            color: Colors.white, size: 28),
                        tooltip: context.t('Seslendirme (Hafız)'),
                        onPressed: () => seslendirmeAc(context, provider)),
                    TextButton(
                        // Varsayılan en az 64 dp genişlik, eşit paydan geniş
                        // olduğu için yazıyı küçültüyordu.
                        style: TextButton.styleFrom(
                            minimumSize: const Size(44, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 4)),
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
                  ].map(_esitPay).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(
          KuranProvider provider, Color txtColor, double arabicFontSize) =>
      _AyetListesi(
          provider: provider,
          txtColor: txtColor,
          arabicFontSize: arabicFontSize);

  /// Ayetler alınamadıysa (çoğunlukla internet yok) boş ekran yerine açıklama
  /// ve "Tekrar Dene". Yükleme uyarısı birkaç saniyede kaybolduğu için ekranda
  /// kalıcı bir durum gerekir.
  Widget _buildYuklenemedi(
      BuildContext context, KuranProvider provider, Color txtColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 56, color: txtColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
                context.t(
                    'Ayetler yüklenemedi.\nİnternet bağlantınızı kontrol edip tekrar deneyin.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: txtColor.withValues(alpha: 0.7), height: 1.5)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: provider.yenidenYukle,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.t('Tekrar Dene')),
              style: OutlinedButton.styleFrom(foregroundColor: txtColor),
            ),
          ],
        ),
      ),
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

  /// Resim görünümünde ayet seçilemez; bu düğme sayfanın ayetlerini (favori,
  /// not, dinle) alt sayfada açar.
  void _sayfaAyetleri(BuildContext context, KuranProvider provider, int sayfa,
      Color txtColor, double arabicFontSize) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: provider.backgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SizedBox(
        height: MediaQuery.of(c).size.height * 0.75,
        child: SayfaAyetleri(
            provider: provider,
            sayfa: sayfa,
            txtColor: txtColor,
            arabicFontSize: arabicFontSize),
      ),
    );
  }

  Widget _buildImageView(
      KuranProvider provider, Color txtColor, double arabicFontSize) {
    final Set<int> pages = provider.currentAyahs
        .map<int>((a) => int.tryParse(a.pageNumber.toString()) ?? 1)
        .toSet();
    final List<int> pageList = pages.toList()..sort();

    final liste = ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: pageList.length,
      itemBuilder: (context, index) {
        final pageNum = pageList[index];
        final String imageUrl = kuranSayfaAdresi(pageNum);

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
            child: Column(
              children: [
                _KuranPageImage(
                  pageNumber: pageNum,
                  imageUrl: imageUrl,
                  inkColor: inkColor,
                  borderColor: borderColor,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _sayfaAyetleri(
                        context, provider, pageNum, txtColor, arabicFontSize),
                    icon: Icon(Icons.format_list_bulleted,
                        size: 18, color: inkColor),
                    label: Text(context.t('Bu sayfanın ayetleri'),
                        style: TextStyle(color: inkColor)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    return Column(children: [
      SayfaIndirmeSatiri(provider: provider, txtColor: txtColor),
      Expanded(child: liste),
    ]);
  }
}

/// Ayet listesi (Liste görünümleri): her ayette favori ve not düğmesi; bir
/// ayete gidilmişse ([KuranProvider.hedefAyetIndex]) o ayete kaydırır.
class _AyetListesi extends StatefulWidget {
  const _AyetListesi({
    required this.provider,
    required this.txtColor,
    required this.arabicFontSize,
  });

  final KuranProvider provider;
  final Color txtColor;
  final double arabicFontSize;

  @override
  State<_AyetListesi> createState() => _AyetListesiState();
}

class _AyetListesiState extends State<_AyetListesi> {
  final _kaydirici = ItemScrollController();

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final txtColor = widget.txtColor;

    // Hedef ayet varsa bir kez kaydır (yeni liste: ilk kareden açılır; eski
    // liste yeniden kullanılmışsa ilk kareden sonra atlanır) ve hedefi sil.
    final hedef = provider.hedefAyetIndex;
    if (hedef != null) {
      provider.hedefiTemizle();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_kaydirici.isAttached) _kaydirici.jumpTo(index: hedef);
      });
    }

    return ScrollablePositionedList.separated(
      itemScrollController: _kaydirici,
      initialScrollIndex: hedef ?? 0,
      padding: const EdgeInsets.all(16),
      itemCount: provider.currentAyahs.length,
      separatorBuilder: (context, index) =>
          Divider(color: txtColor.withValues(alpha: 0.2), height: 32),
      itemBuilder: (context, index) => _AyetSatiri(
          provider: provider,
          index: index,
          txtColor: txtColor,
          arabicFontSize: widget.arabicFontSize),
    );
  }
}

/// Bir ayetin satırı: Arapça metin, meal, not, favori/not düğmeleri; dokununca
/// o ayeti çalar. Liste görünümünde ve Resim görünümündeki "Bu sayfanın
/// ayetleri" alt sayfasında ortaktır. [index], `provider.currentAyahs` içindeki yeridir.
class _AyetSatiri extends StatelessWidget {
  const _AyetSatiri({
    required this.provider,
    required this.index,
    required this.txtColor,
    required this.arabicFontSize,
  });

  final KuranProvider provider;
  final int index;
  final Color txtColor;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) {
    final ayah = provider.currentAyahs[index];
    final isActive = ayah.id == provider.activeAyahId;
    final favori = provider.favoriMi(ayah);
    final not = provider.notu(ayah);
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
            Text(provider.mealKaynagiEtiketi(ayah),
                style: TextStyle(
                    color: txtColor.withValues(alpha: 0.4), fontSize: 11)),
            const SizedBox(height: 4),
            Text(provider.mealMetni(ayah),
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: txtColor.withValues(alpha: 0.8),
                    fontSize: 15,
                    height: 1.5)),
            if (not.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(
                      left: BorderSide(color: Colors.amber, width: 3)),
                ),
                child:
                    Text(not, style: TextStyle(color: txtColor, height: 1.4)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: context.t(not.isEmpty ? 'Not ekle' : 'Notu düzenle'),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                      not.isEmpty ? Icons.edit_note : Icons.sticky_note_2,
                      color: not.isEmpty
                          ? txtColor.withValues(alpha: 0.5)
                          : Colors.amber),
                  onPressed: () =>
                      notDuzenle(context, provider, provider.ayetKaydi(ayah)),
                ),
                IconButton(
                  tooltip:
                      context.t(favori ? 'Favoriden çıkar' : 'Favorilere ekle'),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(favori ? Icons.favorite : Icons.favorite_border,
                      color: favori
                          ? Colors.amber
                          : txtColor.withValues(alpha: 0.5)),
                  onPressed: () => provider
                      .kayitDegistir(provider.ayetKaydi(ayah), favori: !favori),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Resim görünümünde ayet seçilemediği için: [sayfa]nın ayetleri, Liste
/// görünümündekiyle aynı satırla (favori, not, dinle). Favori/not değişince
/// (ve ses ilerleyince) kendini yeniler.
class SayfaAyetleri extends StatelessWidget {
  const SayfaAyetleri({
    super.key,
    required this.provider,
    required this.sayfa,
    required this.txtColor,
    required this.arabicFontSize,
  });

  final KuranProvider provider;
  final int sayfa;
  final Color txtColor;
  final double arabicFontSize;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final indeksler = [
          for (var i = 0; i < provider.currentAyahs.length; i++)
            if (provider.currentAyahs[i].pageNumber == sayfa) i,
        ];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('${context.t('Sayfa')} $sayfa',
                  style: TextStyle(
                      color: txtColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: indeksler.length,
                separatorBuilder: (context, _) =>
                    Divider(color: txtColor.withValues(alpha: 0.2), height: 32),
                itemBuilder: (context, k) => _AyetSatiri(
                    provider: provider,
                    index: indeksler[k],
                    txtColor: txtColor,
                    arabicFontSize: arabicFontSize),
              ),
            ),
          ],
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
                    Text(context.t("Sayfa görseli indirilemedi."),
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

/// Resim görünümünün üstündeki satır: sayfa görselleri cihazda mı, "Tümünü
/// indir" (internetsiz Resim görünümü). Hepsi indirilince düğme kalkar.
class SayfaIndirmeSatiri extends StatefulWidget {
  const SayfaIndirmeSatiri(
      {super.key, required this.provider, required this.txtColor});

  final KuranProvider provider;
  final Color txtColor;

  @override
  State<SayfaIndirmeSatiri> createState() => _SayfaIndirmeSatiriState();
}

class _SayfaIndirmeSatiriState extends State<SayfaIndirmeSatiri> {
  @override
  void initState() {
    super.initState();
    widget.provider.sayfaDurumunuYukle();
  }

  /// 604 sayfa yaklaşık 57 MB (cihazda ölçüldü: 604 sayfa = 56,6 MB); mobil veride
  /// habersiz indirilmesin diye önce sorulur.
  Future<void> _sor() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.t('Tüm sayfaları indir')),
        content: Text(c.t(
            'Yaklaşık 57 MB indirilecek. Mobil veri kullanıyorsanız ücret çıkabilir.')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(c.t('Vazgeç'))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(c.t('İndir'))),
        ],
      ),
    );
    if (onay == true) widget.provider.tumSayfalariIndir();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final p = widget.provider;
        final hepsi = p.sayfaCihazda >= kuranSayfaSayisi;
        final soluk = widget.txtColor.withValues(alpha: 0.6);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                        context.t(
                            '${p.sayfaCihazda} / $kuranSayfaSayisi sayfa cihazda'),
                        style: TextStyle(color: soluk, fontSize: 12)),
                  ),
                  if (p.sayfalarIndiriliyor)
                    TextButton(
                        onPressed: p.sayfaIndirmesiniDurdur,
                        child: Text(context.t('Durdur')))
                  else if (!hepsi) ...[
                    // Açık olan birkaç sayfa küçük bir indirme; onay penceresi
                    // gerektirmez (yaklaşık boyut yalnız 604 sayfanın hepsi için
                    // anlamlı).
                    TextButton(
                        onPressed: p.acikSayfalariIndir,
                        child: Text(context.t('Bu sayfaları indir'))),
                    TextButton(
                        onPressed: _sor,
                        child: Text(context.t('Tümünü indir'))),
                  ],
                ],
              ),
              if (p.sayfalarIndiriliyor)
                LinearProgressIndicator(
                    value: p.sayfaCihazda / kuranSayfaSayisi,
                    color: Colors.amber,
                    backgroundColor: soluk.withValues(alpha: 0.2),
                    minHeight: 2),
              if (p.sayfaHatasi != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(context.t(p.sayfaHatasi!),
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Oynatıcı çubuğundaki bir düğmeye satırdan eşit pay verir; payı düğmenin
/// doğal genişliğinden darsa düğme sığacak kadar küçülür.
Widget _esitPay(Widget dugme) =>
    Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: dugme));
