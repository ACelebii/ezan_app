import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';
import '../../core/vakit/il_kodlari.dart';
import '../../core/vakit/kayitli_sehir.dart';
import '../../core/vakit/vakit_modelleri.dart';
import '../../core/vakit/vakit_servisi.dart';
import '../../locator.dart';

class AddCityPreviewPage extends StatefulWidget {
  final String baslangicSehri;
  const AddCityPreviewPage({super.key, required this.baslangicSehri});
  @override
  State<AddCityPreviewPage> createState() => _AddCityPreviewPageState();
}

class _AddCityPreviewPageState extends State<AddCityPreviewPage> {
  late String _gosterilenSehir;

  /// Dünya listesinden seçilen yer; Türkiye'deki il için null (il adından
  /// bulunur).
  Konum? _yabanciKonum;
  int _istek = 0;
  bool isLoading = true;
  bool hasError = false;
  Map<String, String> vakitler = {};

  String _seciliYontem = "Diyanet Takvimi";
  final List<String> hesaplamaSecenekleri = [
    "Diyanet Takvimi",
    "Kuzey Amerika (ISNA)",
    "Müslim World Lig",
    "Mısır",
    "Karaçi İslami İlimler Üniversitesi",
    "Ummül Kurra",
    "Tahran Üniversitesi",
    "ITNA Ashari, Caferi",
    "UOIF Fransa İslam Organizasyon Birliği",
    "JAKIM (Malezya)"
  ];

  @override
  void initState() {
    super.initState();
    _gosterilenSehir = widget.baslangicSehri;
    // Mevcut global hesaplama yöntemiyle başlat; aksi halde kullanıcı bu
    // seçiciye hiç dokunmasa bile "Kaydet" sabit "Diyanet Takvimi"
    // varsayılanını yazıp global ayarı sessizce sıfırlıyordu.
    _seciliYontem = context.read<AuthService>().hesaplamaYontemi;
    _fetchVakitler(_gosterilenSehir);
  }

  /// Şehrin bugünkü vakitlerini (Diyanet, olmazsa Aladhan) önizleme için yükler.
  Future<void> _fetchVakitler(String sehir) async {
    final istek = ++_istek;
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final konum = _yabanciKonum ?? kayittanKonum({'isim': sehir});
      if (konum == null) throw VakitHatasi('$sehir için Diyanet kodu yok.');
      final servis = locator<VakitServisi>();
      final bugun = servis.bugun(konum);
      // Seçili (henüz kaydedilmemiş) yöntemle; ikindi ve temkin mevcut ayarlar.
      final tercih =
          context.read<AuthService>().vakitTercihiIcin(_seciliYontem);
      final gunler = await servis.vakitleriGetir(konum, tercih);
      final gun = gunler.firstWhere((g) => g.tarih == bugun);
      if (!mounted || istek != _istek) return;
      setState(() {
        vakitler = {for (final v in Vakit.values) v.ad: gun.saatler[v]!};
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Şehir vakitleri alınamadı ($sehir): $e");
      if (!mounted || istek != _istek) return;
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _showYontemDialog() {
    final authService = context.read<AuthService>();
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: authService.uygulamaDili == "العربية"
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: Dialog(
            backgroundColor: getCardColor(context),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: hesaplamaSecenekleri.length,
                itemBuilder: (context, index) {
                  bool isSelected =
                      hesaplamaSecenekleri[index] == _seciliYontem;
                  return ListTile(
                    leading: isSelected
                        ? Icon(Icons.check,
                            color: getAccentColor(context), size: 20)
                        : const SizedBox(width: 20),
                    title: Text(
                        authService.translate(hesaplamaSecenekleri[index]),
                        style: TextStyle(
                            color: isSelected
                                ? getAccentColor(context)
                                : getTextColor(context),
                            fontSize: 16)),
                    onTap: () {
                      setState(
                          () => _seciliYontem = hesaplamaSecenekleri[index]);
                      Navigator.pop(context);
                      _fetchVakitler(_gosterilenSehir);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate("Yeni Şehir Ekle"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          actions: [
            TextButton(
                onPressed: () {
                  final konum = _yabanciKonum ??
                      kayittanKonum({'isim': _gosterilenSehir});
                  if (konum == null) return;
                  // Aynı yer (kimliği aynı) zaten kayıtlıysa tekrar eklenmez,
                  // yalnızca seçilir.
                  authService.sehirleriKaydet(
                      authService.kayitliSehirler.ekleyipSecerek(KayitliSehir(
                    isim: _gosterilenSehir,
                    ulke: _yabanciKonum?.ulke ?? "Türkiye",
                    tur: _seciliYontem,
                    konum: konum,
                  )));
                  authService.updateSetting('hesaplama_yontemi', _seciliYontem);
                  context.pop();
                  context.pop();
                },
                child: Text(authService.translate("Kaydet"),
                    style:
                        TextStyle(color: getTextColor(context), fontSize: 16))),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: getCardColor(context),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_gosterilenSehir,
                                style: TextStyle(
                                    color: getTextColor(context),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                            // Yabancı yerde saat dilimi de yazılır: yanlış bulunmuşsa
                            // kullanıcı kaydetmeden fark edebilsin.
                            Text(
                                _yabanciKonum == null
                                    ? authService.translate("Türkiye")
                                    : '${_yabanciKonum!.ulke} · ${_yabanciKonum!.saatDilimi}',
                                style: TextStyle(
                                    color: getSubTextColor(context),
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      TextButton(
                          onPressed: () async {
                            final yeniArama = await context
                                .push<Object>('/settings/cities/search');
                            if (yeniArama is Konum) {
                              setState(() {
                                _yabanciKonum = yeniArama;
                                _gosterilenSehir = yeniArama.ad;
                              });
                            } else if (yeniArama is String) {
                              setState(() {
                                _yabanciKonum = null;
                                _gosterilenSehir = yeniArama;
                              });
                            } else {
                              return;
                            }
                            _fetchVakitler(_gosterilenSehir);
                          },
                          child: Text(authService.translate("Değiştir"),
                              style: TextStyle(
                                  color: getTextColor(context), fontSize: 14))),
                    ],
                  ),
                  if (_yabanciKonum != null &&
                      _yabanciKonum!.diyanetIlceId == null) ...[
                    // GPS ile bulunan ve Diyanet'in listesinde karşılığı olmayan yer.
                    const SizedBox(height: 8),
                    Text(
                        authService.translate(
                            "Bu yer için Diyanet saati yok; vakitler koordinata göre hesaplanır (Diyanet yöntemiyle, birkaç dakika sapabilir)."),
                        style: TextStyle(
                            color: getSubTextColor(context), fontSize: 12)),
                  ],
                  const SizedBox(height: 24),
                  if (isLoading)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                                color: getAccentColor(context))))
                  else if (hasError)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                                authService
                                    .translate("Şehir bilgileri alınamadı."),
                                style:
                                    const TextStyle(color: Colors.redAccent))))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TimeColumn(
                            title: authService.translate("İmsak"),
                            time: vakitler["İmsak"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Güneş"),
                            time: vakitler["Güneş"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Öğle"),
                            time: vakitler["Öğle"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("İkindi"),
                            time: vakitler["İkindi"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Akşam"),
                            time: vakitler["Akşam"] ?? "--:--"),
                        _TimeColumn(
                            title: authService.translate("Yatsı"),
                            time: vakitler["Yatsı"] ?? "--:--"),
                      ],
                    )
                ],
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _showYontemDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: getCardColor(context),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(authService.translate("Hesaplama Yöntemi"),
                            style: TextStyle(
                                color: getTextColor(context), fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(authService.translate(_seciliYontem),
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 14))
                      ],
                    ),
                    Row(children: [
                      Icon(Icons.mosque_outlined,
                          color: getTextColor(context), size: 24),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios,
                          color:
                              isDark(context) ? Colors.white24 : Colors.black26,
                          size: 14)
                    ])
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String title;
  final String time;

  const _TimeColumn({required this.title, required this.time});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Column(
      children: [
        Text(authService.translate(title),
            style: TextStyle(color: getSubTextColor(context), fontSize: 13)),
        const SizedBox(height: 6),
        Text(time,
            style: TextStyle(
                color: getTextColor(context),
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
