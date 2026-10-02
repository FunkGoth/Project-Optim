# Kaynak Bağımsızlığı + Model Geçiş Stratejisi

Başlangıç: 2026-10-02, Oturum 10 (FunkGoth: B — çerçeveyi şimdi kuralım, veriyi sonra dolduralım)
v2 (2026-10-02): asıl istek netleşti → L1–L4 kaynak stratejisi
v3 (2026-10-02, Oturum 11): FunkGoth 4 soruyu cevapladı + amacı genişletti → strateji yeniden çerçevelendi: **27B ana model KALIYOR**; hedef = paralel iş yeteneği + kaynak verimliliği + kullanım hafızası + context ekonomisi.
İlişkili iş: TASKS "Kaynak bağımsızlığı + model geçişi yeteneği"
Veri: `metrics/runs.csv`, `metrics/baseline.md`, `metrics/eval-2026-10-02.md`
Donanım: Ryzen 7 7800X3D / 32 GB RAM / RTX 3090 24 GB

## Amaç (FunkGoth tarafından netleştirildi, 2026-10-02 Oturum 11)
1. **Kaynak rahatlatma + verimlilik**: sınırlı kaynaklarla (24 GB VRAM) verimliliği artırmak; sistem kullanıcıyı (oyun/iş) rahatlasın.
2. **Paralel iş yeteneği** (bir sonraki ana adım): ne kadar paralel iş, kaç ajan yönetebildiğini öğren; işler bittikten sonra dönen veriyi işlerken "nihai tüm sistem kaynağını ne zaman kullanacağını" öğren; gerektiğinde kendini uyandır.
3. **Context ekonomisi** (en büyük kısıt = context penceresi): paralel ajanlarla ana context daha optimize kullanılır; ana modele ham veri değil **İŞLENMİŞ veri** döner → daha az maliyet. Bu katman context-dolma problemimizi çözer.
4. **Kullanım hafızası** (FunkGoth kavramı): iş → model eşleştirmelerini zamanla biriktir, zenginleştir, ona göre yönlendir → hem verimlilik hem kendi gelişim hızı artar.
5. **Model kütüphanesi** (FunkGoth planı): çeşitli modeller + kuantizasyonlar indirilecek; her modelin ön bilgisi güvenilir benchmark kaynaklarından → testten önce beklenti belli olacak.
6. **27B ana model KALIYOR**: FunkGoth 27B'den büyük tatminlik aldı ("nerdeyse her işte"). Eski L3 ("8b ana") bu yönünden ÇIKTI; sorun 27B'nin kalitesi değil, boşta VRAM tutması ve paralelliği kısıtlaması.

## FunkGoth'un 4 Cevabı (Oturum 11)
1. Hedef: kaynak rahatlatma + verimlilik + paralel iş yeteneği + mekanizmaları geliştirme.
2. Gözlem detayı: worker testinin (148 s) başladığı AN — GPU BELLEK 23 GB → **2–3 GB** ("boş değerler"), GPU KULLANIM %85–90 → **~%5**. Tekrar test edebiliriz; gözlemi o yapacak.
3. LM Studio auto-unload: **KAPALI** (gözlemi: işlem yokken VRAM dolu kalıyor, sadece kullanım/fan düşüyor). Ayarın yerine o bakacak.
4. Boşta boşaltma: **EVET** — boşalan ~23.7 GB VRAM'i devredilen/parçalanan işlerin alt ajanları için kullan.

> Çelişki notu (REVİZE — Oturum 11 kapanışı): "auto-unload kapalı" iddiası Auto-Load/Unload karışıklığındandı. Asıl bulgu: 27B **manuel yüklenen → muaf (#2051)** → LM Studio ayarı onu boşaltmaz. Worker başlayınca VRAM 23→2–3 GB düşmesi → tetikleyici büyük olasılıkla **Bionic yaşam-döngüsü** → Aşama 1 testi attribüsyon + reload maliyeti ölçecek.

## Mimari: GPU Zaman Paylaşımı (ONAYLI — Oturum 11 kapanışı, c maddesi)
GPU 24 GB = ortak havuz. 27B aktifken yanına kimse sığmıyor (23.6/24 freeze kanıtı, Oturum 4). Ama 27B boşaltılırsa ~22 GB worker'lara açılır.
Döngü:
1. **İşleme fazı** — 27B aktif (delege eder, sonucu işler, seninle konuşur) → GPU'da ~23.7 GB.
2. **Boşalt + devir** — 27B VRAM'den iniyor (reload maliyeti ölçülecek); işler worker'lara.
3. **Paralel worker fazı** — worker'lar GPU'da (CPU'dan ~3–5x hızlı olmalı; ölçülecek). Kullanıcı bu fazda oyun/iş yapar.
4. **Uyanma** — işler bitince 27B yüklenir, işlenmiş veriyi tüm sistemle işler.

Paralel kapasite (24 GB, ~2 GB pay; tahmin — ölçülecek):
| Yapılandırma | VRAM | Durum |
|---|---|---|
| 27B + herhangi bir GPU worker | >24 GB | ❌ (freeze kanıtı) |
| 2× qwen3:8b Q4 (5.2×2 + ctx) | ~11–13 GB | ✅ sığar |
| 1× gemma4:26b (18.7) + 8b | >24 GB | ❌ |
| 1× gemma4:26b | ~19–20 GB | ✅ sığar |

→ Aynı anda **2 küçük veya 1 büyük** GPU worker'ı. GPU worker = Ollama `num_gpu > 0` varyantı veya LM Studio ikinci model — FAZ 2'de seçilecek.

**Kendini uyandırma** (FunkGoth isteği): gerçek zamanlı self-trigger'ın Bionic (harness) yetkisi bilinmiyor — kontrol edilecek. Ara çözüm: arka plan watcher'ı (worker bitince result dosyası + Windows toast) + tek kelimelik tetik. Harness yetkisi varsa tam otonomi.

## Kullanım Hafızası (FunkGoth kavramı → somut)
Yeni dosya: `E:\Bionic\agent\model-hafiza.md` (tohumlandı, bu oturum)
- `runs.csv` = ham veri; model-hafiza = **distille bilgi** (iş tipi → model → sonuç).
- Her worker run'ı + her yeni model buraya işlenir. Routing kararı bu dosyaya bakar.

## Benchmark Ön Bilgi (kütüphane büyüdükçe)
Kaynaklar (görev bazlı skor): Chatbot Arena (lmarena.ai), Artificial Analysis (artificialanalysis.ai), Vals AI (vals.ai), llm-benchmarks.com, OpenCompass.
Süreç: FunkGoth model indirir → model-hafiza'ya önce benchmark satırı (beklenti) → test işinde sonuç → beklenti vs gerçek karşılaştırması. İlk skor çekimi web ile (hız/VRAM/kalite).

## Aşama 1 Testi (FunkGoth gözlemleyecek)
1. **Boşta baz**: nvidia-smi → VRAM dolu (27B yüklü) + GPU kullanım düşük. (27B'nin manuel yüklenen/muaf olduğunu teyit et)
2. **Worker başlat**: bilinen iş (T7 tarzı özet, ~1–2 dk); FunkGoth Task Manager'da GPU BELLEK + KULLANIM'ı izler; ben zaman damgası + LM Studio `/v1/models` durumu kaydeder. → VRAM düşüşünün tetikleyicisi + anı.
3. **Uyanma maliyeti**: worker bitince hemen 27B'ye istek → ilk token'a kadar süre = reload maliyeti (boşta-boşaltma kararının bedeli).
Sonuç: attribüsyon kapanır (BIONIC mi LM STUDIO mu 27B'yi boşaltıyor?) + L1'in bedeli (reload) ölçülür.

## L1 Boşta Boşaltma (ONAYLI — uygulama)
- FunkGoth: EVET (4. cevap). Boşalan VRAM → worker'lara.
- ⚠️ **KAVRAM DÜZELTMESİ (Oturum 11 kapanışı)**: "Auto-Unload" derken karıştırdık. LM Studio'da **JIT loading = Auto-LOAD** (boşken istekle YÜKLEME; FunkGoth'ta **KAPALI**) — bu, boşaltma DEĞİL. **Asıl boşaltma = Idle TTL + Auto-Evict** (Developer→Server Settings içinde; Behavior panelinde DEĞİL; varsayılan TTL 60 dk). **CORS ilgisiz.**
- **KRİTİK (resmi doküman + bug-tracker #2051)**: JIT KAPALI → 27B "manuel yüklenen" → **manuel yüklenen modeller Auto-Evict/Idle TTL'den muaftır ("stay forever")** → **ayar açılsa bile 27B büyük olasılıkla boşalmaz**.
- **Asıl kaldıraç = Bionic'in model yaşam-döngüsü yönetimi** (kanıt: yeni sohbette modelin önce yüklenmesi + worker başlayınca VRAM 23→2-3 GB).
- Adımlar: (a) Aşama 1 testi → attribüsyon (Bionic mi LM Studio mu) + reload maliyeti; (b) FunkGoth auto-unload ayarını arıyor+soracak; (c) maliyet kabul edilebilirse PROTOCOL'e "boşta faz" kuralı + worker GPU opsiyonu.

## FAZ Planı (v3)
- **FAZ 1 (çerçeve)**: ✅ v3 — amaç onaylı; **mimari ONAYLI (Oturum 11 kapanışı)**; hafıza/test planı hazır.
- **FAZ 1.5 (bu hafta)**: (1) Aşama 1 testi (attribution + reload maliyeti); (2) auto-unload aç; (3) model-hafiza.md tohum (✅ bu oturum); (4) veri toplama haftası (→10-09) devam.
- **FAZ 2 (10-09 sonrası)**: veri raporu + iş tipi haritası + **paralel kapasite ölçümü (2×GPU worker denemesi)** + FAZ 2 raporu + benchmark ön bilgi derlemesi.
- **FAZ 3 (ileride)**: paralel ajan yönetimi mekanizması (self-wake, sonuç toplama, işlenmiş veri akışı) — kütüphane + offload oturduktan sonra.

## FAZ 2 Rapor İskeleti (v3)
1. Envanter — donanım, modeller, ölçülmüş ayak izler (baseline.md)
2. İş tipi haritası — iş → kaynak / süre / kalite (runs.csv + model-hafiza)
3. Routing önerisi — iş tipi bazında eşiği karşılayan en küçük/ucuz model
4. Paralel kapasite — 24 GB'da aynı anda kaç worker (2×8b GPU denemesi) + boşta-boşaltma döngüsünün gerçek zamanları
5. İş-başı öngörü — "bu iş ~X tüketir, ~Y süre; senin kalanın Z"
6. Bilinmeyenler — VRAM düşüşü attribüsyonu (Aşama 1 ile kapanacak), reload maliyeti, GPU worker hızı

## Karar Kriterleri (v3)
| Kriter | Öneri | Mevcut veri |
|---|---|---|
| Hız | iş tipine göre eval ≥ 4 tok/s + wall-time hedefi | worker 7–10.4 (CPU); GPU: ölçülecek |
| Kalite | FunkGoth onayı + benchmark ön bilgiyle beklenti | runs.csv accepted; 27B = "büyük tatminlik" |
| Kaynak | ölçülmüş ayak iz (VRAM delta, RAM, pagefile) | baseline.md |
| Ana model | **27B KALIYOR** (FunkGoth onayı); Ö3 bandı devam | ≈17 tok/s ilk örnek |
| Maliyet | wall-time × iş sıklığı + reload maliyeti | capture_overhead_s |
| Context | ana context'e ham değil İŞLENMİŞ veri döner | delegation brief/result protokolü |

## Durum
- FAZ 1: ✅ çerçeve v3 (amaç onaylı); mimari ONAYLI (Oturum 11)
- Aşama 1 + L1-B: ✅ BİTTİ — koexist kanıtlı; unload 23574→1500 MiB; 2×GPU 18.5/101.9 tok/s; JIT reload çalışıyor
- **Reload gerçek maliyeti: 17.44s (Oturum 16 KANIT)** — 317.7s = worker8b 6.3 GB VRAM'deyken çakışma artifact'i (disk elenmişti: 4.5s okuma). **Kural (ONAYLI): reload öncesi daima worker evict**
- **Mod B: ✅ KARAR VERİLDİ (Oturum 16, FunkGoth)** — **(b) unattended her zaman B, eşik yok** (break-even ≈200–250 output tok; 17.4s reload ile; eski ~4300 çürütüldü). **Metodun verimliliği hâlâ teste tabi (FunkGoth): veri haftası →10-09 + FAZ 2 raporuyla teyit**
- Veri toplama haftası: 🔄 → 10-09
- model-hafiza.md: ✅ tohumlandı (bu oturum)
<EOF>