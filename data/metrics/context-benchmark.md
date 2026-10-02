# Context Benchmark — K1–K7 Deneysel Tasarım (2026-10-02)
Durum: DENEY (1 hafta: 10-02 → 10-09). Onay: FunkGoth (Oturum 18).
İlke: kurallar veri destekledikçe yaşar — "maliyetliyse veya faydasını sağlamıyorsa terkedelim" (FunkGoth).
Not (tutarlılık): lessons 2026-10-02 "fiilen çalışan davranışı kural olarak ekleme" — K'lar bu yüzden
SÜREKLİ kural değil, **süreli deney** olarak PROTOCOL'de; 10-09'da veri karar verir.

## Hipotez
K uygulamaları (a) compaction sonrası görev-ortası degradasyonu, (b) oturum başına compaction sayısı,
(c) devir sonrası yeniden-okuma maliyeti azaltır — ek maliyeti düşük kalır.

## Baz (K öncesi; kanıt)
- 8 yerel 27B oturumu son context: 32k–57k; 55–57k'lar 64k sınırına yakın.
- ≥5/8 oturumda compaction izi; bazıları görev ortasında (ce857fbf, 280aaa6f, 5709f7d1).
- Compaction sonrası neredeyse her seferinde aynı dosyaların yeniden okunması; 1× yapıyı yanlış hatırlama (280aaa6f).
- Eski veri boşluğu: compaction sıklığı/maliyeti hiç ölçülmemişti (bu deney kuruyor).

## Veri yakalama
1. `metrics/context-snapshots.csv` — **prompt başına 1 satır** (K6):
   `ts_iso, session, task, ctx_start, ctx_end, delta, deg, note`
   Kaynak: `introspection.read_session --project self --session self --limit 1` → header "Current context: N tokens".
   `deg` = o prompt'ta K1 sinyali tetiklendiyse 1; oturum sonunda sınıflandırma: GERÇEK / SAHTE (gerekçe LOG'a).
   **K1 sinyal genişletme (FunkGoth, 2026-10-02)**: "kullanıcı düzeltmesi" (agent hatayı üretti, kullanıcı yakaladı) = deg=1 (1. vaka: 20122→14604 yanlış çerçeveleme — FunkGoth yakaladı).
   **K6 limitasyonu (2026-10-02)**: compaction öncesi tepe agent tarafından YAKALANAMIYOR (otomatik compaction → hemen öncesi snapshot alınamaz); en iyi "önce" = compaction'dan önceki son snapshot. Kullanıcı UI gözlemini verirse csv'ye yaz (vaka: **59k** → K6'nın ilk gerçek veri noktası: compaction etkisi **−44.4k**).
2. **Compaction sayısı = KULLANICI sayar** (agent sayamaz — sınırlılık, rapor §3). Kullanıcı sayıyı LOG oturum satırına yazar.
3. K7 maliyeti: mevcut `runs.csv` (zaten append-only).
4. `metrics/context-ledger.csv` (K9, FunkGoth onayı 2026-10-02): her 100+ satırlık okuma ve her `edit_file` çağrısından sonra 1 satır: `ts_iso,session,dosya,islem,okunan_satir,toplam_satir,bytes,tok_tahmini,kural,gerekce`. **K8 = `echo_bytes`** (edit çıktısının context'e yansıyan maliyeti; ölçüm, karar 10-09). Defterin kendi yazıları deftere yazılmaz. Terk kriteri: olay başına maliyet >300 tok veya 3 gün >%30 turda kayıt eksik.

## Maliyet muhasebesi (haftalık)
- K6: prompt başına 1–2 introspection çağrısı (sn'ler, VRAM YOK — Bionic tarafı).
- K1/K5: devir teklifi sayısı = kesinti sayısı (LOG).
- K3/K4: ek yazı satırı (ihmal edilebilir).
- K7: worker süresi + Mod B geçiş (~17–20s, runs.csv 06).
- **Kural: toplam ölçüm kesintisi oturum süresinin %5'ini geçerse K6 sıklığı düşürülür.**

## K başına terminasyon kriterleri (karar: 10-09)
| K | KALIRSA… (beklenen fayda görülürse) | TERKEDİLİR/DÜZELTİLİRSE… |
|---|---|---|
| K1 | ≥1 GERÇEK degradasyon yakalandı + ≥1 devir hata önledi | ≥2 SAHTE pozitif, 0 gerçek yakalama |
| K2 | ortalama ctx_end, baz (≈47–57k) altına iner; compaction/oturum azalır | eksik okuma nedeniyle ≥1 iş hatası/bilgi kaybı |
| K3 | devir sonrası yeni oturum 0–1 dosya okumasıyla devam etti | devir başarısız: devam >2 tam dosya okuması gerektirdi |
| K4 | büyük çıktı context'i şişirmiyor (nitel + csv) | şikayet/maliyet (düşük maliyetli — varsayılan KALIR) |
| K5 | K1 ile birlikte (alt küme) | K1'e tabi |
| K6 | 10-09'da veri bir karar üretti | kesinti >%5 veya veri hiç kullanılmadı |
| K7 | ≥3 run/hafta ve runs.csv'de net tasarruf | mevcut runs.csv aksiyon eşiklerine tabi |
| K8 | edit yansıma maliyeti nicellendi (ledger echo_bytes); batch-edit kuralı etkili (yansıma/tur azaldı) | olay başına maliyet yüksek + kural işe yaramadı → ölçümü TERK, kuralı KALDIR |
| K9 (defter) | 10-09'da K2/K7/K8 kararları ≥50 veri noktasına dayandı; ≥1 kaçırılmış delegasyon veya ≥1 compaction uyarısı yakalandı | olay başına maliyet >300 tok veya 3 gün >%30 turda kayıt eksik → sadeleştir/terk |

## Karar protokolü (10-09)
1. context-snapshots.csv + LOG deg sınıflandırmaları + kullanıcı compaction sayıları → tek rapor.
2. K başına: KAL / DÜZELT (yeni versiyon notu) / TERK (PROTOCOL'den çıkar + lessons'a gerekçe).
3. Her değişiklik FunkGoth onayıyla (Sabit Kural 2).
4. Bu dosya + csv: deney bitince arşiv; kalan karar DECISIONS'a taşınır.

---
**DURUM: KAPANDI 10-02 (erken)** — nihai kararlar: PROTOCOL/Context Ekonomisi + DECISIONS (2026-10-02 O20 satırı) + `work/2026-10-02-nihai-karar-oturumu/rapor.md`. Bu dosya + csv = **ARŞİV**; 10-09 = gözden geçirme noktası (yeni karar turu değil, kriterlerle yeniden kontrol).
