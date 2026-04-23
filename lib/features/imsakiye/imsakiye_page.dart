import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'
    hide TextDirection; // intl çakışma hatası çözüldü
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'main.dart'; // Vakitler sayfasına dönebilmek için eklendi

class ImsakiyePage extends StatefulWidget {
  const ImsakiyePage({super.key});
  @override
  State<ImsakiyePage> createState() => _ImsakiyePageState();
}

class _ImsakiyePageState extends State<ImsakiyePage> {
  List data = [];
  bool loading = true;
  String _lastCity = "";
  int _lastMethod = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();
    final currentCity = authService.seciliSehir['isim'] ?? "İstanbul";
    final currentMethod = authService.apiMethod;

    if (_lastCity != currentCity || _lastMethod != currentMethod) {
      _lastCity = currentCity;
      _lastMethod = currentMethod;
      _fetch30Days(currentCity, currentMethod);
    }
  }

  Future<void> _fetch30Days(String city, int method) async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      DateTime now = DateTime.now();

      int currentMonth = now.month;
      int currentYear = now.year;

      int nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
      int nextYear = currentMonth == 12 ? currentYear + 1 : currentYear;

      String url1 =
          'https://api.aladhan.com/v1/calendarByCity?city=$city&country=Turkey&method=$method&month=$currentMonth&year=$currentYear';
      String url2 =
          'https://api.aladhan.com/v1/calendarByCity?city=$city&country=Turkey&method=$method&month=$nextMonth&year=$nextYear';

      final responses = await Future.wait([
        http.get(Uri.parse(url1)),
        http.get(Uri.parse(url2)),
      ]);

      if (responses[0].statusCode == 200 &&
          responses[1].statusCode == 200 &&
          mounted) {
        List data1 = json.decode(responses[0].body)['data'];
        List data2 = json.decode(responses[1].body)['data'];

        List combinedData = [...data1, ...data2];

        String todayStr = DateFormat('dd-MM-yyyy').format(now);
        int todayIndex = combinedData
            .indexWhere((day) => day['date']['gregorian']['date'] == todayStr);
        if (todayIndex == -1) todayIndex = 0;

        int endIndex = todayIndex + 30;
        if (endIndex > combinedData.length) endIndex = combinedData.length;

        setState(() {
          data = combinedData.sublist(todayIndex, endIndex);
          loading = false;
        });
      } else {
        if (mounted) setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? Colors.black : const Color(0xFFF2F2F7);
    Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color subTextColor = isDark ? Colors.white54 : Colors.black54;

    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Menüden geldiyse menüye dön
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MainNavigationPage()),
                  (route) => false, // Alt menüden tıklandıysa ana sayfaya git
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: isDark ? Colors.white24 : Colors.black12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: textColor, size: 18),
            ),
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(authService.translate("İmsakiye"),
            style: TextStyle(
                color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, index) {
                var dayData = data[index];
                var date = dayData['date'];
                var timings = dayData['timings'];
                bool isToday = date['gregorian']['date'] ==
                    DateFormat('dd-MM-yyyy').format(DateTime.now());

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
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  "${date['gregorian']['day']} ${authService.translate(_getMonthName(date['gregorian']['month']['number']))}",
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(
                                  "${date['hijri']['day']} ${authService.translate(date['hijri']['month']['en'])}",
                                  style: TextStyle(
                                      color: subTextColor, fontSize: 13)),
                            ]),
                        Divider(
                            color: isDark ? Colors.white12 : Colors.black12,
                            height: 24),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _vSutun(authService.translate("İmsak"),
                                  timings['Fajr'], isDark),
                              _vSutun(authService.translate("Güneş"),
                                  timings['Sunrise'], isDark),
                              _vSutun(authService.translate("Öğle"),
                                  timings['Dhuhr'], isDark),
                              _vSutun(authService.translate("İkindi"),
                                  timings['Asr'], isDark),
                              _vSutun(authService.translate("Akşam"),
                                  timings['Maghrib'], isDark),
                              _vSutun(authService.translate("Yatsı"),
                                  timings['Isha'], isDark),
                            ]),
                      ])),
                );
              },
            ),
    );
  }

  Widget _vSutun(String b, String s, bool isDark) => Column(children: [
        Text(b,
            style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54, fontSize: 11)),
        const SizedBox(height: 6),
        Text(s.split(' ')[0],
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
