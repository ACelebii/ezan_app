import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../auth/auth_service.dart';

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
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
      ),
      child:
          Icon(icon, color: isDark ? Colors.white : Colors.black87, size: 20),
    ),
  );
}

// ============================================================================
// VERİ MODELİ (Firebase'den Gelecek Veriler İçin)
// ============================================================================
class HutbeItem {
  final String baslik;
  final String tarih;
  final String resimUrl;
  final String pdfUrl;

  HutbeItem(
      {required this.baslik,
      required this.tarih,
      required this.resimUrl,
      required this.pdfUrl});

  factory HutbeItem.fromFirestore(Map<String, dynamic> data) {
    // Firebase'deki isimlerle koddaki isimleri eşleştiriyoruz
    return HutbeItem(
      baslik: data['baslik']?.toString() ?? 'Başlıksız Hutbe',
      tarih: data['tarih']?.toString() ?? 'Tarih Yok',
      resimUrl: (data['resimUrl'] ?? data['resimurl'] ?? '').toString(),
      pdfUrl: (data['pdfUrl'] ?? data['pdfurl'] ?? '').toString(),
    );
  }
}

// ============================================================================
// FIREBASE VERİ ÇEKME SERVİSİ (PROFESYONEL VE TEMİZ)
// ============================================================================
class HutbeServisi {
  Future<List<HutbeItem>> fetchHutbeler() async {
    try {
      // DİKKAT: Veritabanın ismi büyük ihtimalle 'ezan-app' veya benzeri bir isim.
      // Firebase Panelinde (Firestore sayfasında) sol üstte yazan ismi tırnak içine yaz.
      // Eğer isminden emin değilsen, bu satırı 'ezan-app' olarak deneyebilirsin.

      var snapshot = await FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: dotenv.env['FIREBASE_DB_ID'] ?? 'default',
      ).collection('hutbeler').get(const GetOptions(source: Source.server));

      if (snapshot.docs.isEmpty) {
        print("Bağlantı başarılı ama koleksiyon boş.");
        return [];
      }

      return snapshot.docs
          .map((doc) => HutbeItem.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print("Firestore Detaylı Hata: $e");
      // Hata hala devam ederse, terminaldeki yeni hata mesajını bana at.
      throw Exception("Bağlantı Hatası: $e");
    }
  }
}

// ============================================================================
// 1. ANA LİSTE SAYFASI
// ============================================================================
class HaftaninHutbesiPage extends StatefulWidget {
  const HaftaninHutbesiPage({super.key});

  @override
  State<HaftaninHutbesiPage> createState() => _HaftaninHutbesiPageState();
}

class _HaftaninHutbesiPageState extends State<HaftaninHutbesiPage> {
  final HutbeServisi _servis = HutbeServisi();
  late Future<List<HutbeItem>> _hutbeFuture;

  @override
  void initState() {
    super.initState();
    _hutbeFuture = _servis.fetchHutbeler();
  }

  // Sayfayı aşağı çekip yenilemek için metod
  Future<void> _refreshData() async {
    setState(() {
      _hutbeFuture = _servis.fetchHutbeler();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
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
                authService.translate("Haftanın Hutbesi"),
                style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.teal,
                child: FutureBuilder<List<HutbeItem>>(
                  future: _hutbeFuture,
                  builder: (context, snapshot) {
                    // Yükleniyor durumu
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: Colors.teal));
                    }
                    // Hata durumu (İnternet yoksa veya Firebase engellerse burası çalışır)
                    else if (snapshot.hasError) {
                      return ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(), // Sayfayı aşağı çekebilmek için şart
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2),
                          Icon(Icons.wifi_off_rounded,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              "Sunucuya bağlanılamadı.\nLütfen internet bağlantınızı kontrol edip sayfayı aşağı çekerek yenileyin.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.6),
                                  height: 1.5),
                            ),
                          ),
                        ],
                      );
                    }
                    // Boş veri durumu
                    else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2),
                          Icon(Icons.article_outlined,
                              size: 64,
                              color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            "Henüz hutbe eklenmemiş.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 16),
                          ),
                        ],
                      );
                    }

                    // Veri başarıyla geldi
                    final hutbeler = snapshot.data!;
                    final oneCikanHutbeler = hutbeler.length >= 2
                        ? hutbeler.take(2).toList()
                        : hutbeler;
                    final digerHutbeler =
                        hutbeler.length > 2 ? hutbeler.skip(2).toList() : [];

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // YATAY KARTLAR
                          if (oneCikanHutbeler.isNotEmpty)
                            SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: oneCikanHutbeler.length,
                                itemBuilder: (context, index) {
                                  final hutbe = oneCikanHutbeler[index];
                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                HutbePdfPage(hutbe: hutbe))),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.85,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          image: DecorationImage(
                                            image: NetworkImage(hutbe.resimUrl),
                                            fit: BoxFit.cover,
                                            colorFilter: ColorFilter.mode(
                                                Colors.black
                                                    .withValues(alpha: 0.4),
                                                BlendMode.darken),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 10,
                                                offset: const Offset(0, 5))
                                          ]),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text(hutbe.baslik,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.2)),
                                            const SizedBox(height: 8),
                                            Text(hutbe.tarih,
                                                style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.8),
                                                    fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          const SizedBox(height: 30),

                          // DİKEY LİSTE
                          if (digerHutbeler.isNotEmpty)
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1C1C1E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: isDark
                                      ? []
                                      : [
                                          BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ]),
                              child: Column(
                                children:
                                    digerHutbeler.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var hutbe = entry.value;
                                  bool isLast =
                                      index == digerHutbeler.length - 1;

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 8),
                                        title: Text(hutbe.baslik,
                                            style: TextStyle(
                                                color: textColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500)),
                                        subtitle: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4.0),
                                          child: Text(hutbe.tarih,
                                              style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white54
                                                      : Colors.grey.shade500,
                                                  fontSize: 13)),
                                        ),
                                        trailing: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.grey.shade300,
                                            size: 14),
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    HutbePdfPage(
                                                        hutbe: hutbe))),
                                      ),
                                      if (!isLast)
                                        Divider(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.grey.shade200,
                                            height: 1,
                                            indent: 20,
                                            endIndent: 20),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. PDF GÖRÜNTÜLEYİCİ SAYFASI
// ============================================================================
class HutbePdfPage extends StatefulWidget {
  final HutbeItem hutbe;
  const HutbePdfPage({super.key, required this.hutbe});

  @override
  State<HutbePdfPage> createState() => _HutbePdfPageState();
}

class _HutbePdfPageState extends State<HutbePdfPage> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),
                  _buildGlassButton(context, icon: Icons.info_outline_rounded,
                      onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text("Bu PDF resmi yayındır."),
                      backgroundColor: Colors.teal.withValues(alpha: 0.9),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  }),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5))
                    ]),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Stack(
                    children: [
                      // PDF Görüntüleyici
                      if (widget.hutbe.pdfUrl.isNotEmpty)
                        SfPdfViewer.network(
                          widget.hutbe.pdfUrl,
                          canShowScrollHead: false,
                          enableDoubleTapZooming: true,
                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                            setState(() {
                              _isLoading = false;
                            });
                          },
                          onDocumentLoadFailed:
                              (PdfDocumentLoadFailedDetails details) {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "PDF yüklenirken hata oluştu! Linki kontrol edin.")));
                          },
                        )
                      else
                        const Center(
                            child: Text("Geçerli bir PDF linki bulunamadı.",
                                style: TextStyle(color: Colors.black))),

                      // İndiriliyor Animasyonu
                      if (_isLoading && widget.hutbe.pdfUrl.isNotEmpty)
                        Container(
                          color: Colors.white,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: Colors.teal),
                                const SizedBox(height: 16),
                                Text("Hutbe İndiriliyor...",
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
