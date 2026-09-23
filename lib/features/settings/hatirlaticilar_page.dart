import '../../core/i18n/cevir.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'settings_common.dart';
import '../../core/services/notification_service.dart';
import '../hatirlaticilar/data/reminder_scheduler.dart';
import '../hatirlaticilar/data/reminder_sound.dart';

class HatirlaticilarPage extends StatefulWidget {
  const HatirlaticilarPage({super.key});
  @override
  State<HatirlaticilarPage> createState() => _HatirlaticilarPageState();
}

class _HatirlaticilarPageState extends State<HatirlaticilarPage>
    with WidgetsBindingObserver {
  PermissionStatus? _bildirimIzni;

  /// Android 12+ "Alarmlar ve hatırlatıcılar" izni; null = henüz okunmadı.
  bool? _tamZamanliIzin;

  /// Pil optimizasyonu bu uygulamayı kısıtlamıyor mu; null = henüz okunmadı.
  bool? _pilIzni;
  bool _ramazanVerisiYok = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _izinDurumunuYenile();
    _ramazanVerisiniKontrolEt();
  }

  // dini_gunler.json içinde bulunduğumuz/gelecek Ramazan için veri yoksa
  // (ör. veri seti gelecek yıllar için henüz güncellenmediyse), "Ramazan
  // Davulcusu" açık görünse bile arka planda sessizce hiçbir şey
  // planlanmaz; bunu kullanıcıya açıkça bildiriyoruz.
  Future<void> _ramazanVerisiniKontrolEt() async {
    final window = await ReminderScheduler.currentRamadanWindow();
    if (mounted) setState(() => _ramazanVerisiYok = window == null);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kullanıcı sistem ayarlarından izin verip uygulamaya geri döndüğünde
    // banner'ın otomatik kaybolması için.
    if (state == AppLifecycleState.resumed) _izinDurumunuYenile();
  }

  Future<void> _izinDurumunuYenile() async {
    final durum = await NotificationService.instance.permissionStatus();
    final tamZamanli =
        await NotificationService.instance.tamZamanliBildirimIzniVar();
    final pil =
        await NotificationService.instance.pilOptimizasyonuYoksayiliyorMu();
    if (mounted) {
      setState(() {
        _bildirimIzni = durum;
        _tamZamanliIzin = tamZamanli;
        _pilIzni = pil;
      });
    }
  }

  // Sistemin "Alarmlar ve hatırlatıcılar" ekranını açar; kullanıcı dönünce
  // bildirimler tam zamanlı olarak yeniden kurulsun diye zamanlayıcı çalışır.
  // Reddederse bildirimler yaklaşık modda kalır (birkaç dakika gecikebilir).
  Future<void> _tamZamanliIzinIste(AuthService authService) async {
    final verildi =
        await NotificationService.instance.tamZamanliBildirimIzniIste();
    if (!mounted) return;
    setState(() => _tamZamanliIzin = verildi);
    if (verildi) ReminderScheduler.rescheduleAll(authService);
  }

  // Sistemin "Pil optimizasyonunu yoksay" ekranını açar. Reddederse arka
  // plan bildirim yenilemesi (12 saatte bir) Android tarafından geciktirilebilir
  // ya da hiç çalışmayabilir; ezan bildirimlerinin kendisi bundan etkilenmez.
  Future<void> _pilIzinIste() async {
    final verildi =
        await NotificationService.instance.pilOptimizasyonuYoksaymayiIste();
    if (mounted) setState(() => _pilIzni = verildi);
  }

  Future<void> _izinIste() async {
    if (_bildirimIzni?.isPermanentlyDenied == true) {
      await openAppSettings();
      return;
    }
    final durum = await NotificationService.instance.requestPermissions();
    if (mounted) setState(() => _bildirimIzni = durum);
  }

  List<String> get _timeOptions =>
      List.generate(14, (i) => "${(i + 1) * 5} Dakika Önce");

  String _offsetToLabel(int minutes) => "$minutes Dakika Önce";
  int _labelToOffset(String label) => int.parse(label.split(' ').first);

  // Bir hatırlatıcı açılırken bildirim izni yoksa önce izin ister; izin
  // verilmezse anahtar açılmaz (üstteki banner zaten sebebini gösteriyor).
  // Kapatma her zaman doğrudan uygulanır, izin gerekmez.
  Future<void> _anahtarDegisti(
      AuthService authService, String tur, bool acik) async {
    if (acik && _bildirimIzni?.isGranted != true) {
      await _izinIste();
      if (_bildirimIzni?.isGranted != true) {
        if (mounted && _bildirimIzni?.isPermanentlyDenied != true) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(authService.translate(
                  "Hatırlatıcının çalışması için bildirim izni gerekir."))));
        }
        return;
      }
    }
    _guncelle(authService, tur, (m) => {...m, 'enabled': acik});
  }

  void _guncelle(AuthService authService, String tur,
      Map<String, dynamic> Function(Map<String, dynamic> mevcut) degistir) {
    final guncelAyarlar =
        Map<String, dynamic>.from(authService.hatirlaticiAyarlari);
    guncelAyarlar[tur] =
        degistir(Map<String, dynamic>.from(guncelAyarlar[tur] as Map));
    authService.updateSetting('hatirlaticilar', guncelAyarlar);
    ReminderScheduler.rescheduleAll(authService);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final ayarlar = authService.hatirlaticiAyarlari;
    final cuma = ayarlar['cuma'] as Map;
    final oruc = ayarlar['oruc'] as Map;
    final teheccut = ayarlar['teheccut'] as Map;
    final ramazan = ayarlar['ramazan'] as Map;

    return Directionality(
      textDirection: authService.uygulamaDili == "العربية"
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: getBgColor(context),
        appBar: AppBar(
          leading: buildBeautifulBackButton(context),
          title: Text(authService.translate("Hatırlatıcılar"),
              style: TextStyle(
                  color: getTextColor(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          backgroundColor: getBgColor(context),
          centerTitle: true,
          elevation: 0,
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildPermissionBanner(authService),
            _buildHatirlaticiCard(
                authService,
                "Cuma Namazı Hatırlatma",
                "Cumadan",
                cuma['enabled'] as bool,
                (v) => _anahtarDegisti(authService, 'cuma', v),
                _offsetToLabel(cuma['offset'] as int),
                (s) => _guncelle(authService, 'cuma',
                    (m) => {...m, 'offset': _labelToOffset(s)}),
                cuma['sound'] as String,
                (key) => _guncelle(
                    authService, 'cuma', (m) => {...m, 'sound': key})),
            const SizedBox(height: 20),
            _buildHatirlaticiCard(
                authService,
                "Pazartesi/Perşembe Orucu",
                "İmsaktan",
                oruc['enabled'] as bool,
                (v) => _anahtarDegisti(authService, 'oruc', v),
                _offsetToLabel(oruc['offset'] as int),
                (s) => _guncelle(authService, 'oruc',
                    (m) => {...m, 'offset': _labelToOffset(s)}),
                oruc['sound'] as String,
                (key) => _guncelle(
                    authService, 'oruc', (m) => {...m, 'sound': key})),
            const SizedBox(height: 20),
            _buildHatirlaticiCard(
                authService,
                "Teheccüt Uyandırması",
                "İmsaktan",
                teheccut['enabled'] as bool,
                (v) => _anahtarDegisti(authService, 'teheccut', v),
                _offsetToLabel(teheccut['offset'] as int),
                (s) => _guncelle(authService, 'teheccut',
                    (m) => {...m, 'offset': _labelToOffset(s)}),
                teheccut['sound'] as String,
                (key) => _guncelle(
                    authService, 'teheccut', (m) => {...m, 'sound': key})),
            const SizedBox(height: 20),
            _buildHatirlaticiCard(
                authService,
                "Ramazan Davulcusu",
                "İmsaktan",
                ramazan['enabled'] as bool,
                (v) => _anahtarDegisti(authService, 'ramazan', v),
                _offsetToLabel(ramazan['offset'] as int),
                (s) => _guncelle(authService, 'ramazan',
                    (m) => {...m, 'offset': _labelToOffset(s)}),
                ramazan['sound'] as String,
                (key) => _guncelle(
                    authService, 'ramazan', (m) => {...m, 'sound': key})),
            if (ramazan['enabled'] == true && _ramazanVerisiYok)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                child: Text(
                    authService.translate(
                        "Bu yıl için Ramazan takvim verisi henüz eklenmedi; hatırlatıcı şu an hiçbir şey planlamıyor."),
                    style: TextStyle(
                        color: Colors.orange.withValues(alpha: 0.9),
                        fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionBanner(AuthService authService) {
    final durum = _bildirimIzni;
    if (durum == null) return const SizedBox.shrink();

    if (!durum.isGranted) {
      return _izinKarti(
        authService,
        icon: Icons.notifications_off_rounded,
        baslik: context.t("Bildirim izni verilmedi"),
        aciklama: "Hatırlatıcıların çalabilmesi için bildirim izni gerekir.",
        dugme: durum.isPermanentlyDenied ? "Ayarları Aç" : "İzin Ver",
        onTap: _izinIste,
      );
    }
    // Bildirim izni var ama tam zamanlı alarm izni yok: ezanlar çalar, ancak
    // Android bunları birkaç dakika geciktirebilir.
    if (_tamZamanliIzin == false) {
      return _izinKarti(
        authService,
        icon: Icons.alarm_off_rounded,
        baslik: context.t("Ezanlar tam vaktinde çalmayabilir"),
        aciklama:
            "Android, \"Alarmlar ve hatırlatıcılar\" izni olmadan bildirimleri "
            "birkaç dakika geciktirebilir. Ezanın tam vaktinde çalması için "
            "bu izni verin.",
        dugme: "İzin Ver",
        onTap: () => _tamZamanliIzinIste(authService),
      );
    }
    // Ezan bildirimleri (tam zamanlı alarm) zaten tam vaktinde çalıyor; bu
    // yalnızca arka plan bildirim YENİLEMESİNİ (uygulama günlerce açılmasa
    // bile bildirimlerin bitmemesi için) etkiler, o yüzden daha az acil
    // (turuncu değil, mavi) bir kart.
    if (_pilIzni == false) {
      return _izinKarti(
        authService,
        icon: Icons.battery_alert_rounded,
        baslik: context.t("Arka plan yenilemesi gecikebilir"),
        aciklama: "Telefonunuzun pil tasarrufu, uygulama uzun süre "
            "açılmadığında bildirimlerin arka planda yenilenmesini "
            "geciktirebilir. Ezanların kendisi bundan etkilenmez; yine de "
            "\"Pil optimizasyonunu yoksay\" izni verirseniz yenileme daha "
            "güvenilir çalışır.",
        dugme: "İzin Ver",
        renk: Colors.blue,
        onTap: _pilIzinIste,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _izinKarti(
    AuthService authService, {
    required IconData icon,
    required String baslik,
    required String aciklama,
    required String dugme,
    required VoidCallback onTap,
    Color renk = Colors.orange,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: isDark(context) ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: renk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(authService.translate(baslik),
                    style: TextStyle(
                        color: getTextColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(authService.translate(aciklama),
                    style: TextStyle(
                        color: getSubTextColor(context),
                        fontSize: 13,
                        height: 1.3)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Text(authService.translate(dugme),
                      style: TextStyle(
                          color: getAccentColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHatirlaticiCard(
      AuthService authService,
      String title,
      String offsetLabel,
      bool isOn,
      Function(bool) onSwitch,
      String timeVal,
      Function(String) onTimeSelect,
      String soundKey,
      Function(String) onSoundSelect) {
    return Container(
      decoration: BoxDecoration(
          color: getCardColor(context),
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text(authService.translate(title),
                        style: TextStyle(
                            color: getTextColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w500))),
                CupertinoSwitch(
                    value: isOn,
                    activeTrackColor: CupertinoColors.activeGreen,
                    onChanged: onSwitch),
              ],
            ),
          ),
          if (isOn) ...[
            Divider(color: getDividerColor(context), height: 1, indent: 16),
            InkWell(
              onTap: () => showSwiperPicker(
                  context,
                  authService.translate(title),
                  _timeOptions,
                  timeVal,
                  onTimeSelect),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(authService.translate(offsetLabel),
                        style: TextStyle(
                            color: getTextColor(context), fontSize: 15)),
                    Row(
                      children: [
                        Text(authService.translate(timeVal),
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 15)),
                        const SizedBox(width: 8),
                        Icon(Icons.unfold_more_rounded,
                            color: isDark(context)
                                ? Colors.white54
                                : Colors.black45,
                            size: 20)
                      ],
                    )
                  ],
                ),
              ),
            ),
            Divider(color: getDividerColor(context), height: 1, indent: 16),
            InkWell(
              onTap: () async {
                final secilenKey = await context
                    .push<String>('/settings/ses-secimi', extra: soundKey);
                if (secilenKey != null) onSoundSelect(secilenKey);
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(authService.translate("Ses"),
                        style: TextStyle(
                            color: getTextColor(context), fontSize: 15)),
                    Row(
                      children: [
                        Text(
                            authService.translate(
                                ReminderSounds.byKey(soundKey).displayName),
                            style: TextStyle(
                                color: getSubTextColor(context), fontSize: 15)),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_ios,
                            color: isDark(context)
                                ? Colors.white24
                                : Colors.black26,
                            size: 14)
                      ],
                    )
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
