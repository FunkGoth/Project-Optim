# metrics — Performans Veri Havuzu
Kuruldu: 2026-10-01 (FunkGoth onayı: otonom sub-agent kullanımı + günlük sistem değerlendirmesi).
Genişletildi: 2026-10-01 (FunkGoth: genişletilmiş telemetri — VRAM shared/tampon, RAM commit, pagefile; random örneklem + ölçüm maliyeti takibi).
Sorumlu: ana agent (kayıt + değerlendirme); FunkGoth raporları okur, aksiyonları onaylar.

## Dosyalar
| Dosya | Görev |
|---|---|
| runs.csv | Worker çalıştırma kayıtları (append-only; 1 satır/çalıştırma — satır silinmez/değiştirilmez; hata → üstüne yeni satır + not) |
| capture.ps1 | Sistem ölçüm aracı (1 JSON satırı: RAM free/avail/commit, pagefile, GPU dedicated+shared, util) — `powershell -NoProfile -ExecutionPolicy Bypass -File E:/Bionic/agent/metrics/capture.ps1` (≈2 sn) |
| top_proc.ps1 | Kaynak dağılımı (attribution): RAM en büyük 25 süreç + shared GPU PID bazında — ana agent / sub agent / kullanıcı / OS ayrımı (≈2–7 sn) |
| baseline.md | Sistem baseline'ı; her Sistem Değerlendirmesinde yenilenir |
| eval-YYYY-MM-DD.md | Sistem Değerlendirmesi raporu (FunkGoth onayıyla üretilir, 24s'de ≤1) |

## Örnekleme politikası (FunkGoth: random + farklı iş ağırlıkları)
- **light (her çalıştırmada, sıfır ek maliyet)**: prompt/eval tok + tok/s, süre, load (API yanıt JSON'ından) + kalite puanı + accepted.
- **full (örnekleme)**: light + çağrının **önce/sonra** capture.ps1 (VRAM dedicated+shared, RAM free/avail/commit, pagefile, GPU util).
  - **VERİ TOPLAMA HAFTASI (2026-10-02 → 2026-10-09, FunkGoth onaylı Ö2 genişletilmiş)**: light daima; full = yeni iş tipi ilk + **~%50 rastgele** (deterministik: run_id çift → full) — süre farketmeksizin; hafta sonunda <3 full varsa tamamlanır. Amaç: iş tipi → kaynak/süre/kalite haritası + model geçişi/kaynak öngörüsü girdisi; hafta sonu rapor + mekanizma optimizasyon tartışması.
  - 2026-10-09 sonrası (varsayılan politika): run <~30s → light varsayılan; full yalnız yeni iş tipi ilk/anomali şüphesi (Ö1, 2026-10-02);
  - önceki çalıştırmada `main_model_impact ≠ none` ise sonraki **mutlaka** full;
  - **Hedef: ≥3 yapılandırılmış full örnek** biriktir (Ö2 — ONAYLI 2026-10-02, genişletilmiş: 1 hafta rastgele full) → etkileşim trend yorumu + kaynak haritası için.
  - FunkGoth her çalıştırmada light/full açıkça isteyebilir.
- **Ölçüm maliyeti**: full çalıştırmada capture çağrı süreleri `capture_overhead_s`'e yazılır → maliyet izlenir ve raporlanır.
- **Ö3 (ONAYLI 2026-10-02)**: her Sistem Değerlendirmesinde ana model hızı ~32 tok API örneğiyle ölçülür (wall-time + eval tok/s, thinking modu not edilir) → `baseline.md` tek nokta yerine **bant** olarak güncellenir. Yol: LM Studio yerel sunucusu, OpenAI-uyumlu API (`localhost:1234/v1/chat/completions`).

## runs.csv alanları
- light: run_id, date, task, model, runtime, prompt_tok, prompt_tps, eval_tok, eval_tps, duration_s, load_s, sample_type, main_model_impact, quality_verdict, accepted, notes
- full ek: ram_free_gb_before/after, ram_avail_gb_before/after, ram_commit_gb_before/after, vram_ded_mb_before/after, vram_shared_mb_before/after, gpu_util_before_pct/after_pct, paging_mb_before/after, capture_overhead_s

## Yakalama protokolü
1. **light**: `curl -s -d @payload.json http://localhost:11434/api/chat` → yanıt JSON: `prompt_eval_count/duration`, `eval_count/duration`, `load_duration`.
2. **full**: çağrı **önce** capture.ps1 (JSON'ı sakla) → çağrı → **sonra** capture.ps1 (JSON'ı sakla) → diff'ler CSV'ye.
3. **Kalite**: ana agent result'ı doğrular → `quality_verdict` + `accepted`.
4. runs.csv'ye satır ekle + result dosyasının başlığına run_id yaz + git commit (E:\Bionic\agent).
5. **Her satır 31 kolonluk header ile yazılır** (light veya full fark etmez); N/A alanlar boş bırakılır — eski 16 kolonlu düzen KULLANILMAZ (2026-10-02 şema hatası dersi, eval-2026-10-02.md §4).

## Yorum kuralları (anomali tespiti)
- **VRAM tampon/aşım**: dedicated 23.7+/24.5 GB (%96+) ana modelin normal durumu; shared zemin ≈1.1 GB'in ~%99'u llama-server'ın kendisi (top_proc.ps1). **Taşma = çalışma sırasında vram_shared delta >128 MB** veya llama-server shared payı delta >256 MB (anomali, notes'a); aksi → `none`.
- **RAM dalgalanma**: worker resident ≈6.7 GB; çalıştırmada boş RAM <3 GB → baskı riski (paging'e bak).
- **Paging**: çalıştırmada paging >0 = RAM baskısı (worker + ana + sistem RAM'e sığmıyor) → kaydedilir.
- **Ana modele etki**: GPU dedicated delta <128 MB ve shared delta 0 → `none`; değilse `minor`/`major` (neden notes'a).
- **Ölçüm maliyeti**: capture_overhead_s >10 sn veya çalıştırma süresinin >%10'u → raporda işaretlenir; kalıcıysa full örnek oranı düşürülür.

## Sistem Değerlendirmesi (24 saatte 1)
- **Tetik**: yalnızca FunkGoth onayı. STATE'te "son_değerlendirme"; >24s ise yeni oturumda kullanıcıya sorulur.
- **Girdiler**: runs.csv (tümü) + LOG son bölüm + lessons + LM Studio server log örneği (ana model tok/s — salt okunur) + baseline.md.
- **Çıktı**: `eval-YYYY-MM-DD.md` — 5 bölüm: 1) Worker hız/kalite trendi · 2) Ana model durumu · 3) Etkileşim (VRAM dedicated+shared / RAM commit / pagefile) · 4) Havuz kalitesi (eksik alan, ölçüm hatası, **ölçüm maliyeti**) · 5) Öneriler (≤3, öncelikli) → FunkGoth'a rapor.
- **Aksiyon eşikleri (otomatik kontrol)**:
  - worker eval <4 tok/s → içerik/yük çakışması ara;
  - kalite "failed" ×2 aynı iş tipi → o iş tipini B'den çıkar (ana modele dön);
  - VRAM dedicated delta >256 MB veya shared delta >0 → `num_gpu 0` doğrula / taşma kaynağını ara;
  - çalıştırmada paging >0 → worker resident/ctx denetimi;
  - aynı runs.csv alanı 3 kez boş → yakalama protokolünü düzelt;
  - capture_overhead >%10 → full örnek oranını düşür.
- **Kapanış**: STATE "son_değerlendirme" güncellenir; öneriler FunkGoth'a raporlanır; git commit.
