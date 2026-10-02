# Sistem Baseline (2026-10-01 ölçüldü; son değerlendirme 2026-10-02 — eval-2026-10-02.md)
"Sistemin normalde nasıl" referansı — her Sistem Değerlendirmesinde yeniden örneklenir, fark varsa açıklanır.

| Metrik | Değer | Not |
|---|---|---|
| GPU | RTX 3090 24 GB (24576 MiB) | dedicated |
| VRAM (ana model yüklüyken) | 23704–23770 MiB / 24576 (%96+) | 27B Q4_K_M + 8192 budget; tampon bölgesi zaten sınırlı |
| **VRAM shared (paylaşılan)** | **≈1113–1120 MB — ~990 MB'ı llama-server'ın kendisi** | top_proc.ps1 ile PID bazında doğrulandı (2026-10-01); zemin NORMAL, anomali = delta | 
| GPU kullanımı (oturum aktifken) | %12–96 (dalgalı) | nvidia-smi; ana model aktivitesine göre |
| RAM commit | 49–51 GB / limit 71.1 GB | commit = RAM + pagefile havuzu |
| Pagefile (C:+D:) | **0 MB — boşta** | RAM şu an yeterli; baskıda ilk sıçrayacak yer | 
| RAM boş (dalgalanma) | 12.5–16 GB (2026-10-01, birkaç dk aralık) | ana model aktivitesine göre dalgalanır; worker ≈6.7 GB sığar |
| Ölçüm aracı | capture.ps1 ≈2 sn/çağrı | light çalıştırma = sıfır ek maliyet; full = 2 çağrı ≈4 sn |
| RAM | 31.1 GB toplam / 12.8 GB boş | worker8b ≈ 6.7 GB resident → rahat sığar |
| Worker prefill | ~63 tok/s | run 2026-10-01-02 (7800X3D) |
| Worker eval | ~7–10.4 tok/s | run 02: 7.1 (thinking ON, 585 tok); runs 03–05: 10.2–10.4; DDR5 tavanına yakın → thread/ayarla anlamlı iyileşme yok |
| Ana model (27B) tok/s | ≈17 tok/s (ilk örnek, 2026-10-02) | 32 tok API örneği (wall-time, ~460 tok prefill dahil; thinking ON, 32/32 reasoning; MTP draft 38/kabul 17). LM Studio log yolu standart konumlarda yok → API örneklemesi; her değerlendirmede yeniden örneklenecek |

## Kaynak dağılımı (attribution) — 2026-10-01, top_proc.ps1 ile 2 örneklem
| Yığın | RAM | GPU | Not |
|---|---|---|---|
| **Ana agent yığını** | **7.5 → 10 GB** (llama-server, aktif üretime göre büyür) + Bionic ≈0.8 GB | dedicated 23.7 GB (27B ağırlık+KV) + shared ≈0.99 GB | RAM, sohbet uzadıkça/KV cache ile artar |
| **Sub agent (worker8b)** | boşta **0** (Ollama auto-unload); aktifken ≈**6.7 GB** resident | **0** (CPU-only) | `ollama ps` ile doğrulanır |
| Kullanıcı uygulamaları | ≈4 GB (Discord ~0.5, Opera ~1.5, Steam ~0.4, ChatGPT ~0.3, Claude ~0.3, NVIDIA Overlay ~0.2) | küçük paylar (Discord ~16 MB, Phone ~20, EdgeWebView ~44) | değişken |
| İşletim sistemi | ≈2 GB (Memory Compression ~0.6, Defender ~0.3, explorer ~0.45, sistem) | küçük paylar | — |

Toplam: 31.1 GB RAM'in ≈11–13 GB'ı kullanımda, boş 10.4–12.8 GB (llama-server'ın büyümesine göre dalgalanır). Commit 50.8–53.2 / 71.1 GB.

## Yorum kuralları
- Worker CPU'da → GPU'da beklenen etki: **sıfır** (dedicated delta ~0, ana model hızı değişmez). Sapma = anomali → ara.
- **Taşma (tampon aşımı) göstergesi**: çalışma sırasında `vram_shared` delta **>128 MB** (zemin ≈1.1 GB'in ~%99'u llama-server'ın kendisi — normal dalgalanma sayılmaz) veya llama-server'ın shared payı delta >256 MB.
- RAM baskı eşiği: worker aktifken boş RAM <3 GB veya paging >0 → anomali.
- ~200 kelimelik worker çıktısı ≈ 45–60 sn (eval hız tavanı).
- Aynı anda TEK worker kuralı (VRAM kuralı) worker B'de zaten CPU ile garanti; A/C runtime'larında geçerli.
