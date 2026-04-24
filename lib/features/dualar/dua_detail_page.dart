import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dualar_model.dart';

class DuaDetailPage extends StatelessWidget {
  final DuaItem dua;
  const DuaDetailPage({super.key, required this.dua});

  // Ortak Glass Buton Tasarımı
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

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ÜST BAR
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),
                  _buildGlassButton(context, icon: Icons.copy_rounded,
                      onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: "${dua.arabic}\n\n${dua.meaning}"));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Dua kopyalandı"),
                        behavior: SnackBarBehavior.floating));
                  }),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // DUA BAŞLIĞI
                    Text(
                      dua.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ARAPÇA METİN KUTUSU
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10))
                              ],
                      ),
                      child: Text(
                        dua.arabic,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 28,
                          fontFamily:
                              'Regular', // Eğer özel bir Arapça fontun varsa buraya yazabilirsin
                          height: 1.8,
                          color: Colors.teal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OKUNUŞ VE ANLAM KARTI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Okunuşu", isDark),
                          const SizedBox(height: 8),
                          Text(
                            dua.pronunciation,
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: textColor.withOpacity(0.7),
                              height: 1.5,
                            ),
                          ),
                          const Divider(height: 40, thickness: 0.5),
                          _sectionTitle("Anlamı", isDark),
                          const SizedBox(height: 8),
                          Text(
                            dua.meaning,
                            style: TextStyle(
                              fontSize: 17,
                              color: textColor,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // KAYNAK BİLGİSİ
                    if (dua.reference.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Text(
                          "Kaynak: ${dua.reference}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withOpacity(0.4),
                          ),
                        ),
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

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: isDark ? Colors.tealAccent : Colors.teal.shade700,
      ),
    );
  }
}
