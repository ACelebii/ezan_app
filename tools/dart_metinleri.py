"""Dart kaynak dosyalarındaki dizge (string) sabitlerini bulur.

Yorumları atlar, ham (r'..') ve üç tırnaklı dizgeleri, `${...}` içindeki iç içe
dizgeleri işler. Aralarında yalnızca boşluk olan komşu dizgeleri ('a' 'b') tek
grup sayar. Çeviri araçları (Kur'an/zikirmatik) için kullanılır.

Kullanım: python tools/dart_metinleri.py dosya.dart [...]
"""
import io
import sys


def _dizge_sonu(s, i):
    """s[i] bir dizgenin açılış tırnağıdır (ya da 'r' öneki); bitiş indeksini döndürür."""
    ham = s[i] == 'r'
    j = i + 1 if ham else i
    q = s[j]
    uc = s.startswith(q * 3, j)
    j += 3 if uc else 1
    n = len(s)
    while j < n:
        c = s[j]
        if not ham and c == '\\':
            j += 2
            continue
        if uc and s.startswith(q * 3, j):
            return j + 3
        if not uc and c == q:
            return j + 1
        if not uc and c == '\n':
            return j  # kapanmamış (hata); yine de ilerle
        if not ham and c == '$' and j + 1 < n and s[j + 1] == '{':
            j = _suslu_sonu(s, j + 1)
            continue
        j += 1
    return n


def _suslu_sonu(s, i):
    """s[i] == '{'; dengeli kapanışın ardındaki indeksi döndürür (içteki dizgeler dahil)."""
    derinlik = 0
    j = i
    n = len(s)
    while j < n:
        c = s[j]
        if c in '\'"':
            j = _dizge_sonu(s, j)
            continue
        if c == '{':
            derinlik += 1
        elif c == '}':
            derinlik -= 1
            if derinlik == 0:
                return j + 1
        j += 1
    return n


def tara(kaynak):
    """[(baslangic, bitis, ham_kaynak)] döndürür (yorumlar dışında)."""
    s = kaynak
    n = len(s)
    i = 0
    bulunan = []
    while i < n:
        if s.startswith('//', i):
            while i < n and s[i] != '\n':
                i += 1
        elif s.startswith('/*', i):
            k = s.find('*/', i + 2)
            i = n if k < 0 else k + 2
        elif s[i] in '\'"' or (s[i] == 'r' and i + 1 < n and s[i + 1] in '\'"'
                               and (i == 0 or not (s[i - 1].isalnum() or s[i - 1] == '_'))):
            bit = _dizge_sonu(s, i)
            bulunan.append((i, bit, s[i:bit]))
            i = bit
        else:
            i += 1
    return bulunan


def gruplari(kaynak):
    """Komşu dizgeleri birleştirir: [(baslangic, bitis, [parcalar])]."""
    gruplar = []
    for b, e, ham in tara(kaynak):
        if gruplar and kaynak[gruplar[-1][1]:b].strip() == '':
            gruplar[-1][1] = e
            gruplar[-1][2].append(ham)
        else:
            gruplar.append([b, e, [ham]])
    return gruplar


def deger(parcalar):
    """Parçaların düz metin değeri (kaçışlar çözülür, ${...} olduğu gibi kalır)."""
    cikti = ''
    for p in parcalar:
        ham = p[0] == 'r'
        govde = p[1:] if ham else p
        q = govde[0]
        kalin = govde.startswith(q * 3)
        ic = govde[3:-3] if kalin else govde[1:-1]
        if not ham:
            ic = (ic.replace('\\n', '\n').replace("\\'", "'").replace('\\"', '"')
                  .replace('\\\\', '\\').replace('\\$', '$'))
        cikti += ic
    return cikti


if __name__ == '__main__':
    for yol in sys.argv[1:]:
        kaynak = io.open(yol, encoding='utf-8').read()
        for b, e, parcalar in gruplari(kaynak):
            satir = kaynak.count('\n', 0, b) + 1
            print(f'{yol.split("/")[-1]}:{satir}\t{deger(parcalar)!r}')
