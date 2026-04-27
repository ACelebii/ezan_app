# State Management Plan (Riverpod)

## Hedef
Uygulama genelinde merkezi, test edilebilir ve reaktif bir state management yapısı kurmak.

## Neden Riverpod?
- Compile-time safety.
- Kolay test edilebilirlik.
- Providers (StateProvider, FutureProvider, etc.) ile temiz kod.

## Uygulama Adımları
- [ ] `pubspec.yaml` dosyasına `flutter_riverpod` ekle.
- [ ] `main.dart` dosyasını `ProviderScope` ile sar.
- [ ] `AuthService` (ChangeNotifier) gibi sınıfları `Notifier`/`AsyncNotifier` yapılarına dönüştür.
- [ ] UI bileşenlerini `ConsumerWidget` veya `ConsumerStatefulWidget` ile güncelle.
