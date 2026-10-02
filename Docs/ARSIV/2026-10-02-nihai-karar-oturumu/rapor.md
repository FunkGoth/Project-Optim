# Nihai Karar Raporu — Context Ekonomisi & Veri Toplama Mekanizmaları
Tarih: 2026-10-02 · Oturum: O20 · Karar veren: **agent (tam yetki)** — FunkGoth, O20: "Bu işi çözmek için kendin ne yapacağına karar vermeni istiyorum… Gerekli tüm düzeltme self-otonom yetkisini sana veriyorum."
Kapsam: K1–K9 kuralları + veri toplama mekanizmaları (snapshot/defter/örnekleme) + boot maliyeti + routing.

## 1. Sorun
Tek 27B model + 24 GB GPU, çoklu proje/uygulamayla paylaşılıyor; context en kıt kaynak, VRAM tek kiracı.
Merkez soru: ölçüm/disiplin yığını (K1–K9, defter, snapshot, full örnekleme) **kendi maliyetinden fazla fayda sağlıyor mu**?
İkincil soru: sabit boot maliyeti (~19–21.5k tok/oturum) düşürülebilir mi?

## 2. Veri (10-02 itibarıyla)
**Context snapshot'ları (8 nokta, 3 oturum):**
| Olay | Değer |
|---|---|
| K öncesi baz | 8 yerel 27B oturumu: son context 32k–57k; ≥5/8'inde compaction izi (bazıları görev ortasında); sonrası aynı dosyaların yeniden okunması |
| O18 tepe | **59k → 14.6k (−44.4k)** — FunkGoth UI gözlemi; K6'nın ilk gerçek veri noktası |
| O19 | boot 21.5k; **deg=1** (boot hatası, kullanıcı düzeltme); 2 promptta +23.9k (4 dosya edit yansıması) |
| O20 | boot **19k** (en düşük); 1 promptta +9.5k |

**Defter (context-ledger.csv, 26 olay):** çoğu 100–300 tok/olay; 1 K2-batch ihlali (~600 tok fazla maliyet — defterin kendisi yakaladı).
**runs.csv (12 run, 12/12 kabul):**
- CPU worker: 10.2–10.4 tok/s stabil; think:false = 11x (41s→3.7s); **ana modele etki: none** (Mod A sıfır maliyet kanıtlı).
- GPU worker (solo): **101.9 / 103.2 / 108.1 tok/s** (~10x CPU); 18.5 = kuyruk artifact'i.
- Mod B: clean JIT reload **17.44s** (VRAM boş) vs 317.7s (çakışma) → break-even ≈200–250 output tok.
- Full örnekleme: **5 full** (hedef ≥3, 1. günde doldu); run 04 capture overhead **%14 > %10 eşiği** → mekanizmanın kendi denetimi bir bulgu üretti.
- Ana model: ~17 tok/s ilk örnek (Ö3 yeniden örnekleme bekliyor).

## 3. K kararları (deney 10-02'de ERKEN KAPANDI; 10-09 = gözden geçirme noktası)
| K | Karar | Gerekçe (kriter → veri) |
|---|---|---|
| K1 | **KAL** | "≥1 gerçek degradasyon yakalandı" → **2 GERÇEK deg=1** (O18 veri yanlış yorumu; O19 boot hatası); devir belgesi O18→O20 kayıpsız çalıştı |
| K2 | **KAL + K2c** | Dar okuma disiplini tutuldu (O20 boot 19k = en düşük). **K2c (yeni): append-only CSV'ler (snapshots/ledger/runs) → shell `>>` (sıfır yansıma)**; edit_file yalnız yerinde düzeltmede |
| K3 | **KAL** | Devir O18→O19→O20 zincirinde 0 yeniden okuma; yeni oturum 1 promptta devraldı (kriter: 0–1 dosya okumasıyla devam) |
| K4 | **KAL** | Bu rapor + O18 raporu; context yalnız özet + yol aldı |
| K5 | **KAL** | K1 alt kümesi; sıfır ek maliyet |
| K6 | **DÜZELT** | Fayda KANITLI (bu raporun kendisi verisiyle yazıldı) ama edit_file ile snapshot+defter yazımı ~400–600 tok/tur yansıtıyordu → **yeni: yalnız araç kullanan prompt sonlarında; shell `>>` ile defterle TEK çağrıda (K2c)**; deg alanı + limitasyon (tepe yakalanamaz) korunur |
| K7 | **KAL** | runs.csv 12/12 kabul; ana model etki none; 100+ satır özetler Mod A'da sıfır geçiş maliyeti (koexist kanıtlı) |
| K8 | **K9'A BİRLEŞTİ** | Echo maliyeti = defterin `tok_tahmini` sütunu (fiilen ölçtü: O18 ihlali ~600 tok, O19 4 edit +23.9k). Ayrı kural ek değer üretmedi → 10-09'a bırakılan karar önden verildi |
| K9 | **DÜZELT** | Kapsam daraltıldı: (a) 100+ satır okuma, (b) 50+ satır/tam dosya edit, (c) K ihlali; **küçük pencere editleri muaf**; **turn sonunda TEK shell append** (K2c); self-audit korunur. Terk kriteri (>300 tok/olay) sağlanmadı; batch append ile olay başına <150 tok |

## 4. Veri toplama mekanizmaları
| Mekanizma | Karar | Not |
|---|---|---|
| runs.csv (light daima) | **KAL** | 12 satır; şema hatası tek seferde yakalandı + düzeltme = yeni satır (append-only çalıştı) |
| Full örnekleme | **DÜZELT** | ~%50 override (→10-09) **düşürüldü**: hedef ≥3 1. günde doldu (5 full). Yeni: protokol = yeni iş tipi ilk + ~1/3 rastgele + anomali sonrası mutlaka; **run <30s → light varsayılan** (kanıt: run 04 %14 > %10) |
| K6 snapshot | **KAL (K6 düzeltmesiyle)** | sıklık: araç kullanan prompt başına 1 |
| K9 defter | **KAL (dar kapsam + batch append)** | 27B tarafının routing kayıtlarını da içeriyor → O18'deki "27B işleri kayıtta yok" boşluğu kapandı |
| Sistem Değerlendirmesi (24s) | **KAL** | 1. değerlendirme gerçek bulgular üretti (şema hatası, %14 overhead, 17 tok/s) → mekanizma çalışıyor; öneri→onay→poliçe döngüsü bir kez döndü (Ö1) |
| Global dosya bütçesi | **DÜZELT** | ~300 satır kuralı **LOG'dan bağımsız** (LOG = arşiv, boot'ta okunmaz); LOG yumuşak tavanı 300, 350'de FunkGoth'a sor — sessiz silme yok |

## 5. Boot maliyeti + routing (agent inisiyatif — tam yetki kapsamında)
- **PROTOCOL distille**: 101 → ~94 satır; runtime/ölçüm/deney detayları `agent/handbook.md`'ye taşındı (boot'ta OKUNMAZ, tam yollarla işaretli). Tahmini tasarruf: **~2–3k tok/oturum** (boot 19k → ~16–17k).
- **Routing haritası (nihai)**:
  | İş tipi | Yürüten |
  |---|---|
  | Karar / diyalog / mimari / kısa okuma / dosya işi / doğrulama | 27B (ana) |
  | 100+ satır özet/çıkarım/taslak, kaba tarama | worker8b (Mod A, CPU — sıfır geçiş maliyeti) |
  | Unattended paralel batch (≥200–250 output tok) | Mod B (2×GPU; evict→unload→JIT ~17s) |
- Kanıt: K9 defteri (27B işleri) + runs.csv (worker işleri) — iki taraf da kayıt altında.

## 6. Uygulanan dosya değişiklikleri
1. `work/2026-10-02-nihai-karar-oturumu/rapor.md` — yeni (bu dosya)
2. `PROTOCOL.md` — distille + K nihai kararları + K2c + routing + bütçe düzeltmesi + handbook işaretleri
3. `handbook.md` — yeni (delegation runtime, değerlendirme detayı, hız tablosu, deney arşivi, Bionic/LM Studio gerçekleri)
4. `DECISIONS.md` — nihai karar satırı (en yeni üstte)
5. `TASKS.md` — K1–K9 deneyi + nihai karar → Arşiv; 10-09 gözden geçirme Aktif'e
6. `STATE.md` — yeniden yazım (sıradaki adım = 10-09 gözden geçirme + Ö3)
7. `LOG.md` — O20 oturum kaydı
8. `lessons.md` — +2 ders
9. `metrics/context-benchmark.md` — "KAPANDI 10-02 (erken)" notu
10. `metrics/context-snapshots.csv` + `context-ledger.csv` — final satırlar (shell `>>`)
11. `git commit` (Sabit Kural 3)

## 7. Açık maddeler
1. **10-09 gözden geçirme noktası**: K verileri benchmark kriterleriyle yeniden kontrol + FAZ 2 raporu (paralel kapasite + routing teyidi) + Ö3 yeniden örnekleme.
2. **Sub-agent entegrasyon çalışması**: zamanı FunkGoth'ta (muhtemelen 10-09 sonrası).
3. EmberTale T1–T6: ayrı sohbet (karıştırmayacak kadar net).
