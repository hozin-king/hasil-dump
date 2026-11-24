# Candy Crush Saga 1.341.2.1 — Dump Full + REA (statis)

- **Package:** `com.king.candycrushsaga`
- **Versi:** 1.341.2.1 (versionCode 13412010), minSdk 24 / targetSdk 37
- **Sumber:** APKMirror, diunggah 17 Nov 2026 — bundle `.apkm` (bukan APK tunggal):
  `base.apk` (93.578.884 B) + `split_config.arm64_v8a.apk` (86.397.543 B) +
  split `armeabi-v7a` + split DPI/bahasa (tidak dianalisis; hanya arm64-v8a)
- **SHA-256 sumber (.apkm):** `7886948de978b25dde0763d0dc14834b12f5c590c19a4d952cf4aa7ab5c8b94a`
- **Tanggal dump:** 24 Nov 2026 (WIB)
- **Metode:** analisis statis SAJA — APK tidak pernah di-install/dijalankan.
  Tanpa Ghidra/IDA/Hopper di VM ini: tidak ada dekompilasi native penuh,
  tidak ada runtime/traffic. Semua kesimpulan di bawah ditandai
  TERBUKTI (dari artefak) atau INFERENSI (butuh bukti lanjutan).

## Isi folder

`dump/` berisi produk analisis (total ~2,9 MB, 18 file):

| File | Isi |
|---|---|
| `FINDINGS-dex.md` | Temuan DEX + manifest + aset (detail, TERBUKTI vs INFERENSI) |
| `FINDINGS-native.md` | Temuan native `.so` (detail, TERBUKTI vs INFERENSI) |
| `zip-inventory.txt` | Inventaris 10.091 entri base.apk + 8 entri split arm64 |
| `hashes.txt` | SHA-256 .apkm, base.apk, split, 6 DEX, 3 `.so` |
| `manifest-badging.txt` / `manifest-xmltree.txt` | Manifest (aapt2 badging + xmltree ter-parse) |
| `signer.txt` | Sertifikat penandatangan + skema signing |
| `classes.txt` | Hitungan DEX + histogram package + 1.170 class `com.king.*` |
| `dex-strings-interesting.txt` | 107 string DEX kurasi (gateway, integrity, billing, iklan, JNI) |
| `assets-inventory.txt` | Inventaris aset + level DB + format config |
| `native-inventory.txt` | ELF header/section/dynamic/symbol ketiga `.so` |
| `libcandycrushsaga-exports.txt` | `nm -D` lengkap main lib (11.592 baris; 182 `Java_*` di atas) |
| `libcandycrushsaga-strings-interesting.txt` | 593 string main lib kurasi, 14 seksi |
| `libcandycrushsaga-strings.txt.gz` | 249.527 string ASCII mentah main lib (gzip) |
| `libapplovin-native-crash-reporter-exports.txt` | Ekspor crash reporter AppLovin |
| `libapplovin-strings-interesting.txt` | 129 string crash reporter |
| `libdatastore_shared_counter-exports.txt` | Ekspor helper DataStore (19 baris) |
| `libdatastore-strings-interesting.txt` | 62 string helper DataStore (semua 50 string) |

## Temuan terpenting

### 1. Game hampir 100% native, engine custom King (TERBUKTI)
Java/Kotlin hanya bridge tipis (AGDK `GameActivity` →
`com.king.core.NativeApplication` → `CandyCrushSagaActivity`). Seluruh
logika game tinggal di `lib/arm64-v8a/libcandycrushsaga.so` (85.487.344 B,
hanya ada di split arm64; base.apk berisi NOL `.so`). Total DEX:
47.126 class, 303.401 method — mayoritas SDK pihak ketiga.
Engine BUKAN Unity/Cocos/Unreal: nol `libunity`/`il2cpp`/`cocos`;
build path Jenkins `tibranch-pipeline_release_0.45.2` + modul `usdk/*` +
`candycrushsaga/packages/ccsm_plugins/` bocor di strings ("Unity" yang
muncul hanya Unity Ads). Bundle di dalam main lib: FreeType, SQLite,
Duktape JS, Spine, Vorbis/Ogg, zlib, WebP parsial, Lua (`OnFireLua`).

### 2. Anti-cheat nyata di native (TERBUKTI ada; efektivitas TIDAK terbukti)
`usdk::AntiCheat` — `MemoryTamperingDetector` (+ `setEnabled`),
`ICheatDetector`, `CheatDetectorAccessPoint`, `anticheat_config.dat`,
string `-- Anti-cheats active --`, anti-cheat per-fitur (CandyRoyale
quit-during-level, SuperCharger, MarathonLeagues `CCheatController`,
`EpisodeRace::CServerCheatApiV2` dibungkus `CGuardedFunction` ×837),
anti time-cheat (`AntiCheatTimeProvider`), detektor debugger via
`TracerPid:` + `/proc/self/status` (`debugger_detector_enabled`).
Nol `ptrace` (string maupun import).

### 3. Negatif penting — yang TIDAK ada (TERBUKTI dari statis)
- **Tidak ada deteksi root** di native (nol `rooted`/`magisk`/`supersu`/
  path `su`; hit `root` semuanya scene-graph) maupun di DEX (tidak ada
  RootBeer/Magisk/Xposed/SafetyNet; `DeviceRootedStatus` dan `FRIDA`
  adalah literal yang mudah disalahbaca — kemungkinan enum device-info
  SDK iklan / nama jaringan iklan, bukan bukti pemeriksaan).
- **Tidak ada deteksi emulator**; **tidak ada SafetyNet/Play Integrity
  native**; **tidak ada cek signature APK di native**.
- **Play Integrity API adalah satu-satunya device-trust yang terbukti**
  (di DEX, `classes3.dex`) + Amazon PrivacyPass attestation.

### 4. 24.005 level lengkap terbaca statis (TERBUKTI)
`levels_batched.db` (SQLite, 44,7 MB): tiap level sebagai JSON
(`protocolVersion 0.3`: `tileMap`, `scoreTargets`, `moveLimit`,
`gameModeName`, `levelDefinitionId_meta`). Indeks `levels.xml` sampai
episode 1601. Paket OTA (`ota-dynamic_difficulty_*`,
`ota-first_attempt_challenge-default`) + `FeatureFlags` gateway —
tuning difficulty dikendalikan server (INFERENSI: perubahan server bisa
membuat dump ini basi).

### 5. IAP = Google Play Billing 8.3.0, katalog server-driven (TERBUKTI)
`BillingManager` + dua glue billing (`com.king.google.billing` +
`com.king.storemodule.google`); 3.271 hit `purchase` di native,
`AppPurchaseApi.verifyPurchase`, `ItemDeliverySystem`/`ProductDelivery`.
**Nol SKU/product-id literal** di DEX maupun (yang terkurasi) di native.
Jalur Amazon IAP ada tapi dormant di build Play ini.

### 6. Iklan = mediasi King sendiri "ABM" (TERBUKTI)
`com.king.abm.*` (~490 class) di atas 7 jaringan: AppLovin MAX,
ironSource/LevelPlay, Unity Ads, Vungle, Moloco, AdMob, Meta Audience
Network; header bidding via gateway protobuf King (`gatewayprotocol.v1`,
704 class, transport Ktor/OkHttp). `libapplovin-native-crash-reporter.so`
hanya crash reporter (signal handler + alt stack), bukan anti-cheat.
`libdatastore_shared_counter.so` (6.856 B) hanya helper AndroidX
DataStore (mmap counter).

### 7. Jaringan + enkripsi (TERBUKTI sebagian)
OpenSSL ter-link statis + `usdk::FileSystem::FileEncryptorOpenSsl`
(encrypt/decrypt/generateDataKey — enkripsi file lokal); HTTP client
buatan sendiri `usdk::Http` (tanpa libcurl/okhttp/Cronet di native).
Domain terlihat: `ccs.play.king.com`, `*.midasplayer.com`,
`graph.facebook.com/v2.12`. **Tidak ada endpoint server King dalam
bentuk literal di DEX** — endpoint hampir pasti di native atau diterima
lewat gateway protobuf (INFERENSI). 0 string "ssl pinning" di native —
pinning bisa hidup di sisi Java (TIDAK terbukti).

### 8. Manifest ketat, signer lama (TERBUKTI)
21 permission, tanpa yang berbahaya-klasik (tanpa lokasi/kamera/mikrofon/
storage). `allowBackup=false`, `debuggable=false`, analytics
consent-gated (Firebase + Facebook auto-log mati). 2 receiver King
exported tanpa `permission` (`AnalyticsReceiver`,
`NativeSharingReceiver` — dampaknya tergantung native, TIDAK bisa
dinilai dari DEX). Signer: `CN=Cristian Bidea, O=king.com` (RSA 2048,
SHA-256 cert `ac7f3b35…`, berlaku 2012–2039, `sha1WithRSAEncryption`);
base.apk hanya v2+v3 (tanpa v1); SourceStamp Google hadir.

### 9. Kebocoran artefak build (TERBUKTI)
Metadata Kotlin Multiplatform (`.knm`) + file proguard ikut terkirim —
berguna untuk pemulihan simbol pada REA lanjutan. Main lib stripped
(tanpa `.symtab`) TAPI kaya: 5.685 simbol dinamis (5.226 defined,
1.677 nama C++ mangled, 182 `Java_*`), `.text` 51,5 MB, RTTI di
`.rodata` membocorkan nama class internal.

## Batasan (apa yang TIDAK bisa diverifikasi dari dump ini)

1. Efektivitas/perilaku runtime anti-cheat & debugger detector (kapan
   memicu, konsekuensinya); kunci/algoritma pasti enkripsi file; detail
   TLS/pinning; alur server-side IAP; validasi skor/progress server-side.
2. Tanpa Ghidra/IDA: tidak ada dekompilasi/pseudocode fungsi native;
   tanpa runtime: tidak ada traffic gateway, token, atau Integrity
   verdict yang diamati.
3. Tidak ada dexdump/jadx/baksmali di VM: hitungan DEX + string
   dikerjakan parser DEX Python tulisan sendiri (bukan dekompilasi;
   tidak ada isi method/control-flow, atribusi string→class tidak
   dimungkinkan).
4. Target `dlopen` dinamis lain selain `libaaudio.so` tidak terlihat
   statis (nama bisa dibentuk runtime via `%s.so`).
5. Hanya arm64-v8a yang dianalisis; split armeabi-v7a tidak termasuk.
6. Aset proprietary (`.ffm/.ffa/.ffsb/.ng/.prefab`, BIN1 `levels.xml`)
   hanya diidentifikasi dari nama/ukuran — isinya tidak di-parse
   kecuali `levels_batched.db` (skema + 2 baris sampel).

## Sumber

- `.apkm` APKMirror 17 Nov 2026 (SHA-256 di atas; APK sumber dihapus
  setelah push hasil ini terverifikasi, sesuai aturan REA 22 Nov 2026).
- Detail lengkap: `dump/FINDINGS-dex.md` dan `dump/FINDINGS-native.md`.
