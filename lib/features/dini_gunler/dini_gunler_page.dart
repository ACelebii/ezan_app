import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';

// ============================================================================
// ORTAK ŞEFFAF BUTON TASARIMI
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

// ============================================================================
// DİNİ GÜNLER VERİTABANI (Eksiksiz 2026 Verisi Eklenmiş Halidir)
// ============================================================================
final List<Map<String, dynamic>> _diniGunlerVerisi = [
  // 2024 Örnekleri
  {
    "yil": 2024,
    "ay": "Ocak",
    "gunNo": "11",
    "gunAd": "Ocak\nPerşembe",
    "baslik": "Regaib Kandili",
    "hicri": "29 Cemaziyelahir 1445",
    "detay": "Regaib Kandili detayları..."
  },
  {
    "yil": 2024,
    "ay": "Şubat",
    "gunNo": "06",
    "gunAd": "Şubat\nSalı",
    "baslik": "Miraç Kandili",
    "hicri": "26 Recep 1445",
    "detay": "Miraç Kandili detayları..."
  },

  // 2025 Örnekleri
  {
    "yil": 2025,
    "ay": "Şubat",
    "gunNo": "13",
    "gunAd": "Şubat\nPerşembe",
    "baslik": "Berat Kandili",
    "hicri": "14 Şaban 1446",
    "detay": "Berat Kandili detayları..."
  },
  {
    "yil": 2025,
    "ay": "Mart",
    "gunNo": "01",
    "gunAd": "Mart\nCumartesi",
    "baslik": "Ramazan'ın İlk Günü",
    "hicri": "1 Ramazan 1446",
    "detay": "On bir ayın sultanı Ramazan..."
  },

  // 2026 (TÜM YIL EKSİKSİZ VERİ)
  {
    "yil": 2026,
    "ay": "Ocak",
    "gunNo": "15",
    "gunAd": "Ocak\nPerşembe",
    "baslik": "Miraç Kandili",
    "hicri": "26 Recep 1447",
    "detay":
        "Kandiller; ışıklarıyla sadece karanlık gecelerimizi değil, aynı zamanda manevi feyziyle de daralan gönüllerimizi aydınlatan, zihinlerimizi berraklaştıran gecelerdir...\n\nÖze dönüşün, Yüce Yaratanımıza yürekten yakarış ve yönelişin kutlu zaman dilimleridir."
  },
  {
    "yil": 2026,
    "ay": "Şubat",
    "gunNo": "02",
    "gunAd": "Şubat\nPazartesi",
    "baslik": "Berat Kandili",
    "hicri": "14 Şaban 1447",
    "detay":
        "Berat Kandili, günahlardan arınma ve temize çıkma gecesidir. Allah'ın rahmetinin yeryüzüne tecelli ettiği, bağışlanma kapılarının ardına kadar açıldığı mübarek bir gecedir."
  },
  {
    "yil": 2026,
    "ay": "Şubat",
    "gunNo": "18",
    "gunAd": "Şubat\nÇarşamba",
    "baslik": "Ramazan'ın İlk Günü",
    "hicri": "1 Ramazan 1447",
    "detay":
        "Rahmet, bereket ve mağfiret ayı olan Ramazan ayının başlangıcı. Kur'an-ı Kerim'in indirilmeye başlandığı, oruç ibadetinin yerine getirildiği mübarek ay."
  },
  {
    "yil": 2026,
    "ay": "Mart",
    "gunNo": "16",
    "gunAd": "Mart\nPazartesi",
    "baslik": "Kadir Gecesi",
    "hicri": "26 Ramazan 1447",
    "detay":
        "Bin aydan daha hayırlı olan Kadir Gecesi. Yüce kitabımız Kur'an-ı Kerim'in Peygamber Efendimize (s.a.v) indirilmeye başlandığı, meleklerin yeryüzüne indiği eşsiz bir gecedir."
  },
  {
    "yil": 2026,
    "ay": "Mart",
    "gunNo": "20",
    "gunAd": "Mart\nCuma",
    "baslik": "Ramazan Bayramı",
    "hicri": "1 Şevval 1447",
    "detay":
        "Başı rahmet, ortası mağfiret, sonu cehennem azabından kurtuluş olan Ramazan ayını geride bırakarak kavuştuğumuz mübarek Ramazan Bayramı."
  },
  {
    "yil": 2026,
    "ay": "Mayıs",
    "gunNo": "27",
    "gunAd": "Mayıs\nÇarşamba",
    "baslik": "Kurban Bayramı",
    "hicri": "10 Zilhicce 1447",
    "detay":
        "Hz. İbrahim'in itaatini ve Hz. İsmail'in teslimiyetini hatırlatan, paylaşmanın ve yardımlaşmanın zirveye ulaştığı mübarek Kurban Bayramı."
  },
  {
    "yil": 2026,
    "ay": "Haziran",
    "gunNo": "16",
    "gunAd": "Haziran\nSalı",
    "baslik": "Hicri Yılbaşı",
    "hicri": "1 Muharrem 1448",
    "detay":
        "Peygamber Efendimiz Hz. Muhammed'in (s.a.v) Mekke'den Medine'ye hicretini esas alan Hicri takvimin ilk günü ve yeni yılın başlangıcı."
  },
  {
    "yil": 2026,
    "ay": "Haziran",
    "gunNo": "25",
    "gunAd": "Haziran\nPerşembe",
    "baslik": "Aşure Günü",
    "hicri": "10 Muharrem 1448",
    "detay":
        "Muharrem ayının onuncu günü olan Aşure Günü, tarihte birçok önemli hadisenin yaşandığı, paylaşmanın, dayanışmanın ve birlikteliğin simgesidir."
  },
  {
    "yil": 2026,
    "ay": "Ağustos",
    "gunNo": "24",
    "gunAd": "Ağustos\nPazartesi",
    "baslik": "Mevlid Kandili",
    "hicri": "12 Rebiülevvel 1448",
    "detay":
        "İnsanlığı karanlıktan aydınlığa çıkaran, rahmet elçisi Peygamber Efendimiz Hz. Muhammed'in (s.a.v) yeryüzünü şereflendirdiği veladet gecesidir."
  }
];

// ============================================================================
// 1. ANA LİSTE SAYFASI
// ============================================================================
class DiniGunlerPage extends StatefulWidget {
  const DiniGunlerPage({super.key});

  @override
  State<DiniGunlerPage> createState() => _DiniGunlerPageState();
}

class _DiniGunlerPageState extends State<DiniGunlerPage> {
  int _seciliYil = 2026; // Varsayılan açılış yılı
  final List<int> _yillar = [2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027];

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black;

    // Seçili yıla göre veriyi filtrele ve aylara göre grupla
    var yillikVeri =
        _diniGunlerVerisi.where((e) => e['yil'] == _seciliYil).toList();

    // Aynı ayda olan günleri bir araya toplayan mantık
    Map<String, List<Map<String, dynamic>>> gruplanmisVeri = {};
    for (var item in yillikVeri) {
      gruplanmisVeri.putIfAbsent(item['ay'], () => []).add(item);
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst Bar (Geri ve Takvim Butonu)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),

                  // Yıl Seçici Popup Menü
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.white24 : Colors.black12),
                    ),
                    child: PopupMenuButton<int>(
                      icon: Icon(Icons.calendar_month_rounded,
                          color: textColor, size: 20),
                      offset: const Offset(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      onSelected: (yil) => setState(() => _seciliYil = yil),
                      itemBuilder: (context) => _yillar.map((yil) {
                        return PopupMenuItem<int>(
                          value: yil,
                          child: Row(
                            children: [
                              if (_seciliYil == yil)
                                const Icon(Icons.check,
                                    size: 18, color: Colors.blue)
                              else
                                const SizedBox(width: 18),
                              const SizedBox(width: 12),
                              Text(yil.toString(),
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: _seciliYil == yil
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Büyük Başlık
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                "${authService.translate("Dini Günler")} $_seciliYil",
                style: TextStyle(
                    color: textColor,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5),
              ),
            ),

            // Gruplanmış Liste
            Expanded(
              child: gruplanmisVeri.isEmpty
                  ? Center(
                      child: Text("Bu yıla ait veri bulunamadı.",
                          style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: gruplanmisVeri.keys.length,
                      itemBuilder: (context, index) {
                        String ayAdi = gruplanmisVeri.keys.elementAt(index);
                        List<Map<String, dynamic>> oAyinGunleri =
                            gruplanmisVeri[ayAdi]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ay Başlığı (Ocak, Şubat vb.)
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16.0, bottom: 12.0),
                              child: Text(
                                authService.translate(ayAdi),
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),

                            // O aya ait günlerin kartları
                            Container(
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
                                                  .withOpacity(0.03),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ]),
                              child: Column(
                                children:
                                    oAyinGunleri.asMap().entries.map((entry) {
                                  int i = entry.key;
                                  var gun = entry.value;
                                  bool isLast = i == oAyinGunleri.length - 1;

                                  return Column(
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(
                                            isLast ? 20 : 0),
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    DiniGunDetayPage(
                                                        gunData: gun))),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16.0, horizontal: 16.0),
                                          child: Row(
                                            children: [
                                              // SOL KISIM (Tarih ve Gün)
                                              SizedBox(
                                                width: 80,
                                                child: Column(
                                                  children: [
                                                    Text(gun['gunNo'],
                                                        style: TextStyle(
                                                            color: textColor,
                                                            fontSize: 26,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            height: 1.0)),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                        authService.translate(
                                                            gun['gunAd']),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors.grey
                                                                    .shade500,
                                                            fontSize: 12)),
                                                  ],
                                                ),
                                              ),

                                              // DİKEY KESİK ÇİZGİ
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10),
                                                width: 1,
                                                height: 45,
                                                color: isDark
                                                    ? Colors.white24
                                                    : Colors.grey.shade300,
                                              ),

                                              // SAĞ KISIM (Başlık ve Hicri)
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        authService.translate(
                                                            gun['baslik']),
                                                        style: const TextStyle(
                                                            color: Color(
                                                                0xFF6B4C7A),
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                    const SizedBox(height: 4),
                                                    Text(gun['hicri'],
                                                        style: TextStyle(
                                                            color: isDark
                                                                ? Colors.white54
                                                                : Colors.grey
                                                                    .shade500,
                                                            fontSize: 13)),
                                                  ],
                                                ),
                                              ),

                                              Icon(
                                                  Icons
                                                      .arrow_forward_ios_rounded,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : Colors.grey.shade400,
                                                  size: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (!isLast)
                                        Divider(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.grey.shade200,
                                            height: 1,
                                            indent: 110),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. DETAY SAYFASI
// ============================================================================
class DiniGunDetayPage extends StatelessWidget {
  final Map<String, dynamic> gunData;
  const DiniGunDetayPage({super.key, required this.gunData});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final authService = context.watch<AuthService>();
    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  _buildGlassButton(context,
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context)),
                  Expanded(
                    child: Center(
                      child: Text(
                        authService.translate(gunData['baslik']),
                        style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Ortalamak için boşluk
                ],
              ),
            ),

            const SizedBox(height: 10),

            // İçerik Kartı
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2))
                          ]),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authService.translate(gunData['detay']),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade800,
                          fontSize: 16,
                          height: 1.6, // Satır arası boşluk
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
