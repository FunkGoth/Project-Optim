# BRIEF — t7-rapor-inceleme (ilk worker denemesi)
Tarih: 2026-10-01 · Runtime: B (`worker8b`, CPU, port 11434) · Ana agent: yönetici

## Amaç
T7 raporu (`work/2026-10-01-agent-iyilestirme-analizi/rapor.md`) üzerine **taze göz** incelemesi:
rapor içindeki iç çelişkileri, eksik bırakılan kontrolleri (gap) ve FunkGoth'un karar verirken
dikkat etmesi gereken riskleri bul. Rapor metni worker'a prompt olarak gömülür (worker'ın aracı yok).

## Kapsam
- Yalnız rapor metni değerlendirilecek; rapor dışı bilgi EKLENMEZ.
- VRAM bütçe tablosu (§4.1) sayısal tutarlılığı ayrıca kontrol edilecek: satır toplamları,
  "sığıyor/sığmıyor" işaretleri, senaryo C ile §4.3 önerisi 3 arasındaki ilişki.
- B2 (128K) zaten REDDEDİLDİ, B3 (Q5_K_M) GERİ ÇEKİLDİ, B5 (16384) GERİ ALINDI →
  bunların rapor içindeki hâlleri "çözülmüş" kabul edilir; yeniden önermek GEREKSE gerekçesiyle.

## Çıktı formatı (≤200 kelime, Türkçe, doğrudan yanıt)
1. **İÇ TUTARLILIK:** çelişen sayı/iddia varsa bölüm referansıyla.
2. **GAP:** raporda eksik bırakılan kontrol/doğrulama.
3. **RİSK:** FunkGoth kararlarında dikkat edilmesi gerekenler.
4. **SORU:** FunkGoth'a 1–2 soru.
5. **EN ÖNEMLİ 3 MADDE** (her biri tek cümle).
