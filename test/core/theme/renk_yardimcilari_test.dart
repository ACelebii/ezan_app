import 'package:ezan_vakti_uygulamasi/core/theme/app_theme.dart';
import 'package:ezan_vakti_uygulamasi/features/settings/settings_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// [mod] ile açılan bir uygulamada, bir bağlamdan okunan renkler.
Future<Map<String, Object>> _oku(WidgetTester tester, ThemeMode mod) async {
  late Map<String, Object> sonuc;
  AppTheme.mod.value = mod;
  await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
    valueListenable: AppTheme.mod,
    builder: (_, m, __) => MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: m,
      home: Builder(builder: (context) {
        sonuc = {
          'karanlik': isDark(context),
          'arkaplan': getBgColor(context),
          'kart': getCardColor(context),
          'yazi': getTextColor(context),
          'altYazi': getSubTextColor(context),
          'cizgi': getDividerColor(context),
          'vurgu': getAccentColor(context),
          'girdi': getTextFieldColor(context),
          // AppTheme'in kendi yardımcıları: aynı olmalı.
          'app.karanlik': AppTheme.isDark(context),
          'app.arkaplan': AppTheme.getBgColor(context),
          'app.kart': AppTheme.getCardColor(context),
          'app.yazi': AppTheme.getTextColor(context),
          'app.altYazi': AppTheme.getSubTextColor(context),
          'app.cizgi': AppTheme.getDividerColor(context),
          'app.vurgu': AppTheme.getAccentColor(context),
          'app.girdi': AppTheme.getTextFieldColor(context),
          'ad': globalGeceModu,
        };
        return const SizedBox();
      }),
    ),
  ));
  return sonuc;
}

void main() {
  tearDown(() => AppTheme.mod.value = ThemeMode.system);

  testWidgets('koyu tema: eski değerlerle birebir', (tester) async {
    final r = await _oku(tester, ThemeMode.dark);
    expect(r['karanlik'], isTrue);
    expect(r['arkaplan'], Colors.black);
    expect(r['kart'], const Color(0xFF151517));
    expect(r['yazi'], Colors.white);
    expect(r['altYazi'], Colors.white54);
    expect(r['cizgi'], Colors.white.withValues(alpha: 0.05));
    expect(r['vurgu'], Colors.yellow);
    expect(r['girdi'], const Color(0xFF2C2C2E));
    expect(r['ad'], 'Açık');
  });

  testWidgets('açık tema: eski değerlerle birebir', (tester) async {
    final r = await _oku(tester, ThemeMode.light);
    expect(r['karanlik'], isFalse);
    expect(r['arkaplan'], const Color(0xFFF2F2F7));
    expect(r['kart'], Colors.white);
    expect(r['yazi'], Colors.black87);
    expect(r['altYazi'], Colors.black54);
    expect(r['cizgi'], Colors.black.withValues(alpha: 0.08));
    expect(r['vurgu'], Colors.orange.shade700);
    expect(r['girdi'], const Color(0xFFE5E5EA));
    expect(r['ad'], 'Kapalı');
  });

  for (final (parlaklik, beklenen) in [
    (Brightness.dark, true),
    (Brightness.light, false),
  ]) {
    testWidgets('otomatik + telefon $parlaklik: karanlık=$beklenen',
        (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = parlaklik;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      final r = await _oku(tester, ThemeMode.system);
      expect(r['karanlik'], beklenen);
      expect(r['ad'], 'Otomatik');
    });
  }

  testWidgets('settings_common yardımcıları ile AppTheme hep aynı sonucu verir',
      (tester) async {
    for (final mod in ThemeMode.values) {
      final r = await _oku(tester, mod);
      for (final anahtar in [
        'karanlik',
        'arkaplan',
        'kart',
        'yazi',
        'altYazi',
        'cizgi',
        'vurgu',
        'girdi'
      ]) {
        expect(r[anahtar], r['app.$anahtar'], reason: '$mod $anahtar');
      }
    }
  });

  testWidgets(
      'AppTheme.mod değişince çalışan uygulamanın renkleri hemen değişir',
      (tester) async {
    var r = await _oku(tester, ThemeMode.light);
    expect(r['arkaplan'], const Color(0xFFF2F2F7));

    AppTheme.mod.value = ThemeMode.dark; // Ayarlar > Gece Modu > Açık
    await tester.pumpAndSettle();
    // Builder yeniden çalıştı: son okunan renk koyu olmalı.
    r = await _oku(tester, ThemeMode.dark);
    expect(r['arkaplan'], Colors.black);
  });
}
