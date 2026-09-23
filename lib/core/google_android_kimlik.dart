// lib/core/google_android_kimlik.dart

import 'package:flutter/foundation.dart' show kReleaseMode;

/// Google'ın "Android apps" kısıtlı bir API anahtarını düz HTTPS (REST)
/// isteğinde doğrulaması için gereken başlıklar. Google Play Services'in kendi
/// SDK'ları (ör. Maps SDK for Android haritayı çizerken) bunu otomatik yapar;
/// elle atılan bir REST isteği (ör. Places API (New) `searchNearby`) bu iki
/// başlığı KENDİ eklemelidir, aksi hâlde kısıtlı anahtarla 403 alır.
/// https://developers.google.com/maps/api-security-best-practices
///
/// Google Cloud Console'daki anahtarın "Android apps" listesinde BU paket adı
/// ile HEM hata ayıklama HEM yayın parmak izinin ikisi de kayıtlı olmalı;
/// [googleAndroidSertifika] çalışan derlemeye göre doğru olanı otomatik seçer.
const googleAndroidPaket = 'com.acelebi.ezanvakti';

/// Hata ayıklama anahtarının (`~/.android/debug.keystore`) SHA-1 parmak izi,
/// iki nokta üst üste işaretleri OLMADAN (Google'ın REST başlığı biçimi).
const _debugSertifika = '5F354297900F3DBFCF4CB1929A31DCF4A68908DA';

/// Gerçek imza anahtarının (22.09.2026, `android/upload-keystore.jks`; şifre
/// `android/key.properties`'te, git'e eklenmez) SHA-1 parmak izi.
const _releaseSertifika = '983B0FDB14BBDD0EFA79CFD14EFEB8167698165B';

/// Çalışan derlemenin imza parmak izi: `flutter run`/`--debug` derlemesinde
/// hata ayıklama anahtarı, `--release`/`--appbundle` derlemesinde gerçek imza
/// anahtarı (`kReleaseMode`, Flutter'ın kendi derleme kipi sabiti).
String get googleAndroidSertifika =>
    kReleaseMode ? _releaseSertifika : _debugSertifika;
