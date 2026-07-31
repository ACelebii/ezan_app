import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'settings_common.dart';

class CitiesPage extends StatefulWidget {
  const CitiesPage({super.key});
  @override
  State<CitiesPage> createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> {
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final sehirler = authService.kayitliSehirler;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          backgroundColor: getBgColor(context),
          elevation: 0,
          centerTitle: true,
          title: Text(authService.translate("Şehirler"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          actions: [
            TextButton(
                onPressed: () => setState(() => isEditing = !isEditing),
                child: Text(
                    isEditing
                        ? authService.translate("Bitti")
                        : authService.translate("Düzenle"),
                    style:
                        TextStyle(color: getTextColor(context), fontSize: 16))),
            IconButton(
                icon: Icon(Icons.add, color: getTextColor(context), size: 28),
                onPressed: () async {
                  context.push('/settings/cities/add-preview',
                      extra: "İstanbul");
                }),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                  color: getCardColor(context),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: sehirler.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var sehir = entry.value;
                  bool isSecili = sehir["secili"] == "true";

                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Icon(Icons.public,
                            color: getSubTextColor(context)),
                        title: Text(sehir["isim"]!,
                            style: TextStyle(
                                color: getTextColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w500)),
                        subtitle: Text(
                            "${authService.translate(sehir["sehir"] ?? "Türkiye")}\n${authService.translate(sehir["tur"])}",
                            style: TextStyle(
                                color: getSubTextColor(context),
                                fontSize: 13,
                                height: 1.3)),
                        trailing: isEditing
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  if (sehirler.length > 1) {
                                    List<dynamic> guncel = List.from(sehirler);
                                    guncel.removeAt(idx);
                                    // Silinen şehir seçiliyse, kalan
                                    // şehirlerden biri seçili işaretlenmezse
                                    // hiçbir şehir "aktif" görünmez (fallback
                                    // olarak sessizce ilk şehre dönülür, ama
                                    // liste bunu göstermez).
                                    if (isSecili && guncel.isNotEmpty) {
                                      guncel[0]["secili"] = "true";
                                    }
                                    authService.updateSetting(
                                        'kayitli_sehirler', guncel);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(authService.translate(
                                                "En az bir şehir kalmalıdır."))));
                                  }
                                })
                            : (isSecili
                                ? Icon(Icons.check,
                                    color: getAccentColor(context))
                                : null),
                        onTap: () {
                          if (!isEditing) {
                            List<dynamic> guncelListe = List.from(sehirler);
                            for (var s in guncelListe) {
                              s["secili"] = "false";
                            }
                            guncelListe[idx]["secili"] = "true";
                            authService.updateSetting(
                                'kayitli_sehirler', guncelListe);
                            context.pop();
                          }
                        },
                      ),
                      if (idx != sehirler.length - 1)
                        Divider(
                            color: getDividerColor(context),
                            height: 1,
                            indent: 50,
                            endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

