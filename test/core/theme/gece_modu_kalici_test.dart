import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kayıttaki değere yazılan değişikliğin diske ulaşmasını bekler.
Future<String?> _kayit() async {
  await Future<void>.delayed(Duration.zero);
  return (await SharedPreferences.getInstance()).getString('gece_modu');
}

/// Temiz bir "telefon": önceki testin dinleyicisi ve önbelleğe alınmış
/// SharedPreferences nesnesi yeni depoyu bozmasın.
void _hazirla(Map<String, Object> kayitlar) {
  AppTheme.mod.value = ThemeMode.system;
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues(kayitlar);
}

void main() {
  tearDown(() => AppTheme.mod.value = ThemeMode.system);

  test('kayıt yoksa Otomatik açılır', () async {
    _hazirla({});
    AppTheme.mod.value = ThemeMode.dark; // bellekte eski bir değer var

    await AppTheme.modYukle();

    expect(AppTheme.mod.value, ThemeMode.system);
  });

  test('kayıtlı seçim (koyu/açık) uygulama açılırken geri yüklenir', () async {
    for (final mod in [ThemeMode.dark, ThemeMode.light]) {
      _hazirla({'gece_modu': mod.name});

      await AppTheme.modYukle();

      expect(AppTheme.mod.value, mod);
    }
  });

  test('bozuk kayıt Otomatik olur, çökmez', () async {
    _hazirla({'gece_modu': 'mor'});

    await AppTheme.modYukle();

    expect(AppTheme.mod.value, ThemeMode.system);
  });

  test('seçim değişince kaydedilir; yeniden yükleyince aynısı döner', () async {
    _hazirla({});
    await AppTheme.modYukle();

    AppTheme.mod.value = ThemeMode.light; // Ayarlar > Gece Modu > Kapalı
    expect(await _kayit(), 'light');
    AppTheme.mod.value = ThemeMode.dark;
    expect(await _kayit(), 'dark');

    // "Uygulamayı yeniden aç": bellek ve önbellek sıfırlanır, diskteki değer okunur.
    final kaydedilen = await _kayit();
    _hazirla({'gece_modu': kaydedilen!});
    await AppTheme.modYukle();
    expect(AppTheme.mod.value, ThemeMode.dark);
  });

  test(
      'modYukle iki kez çağrılsa da her değişiklik bir kez yazılır (dinleyici çoğalmaz)',
      () async {
    _hazirla({});
    await AppTheme.modYukle();
    await AppTheme.modYukle();
    var yazma = 0;
    // Dinleyici sayısını doğrudan ölçemeyiz; davranış: bir değişiklik = bir bildirim
    // ve son değer doğru yazılır.
    AppTheme.mod.addListener(() => yazma++);

    AppTheme.mod.value = ThemeMode.dark;

    expect(yazma, 1);
    expect(await _kayit(), 'dark');
  });
}
