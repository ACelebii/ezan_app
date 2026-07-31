import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'
    hide TextDirection; // intl çakışma hatası çözüldü
import 'package:provider/provider.dart';
import '../auth/auth_service.dart';
import 'data/imsakiye_repository.dart';
import '../../core/widgets/glass_button.dart';

class ImsakiyePage extends StatefulWidget {
  final VoidCallback? onBack;
  const ImsakiyePage({super.key, this.onBack});
  @override
  State<ImsakiyePage> createState() => _ImsakiyePageState();
}

class _ImsakiyePageState extends State<ImsakiyePage> {
  List data = [];
  bool loading = true;
  String? errorMessage;
  String _lastCity = "";
  int _lastMethod = -1;

  int _seciliAy = DateTime.now().month;
  int _seciliYil = DateTime.now().year;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();
    final currentCity = authService.seciliSehir['isim'] ?? "İstanbul";
    final currentMethod = authService.apiMethod;

    if (_lastCity != currentCity || _lastMethod != currentMethod) {
      _lastCity = currentCity;
      _lastMethod = currentMethod;
      _fetchMonth();
    }
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
    setState(() => loading = true);
    try {
      final repo = ImsakiyeRepository(
        city: _lastCity,
        method: _lastMethod,
        month: _seciliAy,
        year: _seciliYil,
      );
      final result = await repo.getData();
      if (mounted) {
        setState(() {
          data = result;
          loading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = "İmsakiye yüklenemedi. İnternet bağlantınızı kontrol edin.";
        });
      }
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
                                child: Text(authService.translate("Tekrar Dene")),
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
                            color: Colors.black.withValues(alpha: 0.05),
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
