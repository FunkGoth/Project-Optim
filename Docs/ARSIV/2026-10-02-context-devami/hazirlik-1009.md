# 10-09 Gözden Geçirme — Hazırlık & Veri Denetimi (O21, 2026-10-02)
Amaç: 10-09'da karar turu AÇMAK DEĞİL, kriterlerle yeniden kontrol etmek (benchmark "Karar protokolü"). Bu dosya = denetim + eksik listesi + yürütme sırası.

## Veri stoğu (gerçek satır sayıları, 10-02)
| Kaynak | Satır | Not |
|---|---|---|
| context-snapshots.csv | 10 | K6; deg=1: 1 satır (O19); −44.4k vaka (59k→14.6k, FunkGoth UI) |
| context-ledger.csv | 28 | K9; 1 K2-batch İHLAL'i defter yakaladı (O18); self-audit 2× gec kayıt yakaladı |
| runs.csv | 12 | K7; full 6 / light 6 |
| **Toplam veri noktası** | **50** | **K9 kriteri "≥50" DOĞRUDAN TAM (O21 snapshot'u eşikte tamamladı)** |

**Denetim bulgusu**: STATE/LOG "ledger 26" diyordu — gerçek 28 (O20 gec kayıtları). O21 düzeltti (STATE güncellendi).

## deg sınıflandırması (K1 kriteri)
- GERÇEK 2: O18 (59k yanlış çerçeveleme — kullanıcı düzeltmesi) + O19 (boot hatası — kullanıcı düzeltmesi).
- Devir hata önledi: O19 dersi → devir TAM YOL + arama-kökü kuralı (O19'da ONAY, PROTOCOL'de) → O20/O21 boot'ları sorunsuz (4 standart dosya, kapsam hatası yok).
- → K1 kriteri "≥1 GERÇEK + ≥1 devir önleme" ✅ · K5 (alt küme) ✅

## K başına kriter anlık kontrolu (10-09'da yeniden sayılacak)
| K | Kriter | Veri (10-02) | Beklenti |
|---|---|---|---|
| K1 | ≥1 GERÇEK yakalama + ≥1 devir hata önledi | 2 GERÇEK; O20/O21 temiz boot | KAL |
| K2 | ortalama ctx_end baz (≈47–57k) altında | O20 tepe 42.032k; O21 25.9k (1. tur) | KAL (trend iyi) |
| K3 | devir sonrası 0–1 dosya ile devam | O20/O21 boot = 4 standart dosya (boot, devir değil); O19 devir başarısızlık O19'da onarildi | KAL (karşı-kanıt yok) |
| K4 | büyük çıktı context şişirmiyor | rapor 76 satır → work/ dosyası | KAL (varsayılan) |
| K5 | K1 ile birlikte | alt küme | KAL |
| K6 | veri bir karar üretti | 10 snapshot + 1 compaction vaka | KAL |
| K7 | ≥3 run/hafta + net tasarruf | 12 run / 2 gün | KAL |
| K8 | echo nicellendi | ledger `tok_tahmini` (K8→K9 birleşik) | KAL (birleşik) |
| K9 | ≥50 veri noktası | **50 (doğrudan tam)** | KAL |

## Boşluklar — 10-09'a kadar doldurulacak
1. **Kullanıcı compaction sayımları** O19→O21 (agent sayamaz; O18 = 2). → K2 kriterinin eksik yarısı.
2. **FAZ 2 paralel kapasite ölçümü** (2×GPU worker, Mod B — YALNIZ unattended; FunkGoth boş vakitte tetikler) → runs.csv 13+.
3. **Ö3**: ana model ≈17 tok/s TEK örnek → yeniden örnekle (~32 tok API) → baseline.md bant.
4. **Routing boşluğu (O18)**: 27B'de kendim yapılan işler runs.csv'de YOK → sub-agent entegrasyon çalışması (routing alanı).
5. **K6 limitasyonu**: compaction tepe değeri agent tarafından yakalanamıyor → FunkGoth UI gözlemi kanalı açık kalır.

## 10-09 yürütme sırası (öneri)
1. FAZ 2 ölçümü tamamlanmadıysa önce o (Mod B, unattended) → runs.csv.
2. Ö3 örnekleme → baseline.md bant güncelle.
3. Bu denetim + yeni veri → rapor `work/2026-10-09-gozden-gecirme/rapor.md`.
4. K başına: KAL / DÜZELT / TERK — her madde FunkGoth onayı (Sabit Kural 2) → PROTOCOL + DECISIONS + lessons.
5. Arşiv: context-benchmark.md + csv'ler → `metrics/archive/` (yol referansları güncellenir); kalan karar DECISIONS'ta.
