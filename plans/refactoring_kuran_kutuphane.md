# Kuran ve Kütüphane Provider Refactoring Planı

## 1. Kuran Feature Refactor
- [ ] KuranProvider sınıfını oluştur (`lib/features/kuran/providers/kuran_provider.dart`).
- [ ] Mevcut `_currentPage`, `_totalPages`, indirme durumu gibi durumları Provider'a taşı.
- [ ] `KuranPage` içinde `ChangeNotifierProvider` ile sarmala.
- [ ] `KuranPage` içeriğini `KuranProvider`'ı kullanacak şekilde güncelle.

## 2. Kütüphane Feature Refactor
- [ ] KutuphaneProvider sınıfını oluştur (`lib/features/kutuphane/providers/kutuphane_provider.dart`).
- [ ] Kütüphane içeriği verisini (`LibraryNode` listesi) Provider'a taşı.
- [ ] `KutuphanePage` içinde `ChangeNotifierProvider` ile sarmala.
- [ ] `KutuphanePage` içeriğini `KutuphaneProvider`'ı kullanacak şekilde güncelle.

## 3. Genel
- [ ] Refactoring sonrası tüm değişiklikleri doğrula.
