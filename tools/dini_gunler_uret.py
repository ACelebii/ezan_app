#!/usr/bin/env python3
"""Diyanet'in resmi "Dini Günler Listesi"nden assets/json/dini_gunler.json üretir.

Kaynak: https://vakithesaplama.diyanet.gov.tr  (Dini Günler Listesi)
Çapraz doğrulama: https://namazvakitleri.diyanet.gov.tr/tr-TR/dini-gunler
(Diyanet'in bugünden ertesi yıl sonuna miladi-hicri gün tablosu).

Kullanım (proje kökünden):  python tools/dini_gunler_uret.py
Her satır doğrulanır; tutarsızlık varsa dosya YAZILMAZ ve hata verir. Diyanet
sayfa düzenini değiştirirse araç sessizce yanlış veri üretmek yerine durur.
Yeni yıl yayımlanınca YILLAR'a eklemek yeter.
"""
import datetime
import html
import io
import json
import os
import re
import sys
import urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0 Safari/537.36"
KOK = "https://vakithesaplama.diyanet.gov.tr/"
# yıl -> sayfa. Yalnızca EKSİKSİZ yayımlanmış yıllar burada olmalı. Diyanet'in
# 2028-2035 listeleri (icerik.php?icerik=185..192, 2028 = 185) henüz yalnızca
# bayramları, Ramazan başlangıcını, Hicri Yılbaşı'nı ve Aşure'yi içerir; kandil,
# Kadir Gecesi ve Mevlid tarihleri yok (21.09.2026'da ölçüldü). Bir yılın listesi
# tamamlanınca buraya eklenir; araç eksik listeyi doğrulamada reddeder.
YILLAR = {
    2024: "dinigunler.php?yil=2024", 2025: "dinigunler.php?yil=2025",
    2026: "dinigunler.php?yil=2026", 2027: "icerik.php?icerik=154",
}
CAPRAZ_SAYFA = "https://namazvakitleri.diyanet.gov.tr/tr-TR/dini-gunler"

MILADI_AY = {"OCAK": 1, "ŞUBAT": 2, "MART": 3, "NİSAN": 4, "MAYIS": 5, "HAZİRAN": 6,
             "TEMMUZ": 7, "AĞUSTOS": 8, "EYLÜL": 9, "EKİM": 10, "KASIM": 11, "ARALIK": 12}
AY_ADI = ["", "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz",
          "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
HAFTA = ["PAZARTESİ", "SALI", "ÇARŞAMBA", "PERŞEMBE", "CUMA", "CUMARTESİ", "PAZAR"]
HICRI_AY = {"MUHARREM": "Muharrem", "SAFER": "Safer", "R.EVVEL": "Rebiülevvel",
            "R.VVEL": "Rebiülevvel", "R.AHİR": "Rebiülahir", "C.EVVEL": "Cemaziyelevvel",
            "C.AHİR": "Cemaziyelahir", "RECEB": "Recep", "ŞABAN": "Şaban",
            "RAMAZAN": "Ramazan", "ŞEVVAL": "Şevval", "ZİLKADE": "Zilkade",
            "ZİLHİCCE": "Zilhicce"}

# Diyanet'in yazımı -> tür anahtarı. AREFE tek başına iki bayram için de geçer;
# hicri aya göre ayrılır.
ADLAR = {
    "ÜÇ AYLARIN BAŞLANGICI": "uc_aylar", "REGAİB KANDİLİ": "regaib",
    "MİRAC KANDİLİ": "miraç", "BERAT KANDİLİ": "berat",
    "RAMAZAN BAŞLANGICI": "ramazan", "KADİR GECESİ": "kadir",
    "HİCRİ YILBAŞI": "hicri_yilbasi", "AŞURE GÜNÜ": "asure",
    "MEVLİD KANDİLİ": "mevlid",
}
for _n in (1, 2, 3):
    ADLAR[f"RAMAZAN BAYRAMI ({_n}. GÜN)"] = f"ramazan_bayrami_{_n}"
for _n in (1, 2, 3, 4):
    ADLAR[f"KURBAN BAYRAMI ({_n}. GÜN)"] = f"kurban_bayrami_{_n}"

# Her türün beklenen hicri günü (ay, gün). Diyanet listesi bununla karşılaştırılır.
BEKLENEN = {
    "uc_aylar": ("Recep", 1), "miraç": ("Recep", 26), "berat": ("Şaban", 14),
    "ramazan": ("Ramazan", 1), "kadir": ("Ramazan", 26),
    "arefe_ramazan": ("Ramazan", None), "hicri_yilbasi": ("Muharrem", 1),
    "asure": ("Muharrem", 10), "mevlid": ("Rebiülevvel", 11),
    "arefe_kurban": ("Zilhicce", 9),
    "ramazan_bayrami_1": ("Şevval", 1), "ramazan_bayrami_2": ("Şevval", 2),
    "ramazan_bayrami_3": ("Şevval", 3),
    "kurban_bayrami_1": ("Zilhicce", 10), "kurban_bayrami_2": ("Zilhicce", 11),
    "kurban_bayrami_3": ("Zilhicce", 12), "kurban_bayrami_4": ("Zilhicce", 13),
}

_BAYRAM_TR = ("Başı rahmet, ortası mağfiret, sonu cehennem azabından kurtuluş olan "
              "Ramazan ayını geride bırakarak kavuştuğumuz mübarek Ramazan Bayramı.")
_BAYRAM_EN = ("The blessed festival that follows Ramadan, a month whose beginning is "
              "mercy, whose middle is forgiveness and whose end is deliverance from the Fire.")
_KURBAN_TR = ("Hz. İbrahim'in itaatini ve Hz. İsmail'in teslimiyetini hatırlatan, "
              "paylaşmanın ve yardımlaşmanın zirveye ulaştığı mübarek Kurban Bayramı.")
_KURBAN_EN = ("The blessed festival that recalls the obedience of Prophet Ibrahim and the "
              "submission of Prophet Ismail, when sharing and helping others reach their peak.")

TANIMLAR = {
    "uc_aylar": (
        "Üç Ayların Başlangıcı", "Beginning of the Three Holy Months",
        "Recep, Şaban ve Ramazan aylarından oluşan, ibadet ve tövbe için fırsat sayılan "
        "mübarek zaman diliminin başlangıcıdır. Recep ayının ilk günüdür.",
        "The start of the three holy months of Rajab, Sha'ban and Ramadan, a period regarded "
        "as an opportunity for worship and repentance. It is the first day of Rajab."),
    "regaib": (
        "Regaib Kandili", "Raghaib Night",
        "Recep ayının ilk Cuma gecesidir (Perşembe'yi Cuma'ya bağlayan gece). Üç Aylar'ın ilk "
        "kandilidir; bu gece dua, ibadet ve tövbe ile geçirilir.",
        "The night of the first Friday of Rajab (the night linking Thursday to Friday). It is the "
        "first of the holy nights of the three months and is spent in prayer, worship and repentance."),
    "miraç": (
        "Miraç Kandili", "Miraj Night",
        "Recep ayının 26'sını 27'sine bağlayan gecedir. Peygamber Efendimiz'in (s.a.v) "
        "Mescid-i Haram'dan Mescid-i Aksa'ya, oradan da semaya yükseltildiği ve beş vakit "
        "namazın farz kılındığı mübarek gece olarak anılır.",
        "The night linking the 26th of Rajab to the 27th. It is remembered as the blessed night "
        "on which the Prophet (peace be upon him) was taken from the Sacred Mosque to Al-Aqsa "
        "and then ascended to the heavens, and on which the five daily prayers were made obligatory."),
    "berat": (
        "Berat Kandili", "Berat Night",
        "Berat Kandili, günahlardan arınma ve temize çıkma gecesidir. Şaban ayının 14'ünü "
        "15'ine bağlayan bu gecede Allah'ın rahmetinin yeryüzüne tecelli ettiği, bağışlanma "
        "kapılarının ardına kadar açıldığı kabul edilir.",
        "The night of purification from sins and a fresh start. On this night, linking the 14th "
        "of Sha'ban to the 15th, God's mercy is believed to be manifest on earth and the doors "
        "of forgiveness to be wide open."),
    "ramazan": (
        "Ramazan Başlangıcı", "Start of Ramadan",
        "Rahmet, bereket ve mağfiret ayı olan Ramazan ayının başlangıcı. Kur'an-ı Kerim'in "
        "indirilmeye başlandığı, oruç ibadetinin yerine getirildiği mübarek ay.",
        "The beginning of Ramadan, the month of mercy, blessing and forgiveness, in which the "
        "Qur'an began to be revealed and the fast is observed."),
    "kadir": (
        "Kadir Gecesi", "Laylat al-Qadr (Night of Power)",
        "Ramazan'ın 26'sını 27'sine bağlayan gecedir. Bin aydan daha hayırlı olan Kadir Gecesi, "
        "Yüce kitabımız Kur'an-ı Kerim'in Peygamber Efendimize (s.a.v) indirilmeye başlandığı, "
        "meleklerin yeryüzüne indiği eşsiz bir gecedir.",
        "The night linking the 26th of Ramadan to the 27th. Better than a thousand months, it is "
        "the unique night on which the Qur'an began to be revealed to the Prophet (peace be upon "
        "him) and the angels descend to earth."),
    "arefe_ramazan": (
        "Ramazan Bayramı Arefesi", "Eve of Eid al-Fitr",
        "Ramazan Bayramı'ndan bir önceki gündür. Bayram hazırlıkları yapılır, fıtır sadakası "
        "verilir.",
        "The day before Eid al-Fitr, when preparations for the festival are made and the "
        "charity of fitr is given."),
    "ramazan_bayrami": (
        "Ramazan Bayramı", "Eid al-Fitr", _BAYRAM_TR, _BAYRAM_EN),
    "arefe_kurban": (
        "Kurban Bayramı Arefesi", "Eve of Eid al-Adha (Day of Arafah)",
        "Zilhicce'nin dokuzuncu günü, Kurban Bayramı'nın arefesidir. Hacıların Arafat'ta vakfe "
        "yaptığı gündür.",
        "The ninth of Dhu al-Hijjah, the eve of Eid al-Adha, when the pilgrims stand at Arafat."),
    "kurban_bayrami": (
        "Kurban Bayramı", "Eid al-Adha", _KURBAN_TR, _KURBAN_EN),
    "hicri_yilbasi": (
        "Hicri Yılbaşı", "Islamic New Year",
        "Peygamber Efendimiz Hz. Muhammed'in (s.a.v) Mekke'den Medine'ye hicretini esas alan "
        "Hicri takvimin ilk günü ve yeni yılın başlangıcı.",
        "The first day of the Hijri calendar, which is based on the migration of the Prophet "
        "Muhammad (peace be upon him) from Mecca to Medina, and the start of the new year."),
    "asure": (
        "Aşure Günü", "Day of Ashura",
        "Muharrem ayının onuncu günü olan Aşure Günü, tarihte birçok önemli hadisenin "
        "yaşandığı, paylaşmanın, dayanışmanın ve birlikteliğin simgesidir.",
        "The tenth day of Muharram, on which many important events took place in history; a "
        "symbol of sharing, solidarity and togetherness."),
    "mevlid": (
        "Mevlid Kandili", "Mawlid Night",
        "İnsanlığı karanlıktan aydınlığa çıkaran, rahmet elçisi Peygamber Efendimiz Hz. "
        "Muhammed'in (s.a.v) yeryüzünü şereflendirdiği veladet gecesidir.",
        "The night of the birth of the Prophet Muhammad (peace be upon him), the messenger of "
        "mercy who led humanity from darkness to light."),
}


def al(url):
    istek = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(istek, timeout=40) as y:
        return y.read().decode("utf-8", "replace")


def metin(hucre):
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", hucre))).strip()


def bosluksuz(s):
    return re.sub(r"\s+", "", s)


def yil_listesi(yil, sayfa):
    """Bir yılın listesini [(tarih, tur, hicri_gun, hicri_ay, hicri_yil, hafta)] olarak döndürür."""
    g = re.sub(r"<script.*?</script>|<style.*?</style>", " ", al(KOK + sayfa), flags=re.S)
    kayitlar, gorulen_satir = [], 0
    for tr in re.findall(r"<tr.*?</tr>", g, flags=re.S | re.I):
        h = [metin(c) for c in re.findall(r"<t[dh][^>]*>(.*?)</t[dh]>", tr, flags=re.S | re.I)]
        if len(h) != 7 or not re.fullmatch(r"\d+", bosluksuz(h[0])):
            continue
        gorulen_satir += 1
        hg, ha, hy = int(bosluksuz(h[0])), bosluksuz(h[1]).upper(), int(bosluksuz(h[2]))
        mg = int(bosluksuz(h[3]))
        ay_adi, _, my = re.sub(r"\s+", "", h[4].upper()).partition("-")
        hafta = bosluksuz(h[5]).upper()
        ad = re.sub(r"\s+", " ", h[6].upper()).strip()
        assert ha in HICRI_AY, f"{yil}: bilinmeyen hicri ay {ha!r}"
        assert ay_adi in MILADI_AY, f"{yil}: bilinmeyen miladi ay {ay_adi!r}"
        assert int(my) == yil, f"{yil}: yıl uyuşmuyor {h}"
        tarih = datetime.date(yil, MILADI_AY[ay_adi], mg)
        assert HAFTA[tarih.weekday()] == hafta, (
            f"{yil}: {tarih} hafta günü {HAFTA[tarih.weekday()]} olmalı, Diyanet {hafta} diyor")
        if set(ad) <= {"."}:
            continue  # ay başı satırı, dini gün değil
        if ad == "AREFE":
            tur = "arefe_ramazan" if HICRI_AY[ha] == "Ramazan" else "arefe_kurban"
        else:
            assert ad in ADLAR, f"{yil}: tanınmayan dini gün adı {ad!r} (Diyanet düzeni değişmiş olabilir)"
            tur = ADLAR[ad]
        kayitlar.append((tarih, tur, hg, HICRI_AY[ha], hy, hafta))
    assert gorulen_satir > 20, f"{yil}: tablo okunamadı ({gorulen_satir} satır)"
    return kayitlar


def dogrula_kurallar(yil, kayitlar):
    turler = [k[1] for k in kayitlar]
    for k in kayitlar:
        tarih, tur, hg, ha, hy, hafta = k
        if tur == "regaib":
            # Recep'in ilk Cuma gecesi: Perşembe akşamı. Recep'in 1'i Cuma ise
            # Perşembe hâlâ bir önceki ayın 29'u/30'udur (ör. 11 Ocak 2024).
            assert hafta == "PERŞEMBE", f"{yil} regaib {k}"
            assert (ha == "Recep" and 1 <= hg <= 7) or (
                ha == "Cemaziyelahir" and hg in (29, 30)), f"{yil} regaib {k}"
        else:
            ay, gun = BEKLENEN[tur]
            assert ha == ay, f"{yil} {tur}: hicri ay {ha}, beklenen {ay}"
            if gun is not None:
                assert hg == gun, f"{yil} {tur}: hicri gün {hg}, beklenen {gun}"
            elif tur == "arefe_ramazan":
                assert hg in (29, 30), f"{yil} arefe_ramazan hicri gün {hg}"
    # Bayram günleri ardışık olmalı
    for onek, n in (("ramazan_bayrami_", 3), ("kurban_bayrami_", 4)):
        gunler = sorted(k[0] for k in kayitlar if k[1].startswith(onek))
        assert len(gunler) == n, f"{yil} {onek}: {len(gunler)} gün"
        assert all((b - a).days == 1 for a, b in zip(gunler, gunler[1:])), f"{yil} {onek} ardışık değil"
    # Her yılda bunlar bir kez bulunmalı
    for tur in ("ramazan", "kadir", "arefe_ramazan", "arefe_kurban", "hicri_yilbasi", "asure", "mevlid"):
        assert turler.count(tur) == 1, f"{yil}: {tur} sayısı {turler.count(tur)}"
    for tur in ("miraç", "berat"):
        assert turler.count(tur) >= 1, f"{yil}: {tur} yok"
    # tarih sırası
    tarihler = [k[0] for k in kayitlar]
    assert tarihler == sorted(tarihler), f"{yil}: sıra bozuk"


def ascii_katla(s):
    for a, b in zip("üıöşçğÜİÖŞÇĞ", "uioscgUIOSCG"):
        s = s.replace(a, b)
    return s.lower()


def capraz_tablo():
    """Diyanet'in ikinci kaynağı: tarih -> (hicri gün, hicri ay), bugünden ertesi yıl sonuna."""
    g = re.sub(r"<script.*?</script>|<style.*?</style>", " ", al(CAPRAZ_SAYFA), flags=re.S)
    satirlar = [s.strip() for s in re.sub(r"<[^>]+>", "\n", g).split("\n") if s.strip()]
    satirlar = [html.unescape(s) for s in satirlar]
    aylar = {"Ocak": 1, "Şubat": 2, "Mart": 3, "Nisan": 4, "Mayıs": 5, "Haziran": 6,
             "Temmuz": 7, "Ağustos": 8, "Eylül": 9, "Ekim": 10, "Kasım": 11, "Aralık": 12}
    tablo = {}
    yil = datetime.date.today().year  # bu yılın satırlarında yıl yazmaz; sıra kronolojik
    for i, s in enumerate(satirlar[:-1]):
        m = re.fullmatch(r"(\d{1,2}) (\S+)(?: (\d{4}))? \S+", s)
        h = re.fullmatch(r"(\d{1,2}) (\S+) (14\d\d)", satirlar[i + 1])
        if m and h and m.group(2) in aylar:
            if m.group(3):
                yil = int(m.group(3))
            tablo[datetime.date(yil, aylar[m.group(2)], int(m.group(1)))] = (
                int(h.group(1)), ascii_katla(h.group(2)))
    assert len(tablo) > 300, f"çapraz tablo okunamadı ({len(tablo)} gün)"
    return tablo


def main():
    tum = {}
    for yil, sayfa in YILLAR.items():
        kayitlar = yil_listesi(yil, sayfa)
        dogrula_kurallar(yil, kayitlar)
        tum[yil] = kayitlar
        print(f"{yil}: {len(kayitlar)} kayıt tamam")

    # İkinci kaynak yalnızca içinde bulunulan ayı ve ertesi yılın tamamını verir
    # (arada boşluk olabilir); tabloda bulunan her gün karşılaştırılır.
    capraz = capraz_tablo()
    kontrol, disarida = 0, 0
    for yil, kayitlar in tum.items():
        for tarih, tur, hg, ha, hy, _ in kayitlar:
            if tarih not in capraz:
                disarida += 1
                continue
            kontrol += 1
            beklenen = (hg, ascii_katla(ha))
            assert capraz[tarih] == beklenen, (
                f"ÇAPRAZ UYUŞMAZLIK {tarih} {tur}: liste {beklenen}, tablo {capraz[tarih]}")
    assert kontrol >= 15, f"çapraz doğrulama çok az kayıt kapsadı ({kontrol})"
    print(f"çapraz doğrulama: {kontrol} kayıt ikinci Diyanet kaynağıyla (miladi-hicri gün tablosu) "
          f"aynı; {disarida} kayıt tablonun kapsamı dışında")

    gunler = []
    for yil, kayitlar in tum.items():
        for tarih, tur, hg, ha, hy, _ in kayitlar:
            gunler.append({"tarih": tarih.isoformat(), "tur": tur, "hicri": f"{hg} {ha} {hy}"})
    tanimlar = {}
    for anahtar, (b, ben, d, den) in TANIMLAR.items():
        tanimlar[anahtar] = {"baslik": b, "baslikEn": ben, "detay": d, "detayEn": den}
    # bayram günleri numaralı başlık taşır: "(1. Gün)"
    cikti = {
        "kaynak": "T.C. Diyanet İşleri Başkanlığı, Vakit Hesaplama: Dini Günler Listesi",
        "uretim": datetime.date.today().isoformat(),
        "araç": "tools/dini_gunler_uret.py",
        "tanimlar": tanimlar,
        "gunler": gunler,
    }
    hedef = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "json", "dini_gunler.json")
    with io.open(hedef, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cikti, f, ensure_ascii=False, indent=1)
        f.write("\n")
    print(f"yazıldı: {os.path.normpath(hedef)}  ({len(gunler)} gün, {len(tanimlar)} tür)")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as e:
        print("DOĞRULAMA HATASI, dosya yazılmadı:", e)
        sys.exit(1)
