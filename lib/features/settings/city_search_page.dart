import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

class CitySearchPage extends StatefulWidget {
  const CitySearchPage({super.key});
  @override
  State<CitySearchPage> createState() => _CitySearchPageState();
}

class _CitySearchPageState extends State<CitySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _tumSehirler = [
    "Adana",
    "Adıyaman",
    "Afyonkarahisar",
    "Ağrı",
    "Amasya",
    "Ankara",
    "Antalya",
    "Artvin",
    "Aydın",
    "Balıkesir",
    "Bilecik",
    "Bingöl",
    "Bitlis",
    "Bolu",
    "Burdur",
    "Bursa",
    "Çanakkale",
    "Çankırı",
    "Çorum",
    "Denizli",
    "Diyarbakır",
    "Edirne",
    "Elazığ",
    "Erzincan",
    "Erzurum",
    "Eskişehir",
    "Gaziantep",
    "Giresun",
    "Gümüşhane",
    "Hakkari",
    "Hatay",
    "Isparta",
    "Mersin",
    "İstanbul",
    "İzmir",
    "Kars",
    "Kastamonu",
    "Kayseri",
    "Kırklareli",
    "Kırşehir",
    "Kocaeli",
    "Konya",
    "Kütahya",
    "Malatya",
    "Manisa",
    "Kahramanmaraş",
    "Mardin",
    "Muğla",
    "Muş",
    "Nevşehir",
    "Niğde",
    "Ordu",
    "Rize",
    "Sakarya",
    "Samsun",
    "Siirt",
    "Sinop",
    "Sivas",
    "Tekirdağ",
    "Tokat",
    "Trabzon",
    "Tunceli",
    "Şanlıurfa",
    "Uşak",
    "Van",
    "Yozgat",
    "Zonguldak",
    "Aksaray",
    "Bayburt",
    "Karaman",
    "Kırıkkale",
    "Batman",
    "Şırnak",
    "Bartın",
    "Ardahan",
    "Iğdır",
    "Yalova",
    "Karabük",
    "Kilis",
    "Osmaniye",
    "Düzce"
  ];
  List<String> _filtrelenmisSehirler = [];

  void _sehirFiltrele(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtrelenmisSehirler = [];
      } else {
        _filtrelenmisSehirler = _tumSehirler
            .where((sehir) => sehir.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getCardColor(context),
        appBar: AppBar(
            leading: buildBeautifulBackButton(context),
            backgroundColor: getCardColor(context),
            elevation: 0),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(authService.translate("Ara"),
                    style: TextStyle(
                        color: getTextColor(context),
                        fontSize: 34,
                        fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: getTextColor(context)),
                autofocus: false,
                onChanged: _sehirFiltrele,
                decoration: InputDecoration(
                    hintText: authService.translate("Ara"),
                    hintStyle: TextStyle(color: getSubTextColor(context)),
                    prefixIcon:
                        Icon(Icons.search, color: getSubTextColor(context)),
                    filled: true,
                    fillColor: getTextFieldColor(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0)),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    context.pop(value.trim());
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _filtrelenmisSehirler.length,
                separatorBuilder: (context, index) => Divider(
                    color: getDividerColor(context), height: 1, indent: 16),
                itemBuilder: (context, index) {
                  return ListTile(
                      title: Text(_filtrelenmisSehirler[index],
                          style: TextStyle(color: getTextColor(context))),
                      onTap: () =>
                          context.pop(_filtrelenmisSehirler[index]));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

