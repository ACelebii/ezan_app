package com.acelebi.ezanvakti

import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Ses tuşu (Zikirmatik sayaç ekranı için): Android, KEYCODE_VOLUME_UP/DOWN'ı
 * sistemin ses yönetimi için burada (Activity.dispatchKeyEvent) tüketir;
 * Flutter'ın kendi tuş dinleyicisine (Dart tarafı) hiç ulaşmaz. Bu yüzden
 * olayı burada yakalayıp Flutter'a bir MethodChannel ile bildiriyoruz.
 * Yalnızca Dart tarafı "dinlemeyiAyarla" ile açtığında (sayaç ekranı
 * görünürken) tüketilir; kapalıyken normal ses davranışı korunur.
 */
class MainActivity : FlutterActivity() {
    private val sesTusuKanaliAdi = "com.acelebi.ezanvakti/ses_tusu"
    private var sesTusuKanali: MethodChannel? = null
    private var sesTusuDinleniyor = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sesTusuKanali =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sesTusuKanaliAdi).apply {
                setMethodCallHandler { call, result ->
                    if (call.method == "dinlemeyiAyarla") {
                        sesTusuDinleniyor = call.arguments as Boolean
                        result.success(null)
                    } else {
                        result.notImplemented()
                    }
                }
            }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (sesTusuDinleniyor &&
            (event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
                event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN)
        ) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                sesTusuKanali?.invokeMethod("basildi", null)
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }
}
