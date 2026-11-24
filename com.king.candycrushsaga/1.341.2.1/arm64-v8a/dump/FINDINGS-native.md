# FINDINGS — Native (.so) dump: Candy Crush Saga 1.341.2.1 (arm64-v8a)

- **Package:** `com.king.candycrushsaga` — version **1.341.2.1**, versionCode **13412010**, min API 24
- **Source APK:** `split_config.arm64_v8a.apk` (86.397.543 byte; berisi persis 3 `.so`)
- **ABI scope:** arm64-v8a only. (info.json menyebut varian juga memuat armeabi-v7a, tetapi split APK yang diberikan hanya arm64-v8a — v7a TIDAK dianalisis.)
- **Metode:** statis saja — `readelf`, `nm`, `objdump`, `strings`, `sha256sum`, `file`, `unzip`. **Tidak ada Ghidra/IDA/Hopper di VM ini; tidak ada dekompilasi; tidak ada eksekusi APK/game.**
- **Tanggal dump (UTC):** 2026-11-24
- **File hasil (di folder `dump/` ini):** `native-inventory.txt`, `libcandycrushsaga-exports.txt`, `libcandycrushsaga-strings-interesting.txt`, `libcandycrushsaga-strings.txt.gz`, `libapplovin-strings-interesting.txt`, `libdatastore-strings-interesting.txt`, plus `libapplovin-native-crash-reporter-exports.txt` dan `libdatastore_shared_counter-exports.txt` (bonus, singkat).

---

## 1. Inventaris — 3 library native

| Library | Ukuran | SHA-256 | ELF | Stripped? | dynsym |
|---|---|---|---|---|---|
| `libcandycrushsaga.so` (utama) | 85.487.344 B (~81,5 MB) | `2363a46a82e7dddf7360f76d625b0b54b7453d4a7cbf68ae08a699e444438548` | ELF64, AArch64, DYN, entry `0x0` | **Ya** (tanpa `.symtab`) | 5.685 (5.226 defined, 458 undefined) |
| `libapplovin-native-crash-reporter.so` | 859.832 B | `e25727f6a898b701d21cc1f403d3db66e445ef9c7be6eca4b5b6cbd27c1e4147` | ELF64, AArch64, DYN, entry `0x60694` | **Ya** | 2.138 (1.994 defined, 143 undefined) |
| `libdatastore_shared_counter.so` | 6.856 B | `1ae17d91da9324da6f0cf4e60e543b7d79d938ca4d300985969acb632cc9ed1c` | ELF64, AArch64, DYN, entry `0x0` | **Ya** | 20 (readelf, termasuk null entry; `nm -D`: 19 baris — 9 defined, 10 undefined) |

- `base.apk` (93.578.884 byte) **tidak mengandung `.so` sama sekali** — terverifikasi via `unzip -l` (nol hasil untuk `*.so`).
- **LOAD segmen `libcandycrushsaga.so`:** `R E` 0x4dd9860 byte (~81,7 MB, kode+rodata), lalu `RW` 0x39f7c8 dan `RW` 0xaef8 (BSS s.d. 0x1b1a28). `.text` sendiri 51.500.740 byte, `.rodata` 10.516.295 byte, `.eh_frame` 7.829.752 byte, `.rela.dyn` 9.588.048 byte, `.data.rel.ro` 3.748.464 byte.
- **NEEDED `libcandycrushsaga.so`:** `libGLESv3.so`, `libEGL.so`, `liblog.so`, `libGLESv2.so`, `libandroid.so`, `libm.so`, `libOpenSLES.so`, `libc.so`, `libdl.so`. SONAME: `libcandycrushsaga` (tanpa `.so`). Tanpa RPATH/RUNPATH.
- **NEEDED AppLovin:** `libandroid.so`, `liblog.so`, `libm.so`, `libdl.so`, `libc.so`. **NEEDED DataStore:** `libm.so`, `libdl.so`, `libc.so`.
- Detail lengkap (ELF header, program/section header, dynamic section) ada di `native-inventory.txt`.

### Seberapa stripped?

**TERBUKTI:** ketiga `.so` **stripped** — tidak ada section `.symtab` / `.debug_*`; `nm` (tanpa `-D`) mencetak `no symbols` pada ketiganya. Namun ini **bukan** stripped total:

- **`.dynsym` tetap kaya:** `libcandycrushsaga.so` mengekspor 5.226 simbol terdefinisi, termasuk **1.677 nama C++ mangled** (`_ZN...`) dan **182 simbol `Java_*`**. Ini karena simbol dinamis wajib ada untuk dynamic linking/JNI — bukan kebocoran debug info.
- **RTTI/typeinfo bocor lewat strings:** `strings -a` menemukan ribuan nama class internal dalam bentuk mangled (mis. `N4usdk9AntiCheat23MemoryTamperingDetectorE`, `N11CandyRoyale19CAntiCheatValidatorE`). Nama-nama ini tersimpan di `.rodata` (typeinfo), bukan di tabel simbol — tapi tetap terbaca statis.
- **`.eh_frame` 7,8 MB** masih ada (unwind info, wajar untuk C++ exceptions) dan **`.rodata` 10,5 MB** berisi 249.527 string ASCII — sumber utama temuan di bawah.
- Catatan koreksi: `nm` mengembalikan exit code 0 walau mencetak `no symbols`, jadi exit code BUKAN indikator stripped; yang menentukan adalah tidak adanya `.symtab` (sudah dikoreksi di `native-inventory.txt`).

---

## 2. Engine — TERBUKTI: custom King engine (CCSM + usdk), BUKAN Unity/Cocos/Unreal

**Kesimpulan: game ini memakai engine native buatan King sendiri.**

Bukti (semua dari strings/exports statis):

- **Tidak ada jejak Unity / Cocos2d / Unreal:** nol string `libunity.so`, `il2cpp`, `libil2cpp.so`, `libcocos2dcpp.so`; nol simbol `Unity*`/`il2cpp`/`cocos2d` di dynsym; NEEDED tidak memuat library engine pihak ketiga. Hit `Unity` di strings (29) semuanya adalah **Unity Ads** (mediation iklan, lihat §7), dan hit `cocos` (11) semuanya substring kata lain — 0 hasil dengan word-boundary.
- **Namespace game sendiri:** `CcsmGui` (CCSM = Candy Crush Saga Mobile), `CandyRoyale`, `EpisodeRace`, `MarathonLeagues`, `SuperCharger`, `OnFire` / `OnFireLua` (framework scene/scripting internal), `Plataforma::KINGAPP_CANDYCRUSH`, `Services::*`.
- **King `usdk` (Universal SDK):** puluhan modul C++ internal — `usdk::AntiCheat`, `usdk::Http`, `usdk::Catalog`, `usdk::OtaStorage`, `usdk::FileSystem`, `usdk::Downloader`, `usdk::HealthMonitor`, `usdk::Livetask`, `usdk::EventScripting` — plus `king::` dan `kstl` (`/thirdparty/kstl/...`).
- **Build path bocor di strings:** `/home/jenkins/agent/workspace/tibranch-pipeline_release_0.45.2/ads-core/packages/amp/...`, `/usdk/modules/...`, `candycrushsaga/packages/ccsm_plugins/...` (mis. `.../super_charger/source/common/SuperChargerPlugin.cpp`). Ini layout monorepo King, bukan proyek Unity/Cocos.
- **Rendering/audio native langsung:** `libGLESv3`/`libEGL` + `libOpenSLES` di NEEDED; `AAudioLoader` me-`dlopen` `libaaudio.so`; Google **AGDK GameActivity + Swappy** ter-link statis (simbol `Java_com_google_androidgamesdk_*`, `SwappyDisplayManager`, `GameActivity`, `ChoreographerCallback`).
- **Scripting ganda:** **Lua** (string `OnFireLua`, file `.lua`, pesan error Lua) dan **Duktape JS** (278 simbol `duk_*`, `usdk::EventScripting::DukTapeScriptManager`, `ads-core/.../clientsidescripting/duktape/...`). Duktape terbukti dipakai untuk client-side scripting iklan (AMP); peran Lua di gameplay hanya INFERENSI (lihat §10).

---

## 3. JNI surface — 182 simbol `Java_*` + `JNI_OnLoad`

- `JNI_OnLoad` **ada**, diekspor di `0x4ca1e00` (`T JNI_OnLoad`).
- **182 simbol `Java_*`** di `libcandycrushsaga-exports.txt` (bagian atas file sudah dipisahkan: `JNI_OnLoad`, semua `Java_*`, lalu daftar lengkap `nm -D`).
- Kelompok terbesar per paket Java (hitung dari `nm -D`):
  - `com.king.core.NativeApplication` — 25 (entry/activity game)
  - `com.king.usdk.lifecycle.UsdkLifecycle` — 10
  - `com.king.abm.adprovider.*` — 9+ (iklan, lihat §7)
  - `com.king.google.billing.GoogleBillingLibGlue` — 8 dan `com.king.storemodule.google.GoogleBillingLibGlue` — 6 (**dua** implementasi billing glue, lihat §6)
  - `com.king.usdk.otconsent.OneTrustHelper` — 7 (consent/privasi), `com.king.usdk.facebook.sdk.FacebookSdkWrapper` — 7, `com.king.usdk.braze.*` — 7+4 (Braze push/notifikasi), `com.king.abm.internal.debugviewer.DebugViewerApi` — 7
  - `com.king.abm.internal.Http` — 6, `com.king.device.DeviceImpl` — 5, `com.king.http.HttpManager` — 2, `com.king.usdk.appsflyer.AppsFlyerModule` — 2, `com.king.usdk.identitygpgs.GooglePlayServices` — 2
  - `com.google.androidgamesdk.*` — GameActivity + Swappy + Choreographer (AGDK)
- Import libc yang relevan: `dlopen`, `dlsym`, `socket`, `connect`, `prctl`, `__system_property_get`, `getenv`, `mmap`, `open`/`opendir`, `AAssetManager_open`. **Tidak ada import `ptrace`.**

---

## 4. Anti-cheat / anti-tamper — TERBUKTI ada, tapi BUKAN root/emulator detect

### Yang TERBUKTI dari strings (+ nama class mangled)

1. **`usdk::AntiCheat` — framework anti-cheat King** (nama class terbaca di `.rodata`, BUKAN di dynsym — 0 hit `anticheat` di exports):
   - `usdk::AntiCheat::MemoryTamperingDetector` — `setEnabled(bool)` (manual reading dari mangled `...MemoryTamperingDetector10setEnabledEbE...`; fragmen ini tertanam di instantiating template sehingga `c++filt` tidak bisa mendemangle langsung)
   - `usdk::AntiCheat::ICheatDetector`, `CheatDetectorAccessPoint` / `ICheatDetectorAccessPoint`, `AntiCheatValue<T>`, `IAntiCheat`, `IMonitoredValue`
   - String literal: `Memory tampering detector`
2. **Debugger detector:** string `Debugger detector` + `debugger_detector_enabled` + `TracerPid:` + `/proc/self/status` — pola klasik deteksi debugger via `TracerPid != 0` di `/proc/self/status`. (Mekanisme persisnya — seberapa sering dicek, apa konsekuensinya — TIDAK bisa diverifikasi tanpa dekompilasi/runtime.)
3. **Anti-cheat level game (per-fitur, server-oriented):**
   - `CAntiCheatPlugin`, `AntiCheatRollout`, `anticheat_config.dat`, string `-- Anti-cheats active --`
   - `CandyRoyale::CAntiCheatValidator` / `IAntiCheatValidator`, `TriggerQuitDuringLevelAntiCheat`, event `ANTICHEAT_QUIT_DURING_LEVEL`, `ANTICHEAT_UNKNOWN_PROGRESS`
   - `SuperCharger::CAntiCheat`, `OnFire::CAntiCheatConfig`, `AntiCheatTimeProvider` / `IAntiCheatTimeProvider` + peringatan `Adding time offset: ... WARNING this overrides all timestamp anticheat.` (anti time-cheat)
   - `MarathonLeagues::CCheatController`, `EpisodeRace::CServerCheatApiV2` (`AdvanceRace`, `SetWinStreak`, `ResetTournament`, `StartTournament`, `SetTournamentTimeLeft`, `SetSpeedChallengeTimeLeft`) — API "cheat" internal untuk server/dev, dibungkus `CGuardedFunction` (837 kemunculan) — indikasi guard agar hanya jalur resmi yang bisa memanggilnya.
   - `Cheater: {}` dan `Set lives to 0 (use game cheat or wait)` — string UI/debug terkait cheat internal.
4. **Integritas data (bukan integritas APK):** `usdk::Catalog::internal::FifoPacketStorage::doIntegrityCheck`, `usdk::OtaStorage::...HeadIntegrityCheckResult`, `PRAGMA integrity_check` (SQLite), `indicator integrity failure` / `module integrity failure`, `Expeditions.OrlockIntegrity`. Ini soal integritas paket OTA/katalog/data lokal — bukan verifikasi signature APK.

### Yang TIDAK ditemukan (hasil negatif — penting)

- **Tidak ada deteksi root:** nol string word-boundary `rooted` / `magisk` / `supersu` / `busybox`; nol path `/system/bin/su`, `/sbin/su`, `/su/bin`. Semua hit `root` (409) adalah scene-graph root (`GetPopupRoot()`, `root scene object`, `BundleRoot`) atau `SuperSugarCrush` (false positive substring).
- **Tidak ada deteksi emulator:** nol string `emulator` / `genymotion` / `bluestacks` / `nox` / `ldplayer` / `memu` (word-boundary).
- **Tidak ada SafetyNet / Play Integrity dari sisi native:** nol referensi `com.google.android.play.core`, `IntegrityManager`, `SafetyNetClient`. (Bila ada, ia hidup di sisi Java/Kotlin — di luar cakupan dump native ini.)
- **Tidak ada `ptrace`:** 0 string `ptrace`, 0 import `ptrace` (debugger detect memakai `/proc/self/status`/`TracerPid`, bukan `ptrace`).
- **Tidak ada pengecekan signature APK di native:** hit `signature` (117) adalah X.509/OpenSSL (`Signature Algorithm:`, `CA signature digest algorithm too weak`) dan signature JNI (`Could not find method {} with signature {}`), bukan verifikasi signer APK.
- **Tidak ada "ssl pinning" / "certificate pinning":** 0 hit; `certificate` (193) kebanyakan dari OpenSSL/X.509 dan string umum. **Tidak terbukti** ada pinning — dan tidak terbukti juga tidak ada; pinning bisa hidup di Java/OkHttp (di luar `.so` ini).

---

## 5. Crypto & jaringan (native)

- **OpenSSL ter-link statis (TERBUKTI):** ratusan string `AES-128/192/256-*` (CBC, GCM, CTR, CCM, ECB, ...), `OPENSSL_init`, `OPENSSL_init_crypto`, `EVP_*`, `ASN1_verify`, error `OpenSSL internal error`. **Bukan BoringSSL** (string menyebut OpenSSL eksplisit).
- **Enkripsi file lokal:** `usdk::FileSystem::FileEncryptorOpenSsl` — `encrypt` / `decrypt` / `generateDataKey` (manual reading dari nama mangled). File save/data lokal kemungkinan terenkripsi — INFERENSI yang kuat, tapi kunci & algoritma pastinya butuh dekompilasi.
- **HTTP client sendiri (`usdk::Http`), bukan libcurl/okhttp/Cronet:** `usdk::Http::HttpBase::createRequest/executeRequest/cancelRequest/onHttpResponse`, `usdk::Http::HttpImpl`, `usdk::Livetask::HttpEventSourceClient` (SSE), `usdk::Downloader`, `usdk::HealthMonitor::Network`. **Nol** string `libcurl`, `curl_easy`, `okhttp`, `Cronet`. Transport bawahnya memakai `socket`/`connect` libc (import terbukti).
- **Domain yang terlihat di strings** (lengkap di `libcandycrushsaga-strings-interesting.txt` §5): `https://ccs.play.king.com/`, `*.midasplayer.com` / `*.p.midasplayer.com` (aset + `observo-receiver.ext.p.midasplayer.cloud/collect`, `trackita-live-privacy.ext.p.midasplayer.cloud/rpc/events`), `https://graph.facebook.com/v2.12/`, `https://sharelog.midasplayer.com`, `https://www.king.com` (+ terms/privacy), `http://127.0.0.1` (kemungkinan debug/local), `https://candycrushqa.midasplayer.com/FacebookServlet` (QA). Tidak ada kredensial/token telanjang yang terlihat di sampel — dan tidak dicari secara eksplisit di luar pola di atas.

---

## 6. IAP / billing (native)

- **Dua set JNI billing glue** (keduanya diekspor — kemungkinan migrasi/dual-path): `com.king.google.billing.GoogleBillingLibGlue` (`onSetupFinished`, `onQuerySkuDetailsFinished`, `onQueryProductDetailsFinished`, `onQueryPurchasesFinished`, `onPurchaseFinished`, `onConsumeFinished`, `onAcknowledgeFinished`, `onGetBillingConfigFinished`) dan `com.king.storemodule.google.GoogleBillingLibGlue` (setara, minus config/details).
- **Verifikasi pembelian:** string `AppPurchaseApi.verifyPurchase`, `AppStoreApi.verify`, `ProductDelivery` / `ItemDeliverySystem` (dengan `ItemDeliverySystemDebugger` + console commands), `usdk::ItemDeliverer`.
- Total hit `purchase` di strings: 3.271; `IAP`: 538; `billing`: 59 — store adalah permukaan besar di library ini. **Logika harga/SKU dan validasi receipt server-side TIDAK bisa diverifikasi dari `.so` saja.**

---

## 7. Iklan (native) — mediasi King ABM

- **King ABM (ads mediation) internal:** `com.king.abm.*` — `AbmAdapterLoader`, `AdProviderModuleAndroid` (`onAdLoaded`, `onAdMetaReceived`, `onLoadFailed`, `onShowFailed`, `onPaidEvent`, `onPlayCompleted`, ...), `AdProviderSDKAndroid::collectBidderTokenJNI`, `AbmAdPlayer`, `BrowserComponent`, `AbmSdk`.
- **Adapter jaringan iklan pihak ketiga (TERBUKTI dari string `GMA:{}, FAN:{}, Unity:{}, IronSource:{}, VungleSDK:{}, AppLovin:{}, Moloco:{}`):** Google Mobile Ads, Facebook Audience Network, **Unity Ads**, IronSource, Vungle, AppLovin, Moloco.
- **`libapplovin-native-crash-reporter.so` BUKAN modul iklan** — ini crash reporter AppLovin MAX: 3 JNI (`NativeCrashReporter_enable/disable/updateAdInfo`), `handle_signal`, `handle_terminate`, alternate signal stack, `Failed to cache crash report`. Perannya hanya menangkap native crash (SIGSEGV dkk.) — **bukan anti-cheat**, bukan game logic.

---

## 8. Library pihak ketiga yang ter-bundle di `libcandycrushsaga.so` (dari dynsym + strings)

| Library | Bukti |
|---|---|
| FreeType (font) | 148 simbol `FT_*`/`FTC_*` diekspor |
| SQLite | 272 simbol `sqlite3_*` + `PRAGMA integrity_check` |
| Duktape (JS engine) | 278 simbol `duk_*`, `DukTapeScriptManager` |
| Spine (animasi skeletal 2D) | `spSkeleton*`, `spBone`, `spSlot`, `spSkin` |
| Vorbis + Ogg (audio) | 57 `vorbis*`, 35 `ogg*`/`oggpack*` |
| zlib | `inflate`/`deflate` (16/21 simbol), `zip` (89) |
| WebP (parsial) | `WebPYuv*` (7) |
| OpenSSL | lihat §5 |
| Google AGDK | GameActivity, Swappy, Choreographer |
| Lua (scripting) | string `OnFireLua`, `.lua`, pesan error Lua (1.090 hit `lua`, sebagian besar substring/mangled — scripting Lua ada, cakupan pastinya inferensi) |

---

## 9. Dua library kecil — ringkas

- **`libapplovin-native-crash-reporter.so`** (859.832 B, 3.974 string ASCII): murni crash reporter AppLovin (lihat §7). 2.137 simbol dinamis — sebagian besar libc++ STL yang ikut ter-link statis. Tidak ada game logic, iklan aktif, atau anti-cheat.
- **`libdatastore_shared_counter.so`** (6.856 B, 50 string ASCII): library stock **AndroidX DataStore** Google — shared counter via `mmap` + `ftruncate`, 4 JNI (`nativeCreateSharedCounter`, `nativeGetCounterValue`, `nativeIncrementAndGetCounterValue`, `nativeTruncateFile`). Tidak ada game logic/iklan/anti-cheat. (Keanehan kecil: string `exynos9810` + `ro.arch` di dalamnya berasal dari jalur NDK cpu-features/system-property yang ikut ter-link — bukan daftar device check.)

---

## 10. Dynamic loading (`dlopen`)

- `dlopen`/`dlsym` **diimpor** (TERBUKTI) — library ini me-load sesuatu secara dinamis.
- Satu-satunya target `dlopen` yang eksplisit di strings: **`libaaudio.so`** (`AAudioLoader::open() could not find libaaudio.so`, plus format `%s.so`). Tidak ada referensi `dlopen` ke `libunity.so`, `libil2cpp.so`, `libcocos2dcpp.so`, atau `.so` game lain. Target dinamis lain — bila ada — tidak bernama eksplisit di strings (format `%s.so` mengisyaratkan nama dibentuk saat runtime) dan **tidak bisa** dienumerasi secara statis.

---

## 11. TERBUKTI vs INFERENSI

| # | Klaim | Status |
|---|---|---|
| 1 | 3 `.so` arm64-v8a, semua stripped, ukuran + SHA-256 sesuai §1 | TERBUKTI (readelf/sha256sum) |
| 2 | Engine custom King (CCSM + usdk + OnFire); bukan Unity/Cocos/Unreal | TERBUKTI (NEEDED, dynsym, strings, build path) |
| 3 | `JNI_OnLoad` + 182 `Java_*`; billing ganda; ABM ads; AGDK GameActivity/Swappy | TERBUKTI (nm -D) |
| 4 | `usdk::AntiCheat` + `MemoryTamperingDetector` + debugger detector (`TracerPid`) + anti-cheat per-fitur + `anticheat_config.dat` | TERBUKTI dari strings/nama class; **efektivitas & perilaku runtime TIDAK terbukti** |
| 5 | Tidak ada root/emulator detect, SafetyNet/Play Integrity, `ptrace`, atau cek signature APK **di sisi native** | TERBUKTI negatif dari strings+imports (tetap mungkin ada di sisi Java/Kotlin — di luar dump ini) |
| 6 | OpenSSL statis + `FileEncryptorOpenSsl` (enkripsi file lokal) | TERBUKTI keberadaannya; algoritma/kunci pastinya INFERENSI |
| 7 | HTTP client `usdk::Http` sendiri; tanpa libcurl/okhttp/Cronet | TERBUKTI dari strings; detail TLS/pinning INFERENSI |
| 8 | IAP via Google Play Billing (dua glue), verifikasi pembelian | TERBUKTI dari JNI+strings; alur server-side TIDAK terbukti |
| 9 | Mediasi iklan ABM: GMA/FAN/Unity Ads/IronSource/Vungle/AppLovin/Moloco | TERBUKTI dari strings |
| 10 | Lua + Duktape scripting ada | TERBUKTI keberadaannya; peran masing-masing di gameplay INFERENSI |
| 11 | Tidak ada `.so` lain yang di-load dinamis selain `libaaudio.so` | **TIDAK TERBUKTI** — hanya satu target eksplisit; `dlopen` dinamis lain tidak bisa dienumerasi statis |

---

## 12. Batasan

1. **Tanpa Ghidra/IDA/Hopper** — tidak ada dekompilasi dan tidak ada analisis alur kontrol; semua kesimpulan di atas berasal dari header ELF, tabel simbol dinamis, dan strings.
2. **Tanpa runtime** — APK tidak diinstal/dijalankan; perilaku anti-cheat (kapan memicu, apa konsekuensinya), enkripsi (kunci/IV), dan jaringan (endpoint aktual saat main) tidak teramati.
3. **Hanya arm64-v8a** — split armeabi-v7a tidak termasuk dalam input.
4. **Hanya sisi native** — Java/Kotlin (`base.apk`, DEX), manifest, dan aset tidak dianalisis di tugas ini; klaim negatif §4 berlaku khusus untuk `.so`.
5. **Strings ≠ eksekusi** — keberadaan string/simbol membuktikan kode itu ada di binary, bukan bahwa kode itu dijalankan di semua perangkat/konfigurasi (mis. `debugger_detector_enabled` mengisyaratkan flag, dan beberapa jalur bisa di-rollout-kan via `AntiCheatRollout` / `anticheat_config.dat`).
6. **Nama mangled yang dikutip** dibaca manual dari `.rodata`; fragmen yang tertanam di instantiating template `std::function` tidak bisa didemangle langsung oleh `c++filt` (ada `E` penutup template di ekornya) — bacaannya tetap konsisten dengan pola nama di sekitarnya.
