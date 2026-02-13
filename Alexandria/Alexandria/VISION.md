# Alexandria – Vizija platforme

> Swift kao temeljni jezik/runtime • "App browser" umjesto klasičnog web browsera • Aplikacije kao single-bundle (.swa) • Online + offline rad • Fokus na sigurnost, performanse i AI • Enterprise-first, pa širenje

---

## 🚀 Ključne značajke platforme

### Runtime
- Swift runtime (AOT/WASM)
- Multithreading
- GPU/ML pristup
- Sandbox po aplikaciji

### App model
- Jedna datoteka (UI + logika + asseti)
- Potpisane aplikacije
- Delta update
- Instant launch

### Networking
- Osim CRUD: **STREAM**, **SUBSCRIBE**, **EVENTS**
- Offline queue + sync
- P2P opcije

### Sigurnost
- Capability-based permissions
- App signing
- Izolacija storagea
- Zero-trust pristup
- Security agent (monitoring)

### Dev mode
- Inspector (UI tree, state)
- Layout debug gridovi
- Network panel
- Profiler (CPU/GPU/memory)
- Hot reload

### Enterprise model
- Interni app ekosustav
- SSO login
- Policy server
- Wipe-on-logout
- Audit log
- Per-app VPN/P2P

---

## 🔥 Arhitektura – 9 principa

| # | Problem | Rješenje |
|---|---------|----------|
| 1 | Loše korištenje CPU-a | Swift concurrency (async/await, Task), AOT, pravi multithreading |
| 2 | GPU djelomično | GPU-first renderer, Metal pipeline |
| 3 | Neural Engine neiskorišten | CoreML, NE kao capability |
| 4 | Previše memorije | Jedan runtime, strogi memory limits, deterministic lifecycle |
| 5 | Preveliki bundleovi | Prekompajlirani bytecode, tree-shaking, streaming load |
| 6 | Loš offline | Offline-first, lokalna baza + sync, CRDT |
| 7 | Sigurnost naknadno | Potpisane appove, nema eval, capability permissions |
| 8 | CRUD-only mreža | STREAM / SUBSCRIBE / EVENTS, QUIC, P2P |
| 9 | Nema resource nadzora | Per-app dashboard, admin policy, throttling |

---

## 🔥 Killer featurei

- **AI-native** (lokalni modeli)
- **Native-level performanse**
- **Offline-first**
- **Instant app korištenje**
- **Sigurnost by default**
