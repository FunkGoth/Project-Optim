---
name: optim
display-name: Project Optim Proje Bağlamı
description: Project Optim: K1–K9 SPEK'i, delegation/routing, veri politikası (CSV şemaları, light/full eşikleri), arşiv haritası. Bu projede işe başlamadan önce oku.
---

# Project Optim — Proje Bağlamı ve Anlaşmalar

Optimizasyon projesinde (self-optimizasyon + multi-model + context verimliliği) referans: nerede ne var, nasıl çalışırız.
Agent'ın kendi çalışma sistemi `E:\Bionic\agent\` hafızasında (PROTOCOL/STATE/TASKS) — bu dosyada kodlanmaz.

## 1. Yapı ve Yol Haritası

| Ne | Nerede | Kim yönetir |
|---|---|---|
| Proje README (durum, onay listesi) | `E:\Bionic\Project Optim\README.md` | Birlikte |
| SPEK (K1–K9 + delegation + routing) | `Docs\PROTOCOL-optim.md` | Agent önerir, FunkGoth onaylar (canon) |
| Veri politikası (şema, append, eşik, retention, canon, sessiz-stop) | `Docs\DATA-POLICY.md` | Agent önerir, FunkGoth onaylar (canon) |
| Arşiv (bitmiş iş klasörleri) | `Docs\ARSIV\` | Agent (silme/onay: FunkGoth) |
| Veri havuzu (runs, snapshots, ledger, baseline, benchmark, eval, ölçüm scriptleri) | `data\metrics\` | Agent (append-only; K2c: shell `>>`) |
| Delegation (brief/result, Modelfile'lar) | `data\delegation\` | Agent |
| İş → model bilgisi | `data\model-hafiza.md` | Agent |
| Operatif K1–K9 metni (boot zinciri) | `E:\Bionic\agent\PROTOCOL.md` | Agent (değişiklik: FunkGoth onayı + LOG) |

## 2. Çalışma Anlaşmaları

1. **Rol**: agent = "araştır → test et → uygula" + toplu yönetim · FunkGoth = onay + yön.
2. **Önce dosya, sonra context**: 50+ satırlık çıktı dosyaya (K4); 100+ satır okuma/özet worker'a (K7).
3. **CSV append = shell `>>`** (K2c); tam dosya okuma istisna + gerekçeli (K2).
4. **Turn sonu kayıtlar**: K6 snapshot (araç kullanan prompt) + K9 defter (kapsam varsa) + STATE/TASKS + git commit.
5. **Canon kuralı**: Docs/ = kullanıcı onayına dek TASLAK; onaysız canon yok.
6. **Dürüstlük**: kayıt boşluğu / ölçülemeyen değer = açıkça bildirilir (alt sınır + sınırlılık notu); uydurma yok.

## 3. Sabit Kurallar (kök README'den miras)
1. Yalnızca `E:\Bionic\` içinde yaz/sil.
2. Kullanıcı onayı olmadan silme / geri alınamaz işlem yok.
3. Proje git yedeği güncel tutulur (her önemli adımda commit).
4. Docs/ içerikleri kullanıcı onayıyla değişir; agent tek taraflı "canon" ilan edemez.
