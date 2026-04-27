# UI Tamamlama Planı

## Hedef
Vakitler sayfası için tüm yerleşim (layout) seçeneklerini aktif hale getirmek ve Pusula sayfasının işlevselliğini tamamlamak.

## Bileşenler
### 1. Vakitler Sayfası
- `VakitlerPage` ana sayfası, kullanıcı ayarlarından gelen "ana_sayfa_stili"ne göre ilgili layout'u göstermeli.
- Mevcut layoutlar: Listeli, Dairesel, Analog Saat, Fotoğraflı, Timeline, Dashboard.
- Her layout için veri binding işleminin yapılması.

### 2. Pusula Sayfası
- `pusula_controller.dart` üzerinden `flutter_compass` entegrasyonu.
- Pusula görselinin cihaza göre dönmesinin sağlanması.

## Uygulama Adımları
- [ ] `VakitlerPage` içinde tema değiştirme mekanizması (Layout switcher) kur.
- [ ] Her bir layout widget'ının vakit verilerine bağlanması.
- [ ] `pusula_controller.dart` içinde pusula açısının hesaplanması.
- [ ] `pusula_page.dart` UI'ının güncellenmesi.
