# PROTOCOL-optim — SPEK (K1–K9 + Delegation + Routing)

Statü: **TASLAK** (canon = FunkGoth onayı — README §Sabit Kurallar/4). Kuruluş: 2026-10-03 (O23).
KAYNAK: `E:\Bionic\agent\PROTOCOL.md` "Context Ekonomisi (K1–K9)" + "Delegation" bölümleri (NİHAİ 2026-10-02, O20 tam yetki) + `E:\Bionic\agent\handbook.md` (detay).
Bu dosya gerekçeyi, kanıtı ve SPEK'i toplar; **operatif metin PROTOCOL.md'de kalır** (O19 dersi: boot zinciri sağlam kalmalı).
Değişiklik: SPEK güncellenir → operatif metin PROTOCOL'e (FunkGoth onayıyla) → karar DECISIONS + LOG.

## 1. K1–K9 SPEK'i

| # | Kural (operatif metin PROTOCOL'de) | Gerekçe / Kanıt |
|---|---|---|
| K1 | Degradasyon sinyali: aynı oturumda (a) DEĞİŞMEDİĞİNİ BİLDİĞİN dosyayı yeniden okuma, (b) biten adımı yeniden yapma, (c) yol/kısıt karıştırma, (d) STATE çelişkisi, (e) kullanıcı düzeltmesi → "compaction-degradasyon şüphesi" bildir + checkpoint + devir teklifi | 2 GERÇEK deg=1: O18 (kendi verisini yanlış yorumladı, FunkGoth düzeltti) + O19 (boot hatası). Compaction sayacı agent tarafında imkânsız (sınırlılık) |
| K2 | Çıktı hijyeni: varsayılan = `search_file_line` / dar satır aralığı / log kuyruğu; tam dosya okuma istisna + gerekçeli. Batch: aynı dosyaya çoklu düzenleme = TEK çoklu-edit çağrısı; %30+ değişim = replace_file | O18'te 3× STATE edit ≈ 3×~300 tok yansıma (defter K2-batch İHLALİ yakaladı) |
| K2c | append-only CSV'ler (snapshots/ledger/runs) → shell `>>` (sıfır yansıma); edit_file yalnız yerinde düzeltmede | edit_file ile CSV append ~400–600 tok/tur yansıtıyordu (O20 kanıtı) |
| K3 | Checkpoint kalitesi: her adımdan sonra STATE (biten adımlar + açık dosya/bölüm + bekleyen sorular + sonraki somut eylem) | Test = yeni oturum yeniden okumadan devam edebilmeli (O3 devir testi başarılı) |
| K4 | 50+ satırlık üretilen çıktı → `work/` (şimdi: `Docs\ARSIV\`) dosyası; context'e özet + yol | Uzun çıktı context şişiriyor; dosya = kalıcı kayıt |
| K5 | Bir prompt içinde K1 ≥1 kez tetikleniyse → prompt bitiminde devir teklifi | O19 boot hatası sonrası devir zinciri sorunsuz çalıştı |
| K6 | Ölçüm: ARAÇ KULLANAN her prompt sonunda (saf sohbet muaf) `introspection.read_session` → "Current context" → snapshots.csv (shell `>>`) | Limitasyon: compaction tepe yakalanamaz (en iyi "önce" = önceki snapshot) |
| K7 | 100+ satır okuma/özetleme → Worker B (Mod A varsayılan; küçük dosyalar muaf); ana agent doğrular | CPU worker sıfır geçiş maliyeti (runs.csv 01 koexist); kalite: run 02'de 2 sapma ana agent yakaladı |
| K8 | (K9'a birleşti) edit yansıma maliyeti = defterin `tok_tahmini` sütunu | Ayrı kural gereksiz (O20) |
| K9 | Defter: kapsam = (a) 100+ satır okuma, (b) 50+ satır/tam dosya edit, (c) K ihlali; küçük pencere muaf; turn sonunda TEK shell append; self-audit: "loglanacak olaylar defterde mi?" | O23'te ihlal VAKASI: O23'ün ilk turu 100+ satır okudu, defter satırı kalmadı → K9 self-audit'inin hedefi (telafi satırı + ihlal kaydı) |

**10-09 gözden geçirme** (yeniden karar DEĞİL): `data\metrics\context-benchmark.md` kriterleriyle veri yeniden kontrol + FAZ 2 raporu + Ö3.

## 2. Delegation SPEK'i (kompakt — detay: `E:\Bionic\agent\handbook.md`)

- Runtime A: qwen3.8-27B Bionic API (`http://localhost:1234/api/v0/chat/completions`; `/api/v1` 404; JSON `Content-Type` zorunlu — 415 dersi) — YALNIZ FunkGoth GO'su.
- Runtime **B (varsayılan)**: worker8b (qwen3:8b, 5.2 GB) Ollama `http://localhost:11434/api/chat`; `model: worker8b`, `stream:false`, **`think:false`** (kanıt: 41s→3.7s), `num_gpu 0` (CPU), `num_ctx 8192`, `temperature 0.3` — 100+ satır özet/çıkarım/taslak, kaba tarama.
- Runtime C: yeni Bionic sohbet (tam agent, araçlı) — FunkGoth açar; brief'i ana agent yazar.
- Brief → `E:\Bionic\Project Optim\data\delegation\brief-<konu>.md` (amaç + kapsam + parçalar + çıktı formatı/kelime limiti + "çözülmüş/kapalı kararlar" + "reddedilen maddeyi yeniden önerme") → result ≤200 kelime → `result-<konu>.md`.
- Worker'ın aracı YOK → gerekli dosya parçaları brief'e gömülür. Ana agent her result'ı doğrular.
- **VRAM kuralı (sert)**: 24 GB kart = aynı anda TEK GPU worker; 27B + CPU worker koexist KANITLI.
- **Mod B (GPU batch)**: yalnız unattended; sıra = worker evict (`keep_alive:0`) → `lms unload` → 2×GPU worker → 27B JIT reload (VRAM boşken **17.44s**; çakışmada 317.7s = kuralın kanıtı). Break-even ≈200–250 output tok.
- Hız (ölçülmüş): CPU 10.2–10.4 tok/s (DDR5 tavanı) · GPU solo warm 101.9–108.1 tok/s (~10x) · 27B ana ~17 tok/s ilk örnek (Ö3: her değerlendirmede yeniden örnekle → `data\metrics\baseline.md` bant).

## 3. Routing Haritası (nihai 10-02)
- **27B ana**: karar / diyalog / mimari / kısa okuma / dosya işi / doğrulama.
- **worker8b CPU (Mod A)**: 100+ satır özet/çıkarım/taslak — sıfır geçiş maliyeti (varsayılan delege hedefi).
- **Mod B (GPU)**: unattended paralel batch.
- Boşluk (KANIT): routing kararlarının kaydı yok (27B'de kendim yaptıklarım runs.csv'de değil) → entegrasyon çalışmasında routing alanı eklenecek.

## 4. Proje Çalışma Kuralları
1. Agent bu projeyi **toplu yönetir**: kurallar (SPEK) + veriler + politikalar + arşiv burada tek sorumlulukta.
2. FunkGoth: "araştır → test et → uygula" + onay-verici. Onaysız silme/geri alınamaz işlem YOK (Sabit Kural 2).
3. Veri işlemleri `Docs\DATA-POLICY.md`'ye tabidir (append-only CSV'ler shell `>>`; edit_file YALNIZ yerinde düzeltmede).
4. Oturum kapanışı: STATE/TASKS/LOG (agent hafızası) + bu projede veri kaydı (runs/snapshots/ledger) + git commit (bu repo).
5. Araştırma çıktısı önce `Docs\ARSIV\<yıl-ay-gün>-<konu>\` dosyası, sonra gerekirse SPEK/politika güncellemesi (öneri → FunkGoth onayı).
