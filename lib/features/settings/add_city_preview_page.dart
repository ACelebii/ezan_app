import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'settings_common.dart';

class AddCityPreviewPage extends StatefulWidget {
  final String baslangicSehri;
  const AddCityPreviewPage({super.key, required this.baslangicSehri});
  @override
  State<AddCityPreviewPage> createState() => _AddCityPreviewPageState();
}

class _AddCityPreviewPageState extends State<AddCityPreviewPage> {
  late String _gosterilenSehir;
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
    "Mısır (BIS)",
    "Temkinli Takvim",
    "JAKIM (Malezya)"
  ];

  @override
  void initState() {
    super.initState();
    _gosterilenSehir = widget.baslangicSehri;
    _fetchVakitler(_gosterilenSehir);
  }

  int _getApiMethodId(String method) {
    switch (method) {
      case "Kuzey Amerika (ISNA)":
        return 2;
      case "Müslim World Lig":
        return 3;
      case "Ummül Kurra":
        return 4;
      case "Mısır":
        return 5;
      case "Tahran Üniversitesi":
        return 7;
      case "Diyanet Takvimi":
        return 13;
      default:
        return 13;
    }
  }

  Future<void> _fetchVakitler(String sehir) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      int methodId = _getApiMethodId(_seciliYontem);
      final url =
          'https://api.aladhan.com/v1/timingsByCity?city=$sehir&country=Turkey&method=$methodId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data']['timings'];
        setState(() {
          vakitler = {
            "İmsak": data['Imsak'],
            "Güneş": data['Sunrise'],
            "Öğle": data['Dhuhr'],
            "İkindi": data['Asr'],
            "Akşam": data['Maghrib'],
            "Yatsı": data['Isha']
          };
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
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
                  List<dynamic> guncelListe =
                      List.from(authService.kayitliSehirler);
                  bool sehirZatenVar =
                      guncelListe.any((s) => s['isim'] == _gosterilenSehir);
                  for (var s in guncelListe) {
                    s["secili"] = "false";
                  }

                  if (sehirZatenVar) {
                    guncelListe.firstWhere(
                            (s) => s['isim'] == _gosterilenSehir)['secili'] =
                        'true';
                  } else {
                    guncelListe.add({
                      "isim": _gosterilenSehir,
                      "sehir": "Türkiye",
                      "tur": _seciliYontem,
                      "secili": "true"
                    });
                  }
                  authService.updateSetting('kayitli_sehirler', guncelListe);
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
                            Text(authService.translate("Türkiye"),
                                style: TextStyle(
                                    color: getSubTextColor(context),
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                      TextButton(
                          onPressed: () async {
                            final yeniArama = await context
                                .push<String>('/settings/cities/search');
                            if (yeniArama != null) {
                              setState(() => _gosterilenSehir = yeniArama);
                              _fetchVakitler(_gosterilenSehir);
                            }
                          },
                          child: Text(authService.translate("Değiştir"),
                              style: TextStyle(
                                  color: getTextColor(context), fontSize: 14))),
                    ],
                  ),
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
