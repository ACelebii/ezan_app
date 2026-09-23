"""Diyanet mealinde "önceki ayetle aynı metin" olan ayetleri bulur ve
assets/json/diyanet_gruplu.json dosyasını üretir.

Neden: Diyanet birkaç ayeti tek blok hâlinde çevirir; quran.com API'si o bloğu
gruptaki HER ayete kopyalar (2:26 ve 2:27 aynı metin). Uygulama bu ayetlerde
Elmalılı meâlini (ayete özel) gösterir ve kaynağı etiketler.

Kural (bir ayet için): Diyanet metni önceki ayetin Diyanet metniyle aynı VE
Elmalılı metni önceki ayetin Elmalılı metninden farklı (ve boş değil).

Kullanım:  python tools/meal_gruplu_uret.py            (ağdan çeker, ~2 dk)
           python tools/meal_gruplu_uret.py --json x.json   (kayıtlı ham veriyle)
Çıktıyı doğrular: 6236 ayet, hiçbir meal boş değil, sure numaraları 2-114.
"""
import io
import json
import re
import sys
import time
import urllib.request

API = 'https://api.quran.com/api/v4'
CIKTI = 'assets/json/diyanet_gruplu.json'
DIYANET, ELMALILI = 77, 52


def al(yol):
    for _ in range(4):
        try:
            istek = urllib.request.Request(API + yol, headers={'User-Agent': 'Mozilla/5.0 EzanVaktiApp-arac'})
            with urllib.request.urlopen(istek, timeout=60) as y:
                return json.loads(y.read().decode('utf-8'))
        except Exception as e:  # noqa: BLE001
            hata = e
            time.sleep(2)
    raise SystemExit(f'alınamadı {yol}: {hata}')


def temizle(metin):
    metin = re.sub(r'<[^>]+>', '', metin)
    return (metin.replace('&quot;', '"').replace('&amp;', '&')
            .replace('&#39;', "'").replace('&nbsp;', ' ').strip())


def cek():
    tum = {}
    for sure in range(1, 115):
        sayfa = 1
        while True:
            d = al(f'/verses/by_chapter/{sure}?language=tr&words=false&translations={DIYANET},{ELMALILI}'
                   f'&fields=text_uthmani&per_page=500&page={sayfa}')
            for v in d['verses']:
                tum[v['verse_key']] = {tr['resource_id']: temizle(tr['text']) for tr in v.get('translations', [])}
            sonraki = d['pagination'].get('next_page')
            if not sonraki or sonraki <= sayfa:
                break
            sayfa = sonraki
    return tum


def main():
    if '--json' in sys.argv:
        ham = json.load(io.open(sys.argv[sys.argv.index('--json') + 1], encoding='utf-8'))
        tum = {k: {int(i): t for i, t in m.items()} for k, m in ham.items()}
    else:
        tum = cek()

    assert len(tum) == 6236, len(tum)
    for k, m in tum.items():
        assert m.get(DIYANET) and m.get(ELMALILI), f'{k}: boş meal'

    anahtarlar = list(tum)
    sure = {}
    diyanet_tekrar = 0
    for onceki, k in zip(anahtarlar, anahtarlar[1:]):
        s, a = k.split(':')
        if onceki.split(':')[0] != s:
            continue
        if tum[k][DIYANET] == tum[onceki][DIYANET]:
            diyanet_tekrar += 1
            if tum[k][ELMALILI] != tum[onceki][ELMALILI]:
                sure.setdefault(s, []).append(int(a))

    sayi = sum(len(v) for v in sure.values())
    assert min(int(s) for s in sure) >= 2 and max(int(s) for s in sure) <= 114
    cikti = {
        'aciklama': 'Diyanet meali (quran.com 77) önceki ayetle aynı olan ve Elmalılı (52) ayete özel farklı '
                    'metin veren ayetler: sure numarası -> ayet numaraları. tools/meal_gruplu_uret.py üretir.',
        'diyanet_tekrar': diyanet_tekrar,
        'sayi': sayi,
        'sure': sure,
    }
    with io.open(CIKTI, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(cikti, f, ensure_ascii=False, separators=(',', ':'))
        f.write('\n')
    print(f'yazıldı: {CIKTI} | Diyanet tekrar: {diyanet_tekrar} | Elmalılıyla değişecek: {sayi} | sure: {len(sure)}')


if __name__ == '__main__':
    main()
