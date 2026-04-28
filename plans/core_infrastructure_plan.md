# Core Infrastructure Planı

## 1. Result Wrapper
- [ ] `lib/core/utils/result.dart` dosyasını oluştur.
- [ ] `Result<T>` sınıfını tanımla (success/failure).

## 2. Dependency Injection (DI)
- [ ] `lib/locator.dart` dosyasını gözden geçir ve eksik Repository/Servisleri kaydet.
- [ ] Provider sınıflarını (DiniGunlerProvider, KuranProvider, KutuphaneProvider) `getIt` kullanacak şekilde güncelle.

## 3. Uygulama
- [ ] Repository metodlarını `Result` dönecek şekilde güncelle.
- [ ] Provider'larda `Result` kontrolü ekle.
