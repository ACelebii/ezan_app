import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ezan_vakti_uygulamasi/locator.dart';
import 'package:ezan_vakti_uygulamasi/features/dualar/data/dualar_repository.dart';
import '../../core/theme/app_theme.dart';
import 'dualar_model.dart';
import 'dua_detail_page.dart';

// ============================================================================
// ORTAK BUTON TASARIMI (Glassmorphism)
// ============================================================================
Widget _buildGlassButton(BuildContext context,
    {required IconData icon, required VoidCallback onTap}) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child:
          Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
    ),
  );
}

// Kategorilere özel ikon atamak için küçük bir yardımcı fonksiyon
IconData _getCategoryIcon(String title) {
  String t = title.toLowerCase();
  if (t.contains('sabah') || t.contains('akşam'))
    return Icons.wb_twilight_rounded;
  if (t.contains('namaz')) return Icons.pan_tool_alt_rounded;
  if (t.contains('hac') || t.contains('umre')) return Icons.language_rounded;
  if (t.contains('şifa')) return Icons.healing_rounded;
  if (t.contains('yemek')) return Icons.restaurant_rounded;
  if (t.contains('sınav')) return Icons.edit_note_rounded;
  return Icons.menu_book_rounded; // Varsayılan ikon
}

// ============================================================================
// 1. KATEGORİLERİN LİSTELENDİĞİ ANA SAYFA (GRID TASARIMI)
// ============================================================================
class DualarPage extends StatefulWidget {
  const DualarPage({super.key});

  @override
  State<DualarPage> createState() => _DualarPageState();
}

class _DualarPageState extends State<DualarPage> {
  List<DuaCategory> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDualar();
  }

  Future<void> _loadDualar() async {
    try {
      final repo = getIt<DualarRepository>();
      final data = await repo.getData();
      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Dualar Yükleme Hatası: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 20.0),
              child: Row(
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Dualar",
                style: AppTheme.headerStyle.copyWith(color: textColor),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.teal))
                  : categories.isEmpty
                      ? const Center(child: Text("Dualar yüklenemedi."))
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 8.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Yan yana 2 kutu
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1, // Kutuların en/boy oranı
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            return InkWell(
                              onTap: () {
                                // Kutuya tıklanınca Liste sayfasına gidiyoruz
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DuaListPage(category: cat)));
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.04),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5))
                                        ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(_getCategoryIcon(cat.title),
                                            color: Colors.teal, size: 28),
                                      ),
                                      Text(
                                        cat.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. KATEGORİ İÇİNDEKİ DUALARIN LİSTELENDİĞİ SAYFA
// ============================================================================
class DuaListPage extends StatelessWidget {
  final DuaCategory category;

  const DuaListPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 20.0),
              child: Row(
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                category.title,
                style: TextStyle(
                    color: textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    height: 1.2),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                ),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: category.items.length,
                  separatorBuilder: (context, index) => Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: isDark ? Colors.white10 : Colors.black12),
                  itemBuilder: (context, index) {
                    final item = category.items[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 6.0),
                      title: Text(
                        item.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black87),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isDark ? Colors.white24 : Colors.black26),
                      onTap: () {
                        // Duaya tıklanınca Detay sayfasına gidiyoruz
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DuaDetailPage(dua: item)));
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
