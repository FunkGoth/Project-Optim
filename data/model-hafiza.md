# Model Hafızası — İş → Model Bilgisi
Oluşturma: 2026-10-02 (Oturum 11) — FunkGoth kavramı "kullanım hafızası"nın somut hâli.
Kural:
- `metrics/runs.csv` = ham veri; **bu dosya = distille bilgi** (iş tipi → model → sonuç).
- Her worker run'ı + her yeni model buraya işlenir; routing kararı bu dosyaya bakar.
- Yeni modelde ÖNCE benchmark beklenti satırı (kaynak + skor), SONRA test sonucu → beklenti vs gerçek karşılaştırması.

## qwen/qwen3.8-27b (Q4_K_M) — ANA MODEL
- Konum: LM Studio :1234 | Boyut: ~17.7 GB | Ayak izi: ~23.7 GB VRAM (ctx dahil)
- Benchmark beklenti: — (ana model; kalite kanıtı = kullanıcı tatmini)
- İş sonuçları:
  - Agentic döngü (tüm oturumlar 10-01→10-02): büyük tatminlik (FunkGoth)
  - Hız: ≈17 tok/s (ilk örnek; Ö3 bandı bekleniyor)
- Karar: **ana model KALIYOR** (FunkGoth onayı, 10-02). Boşta VRAM'i boşaltılacak (L1).

## qwen3:8b → worker8b (Q4_K_M)
- Konum: Ollama :11434 | Boyut: 5.2 GB | GPU: 0 (CPU-only, num_gpu 0)
- Benchmark beklenti: — (doldurulacak: lmarena / artificialanalysis)
- İş sonuçları:
  - T7 raporu incelemesi (10-01): kalite kabul (2 sapma, ana agent düzeltti), 7.1 tok/s, 148 s
  - Kısa özet (10-01): 10.2–10.4 tok/s, 41 s, PASS
  - think:false (10-01): 11x hız (41 s → 3.7 s), kalite korundu
  - GPU solo (10-02, L1-B + W1): warm **~102–108 tok/s** (CPU 10.7'nin ~10x); VRAM'de 6.3 GB (evict = `keep_alive:0`)
- Karar: hafif işler (tarama/özet/tek adım) ✅ · derin agentic ❌ · **Mod B (ONAYLI 10-02): GPU devri = önce `lms unload`, unattended eşik yok; reload öncesi daima evict**

## gemma4:26b (Q4_K_M)
- Konum: Ollama :11434 | Boyut: 18.7 GB | 27B ile aynı VRAM sınıfı (maliyet avantajı yok)
- Benchmark beklenti: — (doldurulacak)
- İş sonuçları: — (test edilmemiş)
- Karar: kalite karşılaştırması adayı (27B vs 26b)

## (Kütüphane — FunkGoth indikçe eklenecek)
Her model için: konum · boyut · kuantizasyon · benchmark beklenti (kaynak+skor+tarih) · iş sonuçları · karar.
<EOF>