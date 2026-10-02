# Agentic Çalışma Araştırması — Qwen3.8-27B + 24GB VRAM (2026-10-03, O22)

**Soru (FunkGoth):** Mevcut model + donanımda agentic iş mümkün mü? Ne kadar karmaşık iş yaptırılabilir? Yapılan optimizasyonlar (K1–K9, worker devir, defter) sonuç verir mi?

## 1) Model yeteneği (kullanılan model: Qwen3.8-27B Q4_K_M, 262k context)
- **Artificial Analysis (3. taraf):** Intelligence Index **52**, Agentic Index **51** — AA'ya göre Claude Opus 4.8 (max reasoning) agentic'te geçilmiş (VentureBeat, 2026-08).
- **Alibaba self-report (harness farklılığı uyarısıyla):** SWE-bench Pro **61.7** (Opus 4.6 Max'ı geçtiğine göre), LiveCodeBench v6 90.3, OSWorld-Verified 84.3. Terminal-Bench/GPQA'da Opus hâlâ önde.
- **Bağımsız kullanım kanıtı (Simon Willison):** M5 Max / DGX Spark'ta Q4_K_M ile coding-agent döngüsü (Pi framework) çalıştırdı; kod tabanında navigasyon + araç yazımı + test. → "tek oturumluk agentic iş" 27B'de **kanıtlanmış**.
- **Bilinen zayıflık — overthinking:** AA testinde 160M output token (aynı sınıf medyan 43M'in ~4x'i); basit SVG isteğine 21 dk + 22k reasoning token; Tunguz 9-görev testinde reasoning açık = ~30x yavaş. **Kilit: reasoning seviyesi işe göre (rutin adım = low/none, karar anı = high).**

## 2) Donanım gerçekleri (24GB VRAM)
- Q4_K_M ~17GB → sığar (bizde 15.66GB). KV cache + 64k pencere bütçemizi belirliyor (model 262k destekliyor; pencere = Bionic/harness limiti, model limiti DEĞİL — genişletme KV maliyetiyle test edilebilir bir kaldıraç).
- Hız: Willison LM Studio varsayılanında 15–30 tok/s; **MTP (Multi-Token Prediction) llama.cpp'te +72%** (DGX Spark). Bizde 27B ~10 tok/s sınıfı → **agentic döngüde baskın maliyet = output hızı**, her tool adımı saniyeler~dk.
- Sonuç: agentic iş **mümkün**, ama "dakika cinsinden" bütçeyle; interaktif döngüde işçi sayısı değil, 27B'nin adım hızı darboğaz.

## 3) Karmaşıklık tavanı (kanıtlarla)
- **Güvenli bölge (kanıtlanmış):** tek kapsamlı modül/bug-fix, araç yazımı+test, kod tabanı okuma-açıklama, doküman üretimi, devir zinciriyle çok oturumluk iş (bizim O12–O21 pratik kanıtı + Willison).
- **Orta bölge:** 2–3 dosyalı özellik, testli refactor → mümkün; K3 checkpoint + devir belgesi zorunlu (O18 compaction'da kayıpsız devam = kanıt).
- **Zor bölge:** saatler süren otonom multi-modül → 2026 literatüründe küçük-orta modellerde hâlâ kırılgan: ACM (2026-08) 9B SWE-bench Verified baseline **%48.9** (59k peak context); 27B bunun üstünde ama uzun ufukta **context management +8–27 puan** fark yaratıyor (aşağıda) — yani tavan, modelden çok **context yönetimiyle** belirleniyor.
- SWE-bench Pro (long-horizon SE) self-report 61.7 → "çok adımlı, gerçek repo" işleri 27B'nin ulaşabildiği bölge; bağımsız doğrulama hâlâ sınırlı.

## 4) Context/compaction literatürü (optimizasyonlarımızın karşılaştırması)
| Bulgu | Kaynak | Bizdeki karşılığı |
|---|---|---|
| Context rot: alakasız çıktı/tekrar okuma birikince sessiz kalite düşüşü | Anthropic engineering blog (via Zylos 2026-04) | **K2 (dar okuma) + K2c (sıfır yansıma) — doğrudan hedef bu** |
| Lost-in-the-middle: orta context bilgisi >30 puan kayıp (20 doküman QA) | Liu 2024 (via Zylos) | K3 checkpoint: kritik bilgi STATE'te = context'in BAŞINDA/SONUNDA |
| Summarizer'ların hepsi "artifact tracking"te zayıf (2.19–2.45/5, 36.6k prod mesaj) | Factory.ai 2026 | **Devir belgesi + STATE + defter = tam olarak artifact izleme; literatürün zayıf noktasını çözüyoruz** |
| Girişim AI görev başarısızlıklarının ~%65'i context drift/memory loss (token tükenmesi değil) | 2025 endüstri anketi (via Zylos) | Ana risk model yeteneği değil, context ekonomisi → optimizasyon yönü DOĞRU |
| Context management küçük modelde +27%/+16%/**+8%** (BrowseComp/DeepSearch/SWE-bench V) + ~20% peak token düşüşü; küçük modeller context yönetiminden BÜYÜK modelden fazla kazanır (daha çok keşif yapmaları gerekir) | ACM arXiv:2607.23809 (2026-08, 9B üzerinde) | **Doğrudan kanıt: bizim K kuralları + worker özetleme sınıfı işe yarar; 8B worker = özetleyici olarak sınırda ama uygun (ACM uyarısı: "çok küçük model birkaç turda tutarlılığı kaybeder" → worker'a ajan değil, özetçi/taslakçı rolü — bizim routing zaten böyle)** |
| Compaction, güvenlik/kural kısıtlarını da silebilir ("governance decay"); compaction zinciri degradasyonu henüz ölçülmemiş (açık problem) | arXiv:2606.22528 (2026) | K1 deg sinyali + devir belgesinde "kapatılmış kararlar" alanı = tam bu riskin panzehiri; snapshots/ledger ile compaction zinciri ölçümü yapıyoruz — **literatürde bu ölçüm yok, bizde var (öncü konum)** |

## 5) Optimizasyonlarımız sonuç verir mi? — ANALİZ
- **Evet, yön olarak literatürle örtüşüyor ve kanıt bulutu lehimize:**
  1. K2/K2c/K4 (yansıma azaltma, dar okuma, dış dosya) = "context rot" ve "artifact tracking" literatürünün önerdiği tam şeyler.
  2. Worker 8B = özetçi/çıkarım (ACON/ACM sınıfı) → ACM: küçük modelde context management +8–27 puan; bizim routing (8b'ye ajan rolü VERMEMEK) doğru.
  3. Devir/STATE/defter = Factory.ai'nin "en zor ve en önemli" artifact tracking'i; O18/O20 vakaları pratik kanıt.
  4. K1 deg sinyali = "governance decay" riskinin erken uyarısı.
- **Nicel beklenti (dürüst):** +8% (SWE-bench V, ACM) bizim en yakın analoğumuz; kendi runs.csv/ledger verimizle 10-09'da ölçülecek.
- **Kaldıraç SIRALAMASI (araştırma bulgusu):**
  1. **Reasoning seviyesi kontrolü** — en büyük hız/kalite kaldırağı (30x iddiası + 22k tok/istek overthinking). Rutin adım low, karar anı high. (Bionic'te model ayarı — FunkGoth/FunkGoth-test)
  2. **MTP (Multi-Token Prediction)** — llama.cpp'te +72% raporlu; Bionic'in Qwen3.8-27B için MTP destekliyor mu? Kontrol edilmeli.
  3. Context penceresi 64k→128k (model 262k destekliyor) — compaction sıklığını düşürür; KV VRAM maliyeti 24GB'da ölçülmeli (worker/27B paylaşımını sıkıştırır).
  4. Kural seti (K1–K9) — kalite/kayıp önleme (yukarıda); hız değil, GÜVENLİK kazancı.
  5. Mod B paralellik — interaktif agentic işte darboğaz OLMAYAN taraf; unattended batch için kalsın.

## 6) Sınırlılıklar (kaynak notu)
- SWE-bench Pro/LiveCodeBench 27B sayıları Alibaba self-report; AA Agentic 51 3. taraf ama composite.
- ACM/ACON sonuçları 9B üzerinde; 27B'ye doğrudan genellenemez (yön genellenir).
- 30x/21dk rakamları anekdotal (9 görev / 1 istek).
- Kaynaklar: VentureBeat 2026-08-18 · arXiv:2607.23809 (ACM) · arXiv:2606.22528 (Governance Decay) · Zylos Research 2026-04-21 (Factory.ai, Anthropic, ACON, LLMLingua-2 derlemesi) · arXiv:2510.00615 (ACON) · llm-stats/AA.
