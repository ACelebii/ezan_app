import '../../features/kutuphane/kutuphane_model.dart';
import '../../utils/assets_constants.dart';

class KutuphaneRepository {
  List<LibraryNode> getLibraryItems() {
    return [
      LibraryNode(title: "Yâsîn", imagePath: Assets.yasinKapak),
      LibraryNode(title: "Tesbihat", imagePath: Assets.tesbihatKapak),
      LibraryNode(
          title: "Oruç",
          imagePath: Assets.orucKapak,
          children: getOrucAltKategorileri()),
      LibraryNode(title: "Namaz Hocası", imagePath: Assets.namazKapak),
      LibraryNode(title: "İlmihal", imagePath: Assets.ilmihalKapak),
      LibraryNode(title: "Dua", imagePath: Assets.duaKapak),
    ];
  }

  List<LibraryNode> getOrucAltKategorileri() {
    return [
      LibraryNode(
          title: "Oruç hakkında tüm bilgiler",
          imagePath: Assets.orucBilgi,
          children: [
            LibraryNode(
                title: "Oruca niyet ne zaman ve nasıl yapılır?",
                imagePath: Assets.orucNiyet,
                content:
                    "Oruca kalben niyet etmek yeterlidir. Ancak dille de söylenmesi sünnettir..."),
            LibraryNode(
                title: "Orucun Mahiyeti ve Çeşitleri",
                imagePath: Assets.orucMahiyet,
                content:
                    "Oruç, imsak vaktinden iftar vaktine kadar ibadet niyetiyle yeme, içme ve cinsel ilişkiden uzak durmaktır...")
          ]),
      LibraryNode(
          title: "Kuran-ı Kerim'de Oruç",
          imagePath: Assets.kuranOruc,
          content:
              "Kuran-ı Kerim'de oruç ile ilgili ayetler Bakara suresinde yer almaktadır..."),
    ];
  }
}
