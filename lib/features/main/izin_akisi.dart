import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../auth/auth_service.dart';

const _sorulduAnahtari = 'ilk_acilis_izinleri_soruldu';

/// Açıklama penceresi gösterilmeli mi? Gerekli izinlerden biri eksikse ve daha
/// önce sorulmadıysa. Bir kez sorulur: kullanıcı "Şimdi Değil" derse tekrar
/// tekrar rahatsız edilmez; izinler Ayarlar > Hatırlatıcılar sayfasından da
/// verilebilir.
bool izinDiyaloguGerekli({
  required bool bildirimVar,
  required bool tamZamanliVar,
  required bool dahaOnceSoruldu,
}) =>
    !dahaOnceSoruldu && !(bildirimVar && tamZamanliVar);

/// İlk açılışta, ezanların tam vaktinde çalması için gereken iki izni önce
/// açıklar, sonra ister: bildirim izni ve Android 12+ "Alarmlar ve
/// hatırlatıcılar" izni (verilmezse Android bildirimleri dakikalarca
/// geciktirebilir; ölçüldü: 1 dk 56 sn).
Future<void> ilkAcilisIzinleriniIste(BuildContext context) async {
  final authService = Provider.of<AuthService>(context, listen: false);
  final prefs = await SharedPreferences.getInstance();
  final servis = NotificationService.instance;

  final bildirimVar = (await servis.permissionStatus()).isGranted;
  final tamZamanliVar = await servis.tamZamanliBildirimIzniVar();
  if (!izinDiyaloguGerekli(
    bildirimVar: bildirimVar,
    tamZamanliVar: tamZamanliVar,
    dahaOnceSoruldu: prefs.getBool(_sorulduAnahtari) ?? false,
  )) {
    return;
  }
  // Önce işaretle: uygulama pencere açıkken kapanırsa her açılışta sorulmasın.
  await prefs.setBool(_sorulduAnahtari, true);
  if (!context.mounted) return;

  final devam = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.notifications_active_rounded, size: 32),
      title: Text(authService.translate("Ezanlar tam vaktinde çalsın")),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(authService.translate(
              "Ezan ve hatırlatıcıların tam vaktinde çalabilmesi için şu izinler gerekiyor:")),
          const SizedBox(height: 12),
          if (!bildirimVar) _madde(authService.translate("Bildirim izni")),
          if (!tamZamanliVar)
            _madde(authService.translate(
                "\"Alarmlar ve hatırlatıcılar\" izni: verilmezse Android ezanı birkaç dakika geciktirebilir.")),
          const SizedBox(height: 12),
          Text(
              authService.translate(
                  "Daha sonra Ayarlar > Hatırlatıcılar bölümünden de verebilirsiniz."),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(authService.translate("Şimdi Değil")),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(authService.translate("Devam")),
        ),
      ],
    ),
  );
  if (devam != true) return;

  // Bildirim izni reddedilirse tam zamanlı alarm izninin anlamı yok.
  final bildirimVerildi =
      bildirimVar || (await servis.requestPermissions()).isGranted;
  if (bildirimVerildi && !tamZamanliVar) {
    await servis.tamZamanliBildirimIzniIste();
  }
}

Widget _madde(String metin) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  "),
          Expanded(child: Text(metin)),
        ],
      ),
    );
