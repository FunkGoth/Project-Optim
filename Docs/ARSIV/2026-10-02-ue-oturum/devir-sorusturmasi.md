# O22 Devir Soruşturması (2026-10-02)

**Soru (FunkGoth):** "İşlem sırasında context dolması yüzünden durmam sebebiyle kaç defa kullanıcı benden yeni prompt ile kaldığım işe devam etmemi istedi?"

## Kaynaklar
- LOG.md (compaction/devir satırları — regex taraması yapıldı)
- metrics/context-snapshots.csv (10 satır, delta<0 vakaları)
- TASKS/STATE geçmişi

## Bulgular

### A) Açıkça "context doluluğu" sebebiyle kapanıp yeni prompt ile devam (KESİN KAYITLI)
| # | Vaka | Kanıt |
|---|---|---|
| 1 | O6 → O7 | LOG s.50: "OTURUM KAPANDI (context doluluğu, FunkGoth)" → O7 başlığı "devam — devir sonrası". |
| 2 | O20 (nihai karar turu) | **FunkGoth ekran görüntüsü (10-03, soruşturmaya kanıt olarak sunuldu)**: 62k context'te çalışma durmuş, FunkGoth "62k context sebebiyle durdun, çalışmaya devam et" promptu vermiş. LOG/CSV'de KAYIT YOK — snapshot'lar 42k'ta kesiliyor (42k→62k aralığı ölçülmemiş). Kaynağ: kullanıcı kanıtı. |

### B) FunkGoth'un "devir yapalım / devam" diye yeni oturum açtığı vakalar (sebep KAYITLI DEĞİL)
| # | Vaka | Not |
|---|---|---|
| 2 | O13 → O14 | LOG s.161: "DEVİR (FunkGoth: 'devir yapalım')" — context doluluğu kaydı yok; muhtemel proaktif devir (limit yakınında) ama KAYITTA SEBEP YOK |
| 3 | O15 → O16 | LOG s.168: "DEVİR (FunkGoth: 'oturum devir yapıyoruz')" — sebep kayıtsız |
| 4 | O16 → O17/O18 zinciri | LOG s.200: "DEVİR (FunkGoth: 'devir yapalım')" — sebep kayıtsız |
| 5 | O21 → O22 (bu oturum) | O21 son snapshot 56.5k (compaction tepe 59k'a yakın — "bu oturum burada kapanmalı" notu) → limit yakınında planlı devir; FunkGoth "Devam edelim" promptu |

### C) Otomatik compaction (agent'ın durduğu anlar — kullanıcı promptu DEĞİL)
- O18 (768b9104): **2 compaction** (FunkGoth sayımı); 1'i görev ortasındaydı (devir belgesi sayesinde kayıp yok), 59k→14.6k (−44.4k).
- Bu vakalarda oturum DEVAM ETTİ; yeni prompt gerekmedi.

### D) Özel vaka: O19 boot hatası
- Yeni oturum açıldı ama sebep context doluluğu DEĞİLDİ: agent E:\ kökünü bulamadı, FunkGoth yönlendirmek zorunda kaldı (K1 kullanıcı-düzeltme sinyali, deg=1). Devam-promptu sayılır ama kök nedeni farklı.

## Net Sayım
- **"Context doldu → kullanıcı yeni prompt ile devam istedi" KESİN: 2 vaka** — O6→O7 (LOG kayıtlı) + O20 (kullanıcı ekran görüntüsü; kayıtlarda yoktu, 10-03'te soruşturma sırasında ortaya çıktı). Diğer benzer vakalar kayıtlarda yoksa bilinmiyor — sayı alt sınırdır.
- FunkGoth'un başlattığı toplam yeni-oturum/devir zinciri: **~6** (O7, O14, O16, O18-zinciri, O20, O22) — bunların hangisinin sebebinin context doluluğu olduğu **kayıtlarda açıkça belirtilmemiş**.
- Otomatik compaction: **2** (O18) — ikisi de oturumu durdurmadı.

## Sınırlılık (dürüst beyan)
1. Devir kayıtları "neden devir?" alanı tutmuyordu — yukarıdaki B listesindeki sebepler **varsayım değil, kayıtsızlık** olarak raporlanıyor.
2. Compaction sayısını agent sayamaz (K6 sınırlılığı); O18 sayısı FunkGoth kaydı.
3. O20 vakası (62k durması) metriklerde KAYIT DIŞI — K6 snapshot'u durma anını yakalayamamış (42k→62k arası kör nokta).
4. Öneri: LOG şablonuna "devir sebebi" alanı + durma/dolma olayları ledger'a shell-append (PROTOCOL değişikliği → gerekçe + onay gerekir; şimdi uygulanmadı).
