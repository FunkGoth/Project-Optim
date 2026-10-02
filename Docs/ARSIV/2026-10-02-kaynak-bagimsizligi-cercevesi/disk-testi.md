# Disk Hızı Ölçümü (Oturum 14 — 2026-10-02)

ONAY: FunkGoth (tüm diskler; C/D = hızlı M.2 SSD). Amaç: JIT reload 317.7s'in disk kaynaklı olup olmadığını teyit (normal reload ~10s — kullanıcı gözlemi).

## Donanım envanteri
| Sürücü | Disk | Arayüz | Kapasite | Boş |
|---|---|---|---|---|
| C: | Samsung SSD 980 PRO (Heatsink) | NVMe (SCSI) | 930 GB | 223 GB |
| D: | Viper VP4300L | NVMe (SCSI) | 1862 GB | 406 GB |
| E: | SPCC Solid State Disk ("Depot") | IDE (sabit) | 1908 GB | 1908 GB (BOŞ) |

RAM: **32 GB**. GPU: RTX 3090 24 GB. CPU: Ryzen 7 7800X3D.

## Benchmark (8 GB, 64 MB chunk, tek dosya)
| Sürücü | WRITE 8 GB | READ-WARM 8 GB |
|---|---|---|
| C: | **937 MB/s** (8.7 s) | 9471 MB/s (0.9 s — RAM cache) |
| D: | **1687 MB/s** (4.9 s) | 3461 MB/s (2.4 s) |
| E: | **323 MB/s** (25.4 s) | 417 MB/s (19.7 s) |

Not: READ-WARM değerleri önbellekten (RAM) beslenir → disk hızını değil tavanı gösterir. C:'nin 9471 MB/s'i net RAM hızı.

## Model dosyası (JIT reload'un okuduğu dosya)
- Konum: `C:\LM-Models\lmstudio-community\Qwen3.8-27B-GGUF\Qwen3.8-27B-Q4_K_M.gguf`
- Boyut: **15.66 GB** (+ mmproj-Qwen3.8-27B-BF16.gguf 0.87 GB) — **C: diskte**
- Tam okuma: **3587 MB/s → 4.47 s** (ilk 64 MB: 28 ms)

## SONUÇ
1. Model C:'de (980 PRO); tam disk okuması **~4.5 s**. Önbellek tavanı ~9.4 GB/s.
2. Makinedeki **en yavaş** disk (E:, 417 MB/s) bile modeli **~38 s**'de okur.
3. **Hiçbir disk senaryosu JIT reload 317.7s'i açıklayamaz** → "17.7 GB disk okuması sınırlı" atfı (Oturum 13 LOG) BU VERİYLE ÇÜRÜTÜLDÜ.
4. 317.7s'in gerçek nedeni disk DIŞINDA: (a) 2×worker8b GPU'da VRAM tutarken 27B'nin yeniden yüklenmesi (VRAM çakışması → kısmi CPU offload), (b) 317.7s'in istek→ilk token wall-time olması (kuyruk + load + ilk decode), (c) CPU/RAM thrashing. → #1 tartışmasına girdi.
5. E: (SPCC) yavaş disk (C/D'nin 3–10× altı) — model/worker E:'ye taşınsa hız kaybı orada olur; C/D her ikisi de hızlı NVMe.

## Kısıt / dürüstlük
- 3587 MB/s model okuması kısmen warm olabilir (27B şu an Bionic'te resident). Tam cold biraz yavaş olabilir; ama ~38 s (en kötü E:) ile ~4.5 s (C:) aralığının ötesine geçmez → 317.7s yine açıklanamaz.
- Test dosyaları (bench8g.bin) her diskte ölçüm sonrası SİLİNDİ (agent scratch).
