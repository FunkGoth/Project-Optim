# Project Optim — Optimizasyon Projesi

Kuruluş: 2026-10-03 (Oturum 23) · Sahip: FunkGoth · Yöneten: ana agent (Qwen3.8-27B)
Durum: iskelet + taşımalar + kayıtlar **TAMAM** · açık: FunkGoth onayları (isim, canon, 3 kaldıraç — aşağıda).

## Bu proje ne?
Self-optimizasyon, multi-model (delegation) ve context verimliliği işlerinin **tek çatıda** toplu yönetildiği proje:
kuralların SPEK'i, işlenen veriler, veri işleme politikaları, arşiv — hepsi burada, tek sorumluluk altında.
**Rol paylaşımı (FunkGoth yetkisi):** agent = "araştır → test et → uygula" + toplu yönetim · FunkGoth = onay + yön.

## Yapı
| Yol | İçerik |
|---|---|
| `Docs\PROTOCOL-optim.md` | K1–K9 SPEK'i (gerekçe + kanıt) + delegation/routing SPEK'i + proje çalışma kuralları |
| `Docs\DATA-POLICY.md` | CSV şemaları, append kuralları, light/full eşikleri, retention, canon, sessiz-stop tespiti |
| `Docs\ARSIV\` | 5 çalışma klasörü: nihai-karar-oturumu · context-devami · agentic-arastirma · ue-oturum · kaynak-bagimsizligi-cercevesi |
| `data\metrics\` | Veri havuzu: runs.csv · context-snapshots.csv · context-ledger.csv · baseline.md · context-benchmark.md · eval-2026-10-02.md · capture.ps1 · top_proc.ps1 · README.md |
| `data\delegation\` | Worker brief/result (t7) + worker Modelfile'ları (3) |
| `data\model-hafiza.md` | İş → model distille bilgisi |
| `.agents\skills\optim\SKILL.md` | Proje skill'i (bu projede açılan sohbetlerde otomatik aktif) |

## Bölüşüm (O19 dersi — boot çökmesin)
- K1–K9'ın **operatif metni `E:\Bionic\agent\PROTOCOL.md`'de KALIYOR** (boot zinciri: README → PROTOCOL → STATE → TASKS).
- Bu proje = **SPEK + gerekçe + kanıt** (Docs\) + **veri** (data\) + **politika** (Docs\DATA-POLICY.md) + **arşiv** (Docs\ARSIV\).
- Kural değişirse: SPEK güncellenir → operatif metin PROTOCOL'e (FunkGoth onayıyla) → karar DECISIONS + LOG'a.

## Sabit Kurallar (kök README'den miras)
1. Yalnızca `E:\Bionic\` içinde yaz/sil.
2. Kullanıcı onayı olmadan silme / geri alınamaz işlem yok.
3. Bu projenin git yedeği güncel tutulur (her önemli adımda commit).
4. `Docs\` dosyaları kullanıcı malıdır; onaysız "canon" ilan edilemez.

## Onay Bekleyenler (O23)
1. **Proje adı**: "Project Optim" (alternatif: SelfTune) — öneri, FunkGoth onayı bekler.
2. **Canon**: Docs/ dosyaları onaya dek **TASLAK** (Sabit Kural 4).
3. **Kaldıraç sırası** (O22 araştırması — `Docs\ARSIV\2026-10-03-agentic-arastirma\arastirma.md`):
   (1) reasoning seviyesi: rutin iş=low / kritik karar=high · (2) Bionic MTP desteği kontrolü · (3) pencere 64k→128k KV ölçümü.
