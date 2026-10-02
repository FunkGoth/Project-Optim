# Delegation — worker brief & sonuçları

- `brief-<konu>.md` — görev brief'i: amaç, kapsam, gerekli dosya parçaları, çıktı formatı + kelime limiti.
- `result-<konu>.md` — worker'ın KOMPAKT çıktısı (≤200 kelime veya sabit format).
- VRAM kuralı: aynı anda TEK worker (24 GB tavan; 2026-10-01 donması: 2×64K slot sığmıyor).
- Runtime'lar: A = localhost:1234 (aynı model, sınırda) · **B = KURULU (2026-10-01): `worker8b` (qwen3:8b) — Ollama port 11434, CPU-only, ctx 8192, temp 0.3** · C = yeni Bionic sohbet (tam agent; FunkGoth açar, brief'i ana agent yazar).
- Worker B çağrısı: `POST http://localhost:11434/api/chat` — `model: worker8b`, `stream: false`, `think: false` (varsayılan — ölçüm: aynı iş 41s→3.7s, kalite korundu; derin çıkarım gereken işte `think: true`), gerekli dosya parçaları prompt'a gömülür (worker'ın aracı yok).
- Ana agentın context'i yalnız brief+result kadar büyür; hacimli okuma worker'ın atılabilir havuzunda kalır.
