# DATA-POLICY — Veri İşleme Politikası

Statü: **TASLAK** (canon = FunkGoth onayı). Kuruluş: 2026-10-03 (O23).
Kapsam: `data\` altındaki tüm veri (metrics, delegation, model-hafiza) + `Docs\` statüleri.

## 1. CSV Şemaları (append-only — satır silinmez/değiştirilmez; hata → üstüne yeni satır + not)

**`data\metrics\context-snapshots.csv` (K6)**
`ts_iso,session,task,ctx_start,ctx_end,delta,deg,note`
- Kaynak: `bionic_tool introspection.read_session --project self --session self --limit 1` → "Current context: N tokens".
- Zamanlama: ARAÇ KULLANAN her prompt sonunda (saf sohbet muaf); yazım = shell `>>`.
- Limitasyon: compaction TEPE yakalanamaz (otomatik compaction → hemen öncesi snapshot alınamaz); en iyi "önce" = compaction'dan önceki son snapshot.
- `deg`: 1 = degradasyon sinyali (K1); kullanıcı düzeltmesi = deg (O18 kararı).
- Kullanıcı verisi: compaction sayıları FunkGoth girer (agent sayamaz — K6 sınırlılığı).

**`data\metrics\context-ledger.csv` (K9 defteri)**
`ts_iso,session,dosya,islem,okunan_satir,toplam_satir,bytes,tok_tahmini,kural,gerekce`
- Kapsam: (a) 100+ satır okuma, (b) 50+ satır/tam dosya edit, (c) K ihlali; küçük pencere editleri MUAF.
- `tok_tahmini`: edit yansıma (echo) tahmini (K8 birleşik alan); ölçüm: edit ~400–600 tok/tur (tam dosya yansıması).
- Yazım: turn sonunda TEK shell append (K2c). Self-audit: "loglanacak olaylar defterde mi?" (K3 denetimi).

**`data\metrics\runs.csv`**
31 kolon (light + full alanları; light'ta N/A boş); şema: `data\metrics\README.md` §"runs.csv alanları".
- light: run_id, date, task, model, runtime, prompt_tok, prompt_tps, eval_tok, eval_tps, duration_s, load_s, sample_type, main_model_impact, quality_verdict, accepted, notes
- full ek: ram_free/avail/commit before/after, vram_ded/shared before/after, gpu_util before/after, paging before/after, capture_overhead_s
- Kurallar: her satır 31 kolonluk header ile; kalite = ana agent doğrulaması; run_id result dosyası başlığına yazılır.

## 2. Append Kuralları (K2c)
- append-only CSV'ler YALNIZ shell `>>` (sıfır yansıma); `edit_file` YALNINZ yerinde düzeltmede (mevcut satırın yanlış verisini düzeltme — gerekçe notu ile).
- Tam dosya okuma + yazma (replace) YASAK — yansıma maliyeti ~400–600 tok/tur (O20 kanıtı).
- Her CSV satırı kendi `ts_iso`'sünü taşır; saat dilimi `+03:00` (yerel).

## 3. Light / Full Örneklem Eşikleri (runs.csv)
- **light**: her worker run'ında, sıfır ek maliyet (API yanıt JSON'ından: prompt/eval tok, tok/s, süre, load).
- **full**: light + çağrı **önce/sonra** `capture.ps1` (VRAM dedicated+shared, RAM free/avail/commit, pagefile, GPU util).
- Politikalar (2026-10-02 NİHAİ, O20):
  - run <30s → light varsayılan (kanıt: run 04 capture_overhead %14 > %10 eşiği → Ö1 önerisi).
  - full: yeni iş tipi İLK + ~1/3 rastgele + anomali sonrası MUTLAKA.
  - önceki run'da `main_model_impact ≠ none` → sonraki MUTLAKA full.
  - VERİ TOPLAMA HAFTASI 2026-10-02→10-09 (Ö2 genişletilmiş, ONAYLI): light daima; full = yeni iş tipi ilk + ~%50 rastgele (deterministik: run_id çift → full); hafta sonunda <3 full varsa tamamlanır.
- **Ö3 (ONAYLI)**: her Sistem Değerlendirmede ana model ~32 tok API örneği → `baseline.md` bant (tek nokta değil).
- Aksiyon eşikleri + yakalama protokolü: `data\metrics\README.md`.

## 4. Retention / Arşiv Politikası
- **Veri dosyaları (CSV)**: append-only; silinmez. Eski veriler arşiv olur ama kayıtlı kalır.
- **Çalışma klasörleri**: biten iş → `Docs\ARSIV\<yıl-ay-gün>-<konu>\` (O23'te 5 klasör taşındı); `agent\work\` yalnız aktif işler.
- **Raporlar** (`eval-*.md`, `arastirma.md`, `rapor.md`): ARŞİV (karar kaynağı DECISIONS; rapor kanıt).
- **Sessiz silme YOK**: her silme/taşıma = FunkGoth onayı + LOG kaydı (Sabit Kural 2).
- **LOG.md** (agent): global bütçeden ÇIKMIŞ (arşiv); yumuşak tavan 300 satır, 350'de FunkGoth'a sorulur, sessiz silme yok.

## 5. Canon / Sahiplik
- `Docs\` dosyaları (bu proje dahil, EmberTale dahil) = **kullanıcı malı**; agent önerir, FunkGoth onaylar.
- Onaysız içerik "canon" ilan edilemez; "Kaynak: …" satırı sahiplik kanıtı DEĞİL (EmberTale skill §2 dersi).
- Agent hafızası (`E:\Bionic\agent\`) = agent'ın kendi tasarımı (kullanıcı müdahale edebilir); bu politika agent hafızası için BAĞLAYICI, Docs/ için ÖNERİ statüsündedir (canon'a dönüş = FunkGoth onayı).

## 6. Tespit Mekanizması — "Sessiz Stop" (YENİ, O23)
**Boşluk (kanıt):** "sessiz stop" (agent mesaj üretmeden durma; FunkGoth ekran görüntüsü, O21 olayı) snapshot/ledger'a düşmüyor — agent durduğunda kayıt yapacak canlı adım yok. O21 vakası kayıtlarda YOK (devir-sorusturmasi.md: kesin 2 vaka O6→O7 + O20 62k; O21 = kullanıcı kanıtlı 3. vaka, sistem kaydı yok).
**Mekanizma (öneri — canon = onay):**
1. Oturum BAŞINDA (Oturum Başlangıcı adım 1.5): önceki oturumun LOG satırı var mı? LOG satırı YOK ama sohbet geçmişinde kapanış yoksa → **sessiz stop şüphesi** → FunkGoth'a bildir + LOG'a kayıt (alt sınır güncellenir).
2. K6 snapshot'ı "oturum başı" değil "turn sonu" olduğu için: LOG'daki son oturum kaydı = session-end işaretçisi olarak kullanılır.
3. Her sessiz stop tespiti → context-ledger.csv satırı (kural = K6-boşluk, gerekçe = tespit) + LOG.
**Alt sınır (2026-10-03):** 2 KESİN (O6→O7 LOG; O20 62k — kullanıcı kanıtlı, kayıtlarda yoktu) + ~5 sebep-kayıtsız devir + O21 (sistem kaydı YOK) → **kayıt alt sınırı = 3, gerçek sayı bilinmiyor** (kayıt boşluğu dürüstçe raporlanır).
