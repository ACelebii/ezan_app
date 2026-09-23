import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import '../../core/vakit/vakit_modelleri.dart';
import '../../core/vakit/vakit_servisi.dart';
import '../../core/widgets/glass_button.dart';
import '../../locator.dart';

class ImsakiyePage extends StatefulWidget {
  final VoidCallback? onBack;
  const ImsakiyePage({super.key, this.onBack});
  @override
  State<ImsakiyePage> createState() => _ImsakiyePageState();
}

class _ImsakiyePageState extends State<ImsakiyePage> {
  final _servis = locator<VakitServisi>();

  List<GunlukVakit> data = [];
  bool loading = true;
  String? errorMessage;
  String _lastCity = "";
  String? _sonKimlik;
  Konum? _konum;

  /// Konumun takvimine göre bugün; "bugün" vurgusu ve açılış ayı buna göre.
  DateTime? _bugun;
  int _seciliAy = DateTime.now().month;
  int _seciliYil = DateTime.now().year;

  /// Şehir ya da ay hızlıca değişirse eski isteğin geç gelen yanıtı yok sayılır.
  int _istek = 0;

  /// Vakitlerin hesaplandığı tercih; yöntem/ikindi/temkin değişince yenilenir.
  String? _sonTercih;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();
    final secili = authService.seciliSehir;

    // Değişimi ad değil kimlik algılar (aynı adlı iki yer olabilir).
    if (_sonKimlik != secili.kimlik) {
      _sonKimlik = secili.kimlik;
      _lastCity = secili.isim;
      _konum = secili.konum;
      final konum = _konum;
      if (konum != null) {
        // Açılış ayı: telefonun değil konumun bulunduğu ay.
        _bugun = _servis.bugun(konum);
        _seciliAy = _bugun!.month;
        _seciliYil = _bugun!.year;
      }
      _fetchMonth();
    } else if (_sonTercih != null &&
        _sonTercih != authService.vakitTercihi.ozet) {
      _fetchMonth();
    }
    _sonTercih = authService.vakitTercihi.ozet;
  }

  void _oncekiAy() {
    setState(() {
      if (_seciliAy == 1) {
        _seciliAy = 12;
        _seciliYil--;
      } else {
        _seciliAy--;
      }
    });
    _fetchMonth();
  }

  void _sonrakiAy() {
    setState(() {
      if (_seciliAy == 12) {
        _seciliAy = 1;
        _seciliYil++;
      } else {
        _seciliAy++;
      }
    });
    _fetchMonth();
  }

  Future<void> _fetchMonth() async {
    if (!mounted) return;
    final konum = _konum;
    if (konum == null) {
      setState(() {
        loading = false;
        errorMessage = "$_lastCity için imsakiye bulunamadı.";
      });
      return;
    }
    final istek = ++_istek;
    setState(() => loading = true);
    try {
      final tercih = context.read<AuthService>().vakitTercihi;
      final result =
          await _servis.ayVakitleri(konum, _seciliYil, _seciliAy, tercih);
      if (mounted && istek == _istek) {
        setState(() {
          data = result;
          loading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && istek == _istek) {
        setState(() {
          loading = false;
          errorMessage =
              "İmsakiye yüklenemedi. İnternet bağlantınızı kontrol edin.";
        });
      }
    }
  }

  /// Diyanet hicri tarihi "9 Rebiulahir 1448" → "9 Rebiulahir" (yıl gösterilmez).
  String? _hicri(GunlukVakit gun) {
    final parcalar = gun.hicriTarih?.split(' ');
    if (parcalar == null || parcalar.length < 3) return null;
    return parcalar.sublist(0, parcalar.length - 1).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    final authService = context.watch<AuthService>();
    // Kullanıcı bir hesaplama yöntemi seçtiyse bütün günler zaten o yöntemle
    // hesaplanmıştır; "Diyanet dışı" ayrımı yalnızca Diyanet Takvimi'nde anlamlı.
    final yontemSecili = authService.vakitTercihi.aladhanYontemi != null;
    final hesaplananVar =
        !yontemSecili && data.any((g) => g.kaynak != VakitKaynagi.diyanet);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            iconColor: textColor,
            size: 18,
            onTap: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (context.canPop()) {
                context.pop(); // Menüden geldiyse menüye dön
              } else {
                context.go('/'); // Alt menüden tıklandıysa ana sayfaya git
              }
            },
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(authService.translate("İmsakiye"),
            style: TextStyle(
                color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _oncekiAy,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.chevron_left_rounded,
                        color: textColor, size: 26),
                  ),
                ),
                Text(
                    "${authService.translate(_getMonthName(_seciliAy))} $_seciliYil",
                    style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                InkWell(
                  onTap: _sonrakiAy,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.chevron_right_rounded,
                        color: textColor, size: 26),
                  ),
                ),
              ],
            ),
          ),
          if (!loading && errorMessage == null && hesaplananVar)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                  authService.translate(
                      "Soluk yazılı günler Diyanet'ten değil, hesaplanmış vakitlerdir (1-2 dakika sapabilir)."),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor, fontSize: 11)),
            ),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(errorMessage!,
                                  textAlign: TextAlign.center,
                                  style:
                                      const TextStyle(color: Colors.redAccent)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchMonth,
                                child:
                                    Text(authService.translate("Tekrar Dene")),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final gun = data[index];
                          final isToday = gun.tarih == _bugun;
                          final hicri = _hicri(gun);
                          // Diyanet dışı (hesaplanmış) günler soluk gösterilir.
                          final soluk = !yontemSecili &&
                              gun.kaynak != VakitKaynagi.diyanet;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: isToday
                                    ? Border.all(color: Colors.orange, width: 2)
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            "${gun.tarih.day} ${authService.translate(_getMonthName(gun.tarih.month))}",
                                            style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                        if (hicri != null)
                                          Text(hicri,
                                              style: TextStyle(
                                                  color: subTextColor,
                                                  fontSize: 13)),
                                      ]),
                                  Divider(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.black12,
                                      height: 24),
                                  Opacity(
                                    opacity: soluk ? 0.55 : 1,
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          for (final vakit in Vakit.values)
                                            _vSutun(
                                                authService.translate(vakit.ad),
                                                gun.saatler[vakit]!,
                                                isDark),
                                        ]),
                                  ),
                                ])),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _vSutun(String b, String s, bool isDark) => Column(children: [
        Text(b,
            style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54, fontSize: 11)),
        const SizedBox(height: 6),
        Text(s,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ]);

  String _getMonthName(int month) {
    const months = [
      "",
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık"
    ];
    return months[month];
  }
}
