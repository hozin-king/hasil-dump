# REA + Dump — Amora (`com.litapps.selfly`) v3.6.0 / code 362

Tanggal: 11 Nov 2026. Analisis statik saja, tanpa runtime, tanpa build/mod.

## 0. Vonis singkat

**File ASLI — build resmi Google Play, bukan repack/mod.** Bukti: apksigner lolos di semua split; signer = sertifikat Google Play App Signing (`CN=Android, OU=Android, O=Google Inc.`, RSA 4096); stamp Play di manifest (`com.android.stamp.source = https://play.google.com/store`, `STAMP_TYPE_DISTRIBUTION_APK`); SHA-1 XAPK cocok dengan metadata API APKPure; ukuran XAPK persis sama dengan metadata API; listing Play independen (Lit Apps LLC) cocok dengan paket + nama aplikasi.

**Aplikasinya: Amora — aplikasi astrologi / soulmate (Lifestyle), bukan game.** Fitur utama: potret soulmate AI, birth chart (Sun/Moon/Rising), tarot harian, horoskop, kompatibilitas, astrocartography (peta), aura dari foto, koin + streak + roda hadiah, langganan Premium (weekly/yearly) + paket koin via Play Billing/Qonversion. Semua konten AI + premium **server-gated** (Firebase Cloud Function + Play Billing); koin disimpan lokal (AsyncStorage) dengan mode server-coins di balik flag — otoritas saldo **belum terverifikasi statik**.

## 1. Perolehan

- Tautan user: `[tautan unduhan dihapus — minta ke Alyaa]` (host ini kena Cloudflare challenge untuk klien non-browser — tidak dipakai langsung, sesuai pola terbukti).
- Jalur tembus: API publik APKPure `api.pureapk.com/m/v3/cms/app_version?hl=en-US&package_name=com.litapps.selfly` (resep open-source `apkeep` / EFForg, header `x-cv: 3172501`, `x-sv: 29`, `x-abis: arm64-v8a,...`, `x-gp: 1`) → HTTP 200, respons protobuf 117.521 byte (`api_response.bin`), berisi daftar versi; URL unduh versi 362 diekstrak dari marker `XAPKJ`.
- URL CDN bertanda tangan (disimpan di `download_url.txt` — berlaku ±2 hari, jangan disebar): `download.pureapk.com/b/XAPK/com.litapps.selfly_362_b89a2003` (`_fn=Amora_v3.6.0_apkpure.com.xapk`, `s=156521630`, `vn=3.6.0`, `vc=362`, dev `Lit Apps LLC (Mobile)`, kategori `LIFESTYLE`).

## 2. Identitas & verifikasi

| Item | Nilai |
|---|---|
| File | `Amora_v3.6.0_apkpure.com.xapk` |
| Ukuran XAPK | 156.521.630 byte (= metadata API `s=156521630`, persis) |
| SHA-256 XAPK | `fc7a5cb8a533a8cdd4d634b67321cd80ed3af4c94484d4a8cfdc8fb6668cc328` |
| SHA-1 XAPK | `c4523a58265ae0454114b6893855492a2ea58d03` — **ditemukan di `api_response.bin`** (cocok metadata APKPure) |
| Package | `com.litapps.selfly` |
| versionName / versionCode | 3.6.0 / 362 |
| minSdk / targetSdk / compileSdk | 24 / 36 / 36 (Android 16) |
| Label aplikasi | Amora |
| Launcher activity | `com.litapps.selfly.MainActivity` |
| Deep link | scheme `lualaapp` + `https` |
| Isi XAPK (22 entri) | base APK 120.873.120 B + `config.arm64_v8a.apk` 34.486.641 B + 18 config locale + `config.xxhdpi.apk` + `icon.png` + `manifest.json` (xapk_version 2). **Tidak ada OBB.** |
| Base APK SHA-256 | `38ab874738859729508faecf0a160ca4315a4d977721c4e19095eb57abc6e8c0` |
| config.arm64_v8a SHA-256 | `17f119e5fcb39fb51b89f58589e812082bfa5ec7e0ddae430bfac8a2a2db226f` |
| apksigner | **Verifies** (base + arm64 split) |
| Signer DN | `CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US` |
| Signer SHA-256 | `2572df880c86cc4f68506f9c750e727fa7bae7e69ae878869dd20e295362206c` |
| Signer SHA-1 / MD5 | `5c53557d5077cafa98db9b6f1af9e38d800432d0` / `d031362ba6e5edc439de354d58436eb4` |
| Kunci signer | RSA 4096 — sertifikat Play App Signing Google |
| Verifikasi independen | Listing Play `com.litapps.selfly` ("Amora: A Hint of Your Soulmate", Lit Apps LLC, update 11 Agu 2026) cocok; Uptodown/Softonic mencatat 3.5.0 (21 Sep 2026) — 3.6.0 ini lebih baru, konsisten dengan APKPure membawa rilis terbaru. Perhatian: ada aplikasi lain bernama mirip, "Amora - Astra Soulmate Draw" (`com.aiany.astra`, Top Infinity LLC) — **bukan** aplikasi ini. |

## 3. Ringkasan aplikasi

Amora adalah aplikasi astrologi & self-reflection (kategori Lifestyle, gratis + IAP). Dari `assets/app.config` (Expo SDK 56.0.0, slug `selfly-app`, owner `topinit`, EAS projectId `6bbc1f3e-…`, scheme `lualaapp`, UI gelap, portrait) dan string bundle JS:

- **Onboarding**: nama, tanggal + jam lahir, lokasi, preferensi gender → hasil soulmate.
- **AI Soulmate Portrait**: potret pasangan imajiner dari data lahir (framing polaroid, bisa disimpan/dibagikan); "blend your face with your soulmate's portrait" via kamera/galeri.
- **Birth chart / love profile**: Sun, Moon, Rising, love language, attachment style, warning signs.
- **Tarot harian + horoskop + kompatibilitas** (dengan crush/teman/keluarga).
- **Astrocartography**: peta (MapLibre + style CARTO dark-matter/voyager) — "di mana dia tinggal sekarang / di mana dia bermula".
- **Aura**: baca warna aura dari foto pengguna.
- **Ekonomi koin**: koin untuk membuka bacaan; quests harian, streak + streak-freeze, roda hadiah (wheel spins), refund pembelian koin, starter offer. Kunci AsyncStorage: `@amora/coins_balance_owner_v1`, `@amora/credited_coin_txns`, `@amora/pending_coin_purchase`, `@amora/server_coins_enabled`, `@amora/server_coins_killed` (flag/kill-switch mode koin server).
- **Langganan Premium**: `weekly_sub` (base plan `weeklysub`), `yearly_sub`; paket koin `10_coins`, `30_coins`, `1000_coins` — semuanya memberi permission `premium` (Qonversion). Paywall NoCodes, variasi `Paywall_A_Control` (+ varian uji `test2-v1/v3/v5`, `test3-v3/v25`, winback).
- **Auth**: Firebase Auth (email kode verifikasi + Google Sign-In), `getIdToken` dipakai.
- **Notifikasi**: FCM + Expo Notifications (termasuk location task + boot receiver).

## 4. Struktur & dump

### 4.1 Teknologi

- **React Native + Expo SDK 56** (Hermes): `libhermesvm.so`, `libreactnative.so`, `libexpo-modules-core.so`, `libappmodules.so`; bundle JS Hermes `assets/index.android.bundle` 53.293.888 byte (~51 MB, 53.990 string); `expo-router`, `expo-updates` **ENABLED=false** (tidak ada OTA — aplikasi sepenuhnya terbundel).
- **Kotlin/Java**: `classes.dex` 9.576.396 B + `classes2.dex` 9.086.800 B; R8-obfuscated (paket satu huruf, 19.222 file smali); `MainActivity`/`MainApplication` standar Expo.
- **Native libs (arm64 split, 27 .so)**: `libmaplibre.so` 11.591.368 B (peta), `libreactnative.so`, `libreanimated.so`, `libworklets.so`, `libhermesvm.so`, `libexpo-modules-core.so`, `libappmodules.so`, `libavif_android.so`, `libzstd-kmp.so`, `libjsi.so`, `libfbjni.so`, codec gambar (gif/webp/animasi), `libnative-filters.so`, `libnative-imagetranscoder.so`. **Tidak ada .so injeksi / game engine / IL2CPP.**
- **Base APK**: 2.740 entri (assets 1.258, res 1.177, META-INF 137). Terbesar: bundle JS 53 MB, dex 9,5 + 9 MB, gambar playgrid/heartrotating/playbackground, video `amoracoverlogo.mp4`, font Material Symbols + vector icons.

### 4.2 Manifest (apktool decode)

- Activities: `MainActivity` (exported), `expo.modules.video.FullscreenPlayerActivity`, cropper (`CropImageActivity`, `ExpoCropImageActivity`), `NotificationForwarderActivity`, `BrowserProxyActivity`, `io.qonversion.nocodes...ScreenActivity` (paywall), Google Sign-In `SignInHubActivity`, billing `ProxyBillingActivity(V2)`, `GoogleApiActivity`, `PlayCoreDialogWrapperActivity`, **`com.pairip.licensecheck.LicenseActivity`**.
- Services: Firebase ComponentDiscovery + Messaging, `expo.modules.location...LocationTaskService`, `ExpoFirebaseMessagingService`, datatransport scheduler.
- Receivers: notifications, `FirebaseInstanceIdReceiver` (exported), `ProfileInstallReceiver` (exported), datatransport alarm.
- Providers: Firebase init/app, Expo FileSystem/Sharing/Clipboard/ImagePicker FileProviders, CropFileProvider — semua non-exported.
- Permissions (36): INTERNET, CAMERA, lokasi halus+kasar, SYSTEM_ALERT_WINDOW, VIBRATE, penyimpanan, BOOT_COMPLETED, POST_NOTIFICATIONS, DETECT_SCREEN_CAPTURE, USE_BIOMETRIC + USE_FINGERPRINT, BILLING, WAKE_LOCK, C2DM RECEIVE, BIND_GET_INSTALL_REFERRER_SERVICE, CHECK_LICENSE, + izin badge launcher (Samsung/HTC/Sony/Huawei/Oppo/dll). `app.config` memblokir `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `ACTIVITY_RECOGNITION`; meminta `RECORD_AUDIO`.
- Meta-data penting: `expo.modules.updates.ENABLED=false`, `com.android.stamp.source=https://play.google.com/store`, `STAMP_TYPE_DISTRIBUTION_APK`, billing client 8.1.0, `com.android.vending.splits.required=true`, `app_data_collection_default_enabled=true`.

### 4.3 SDK & endpoint (dari string dex + JS + app.config)

| SDK / layanan | Bukti |
|---|---|
| Firebase (project `amora-app-c82b4`) | `google-services` di strings.xml (`project_id`, `google_storage_bucket ...firebasestorage.app`); `@react-native-firebase/app`; FCM; Auth; `securetoken.google.com` |
| AI via Cloud Function | `aiProxyUrl = https://us-central1-amora-app-c82b4.cloudfunctions.net/ai_proxy` (di `app.config` extra; dibaca bundle lewat Expo Constants) |
| RapidAPI — GeoDB | `ft-geo-db.p.rapidapi.com` (lookup negara/kota by calling code); kunci RapidAPI **tertanam di app.config** (nilai tidak dikutip di laporan ini) |
| Qonversion + NoCodes | paywall `ScreenActivity`, `qonversion_android_fallbacks.json` (produk + `paywall_variation: Paywall_A_Control`); project key tertanam di app.config |
| Google Play Billing 8.1.0 | `billing.properties`, `ProxyBillingActivity`, produk `weekly_sub`/`yearly_sub`/`10_coins`/`30_coins`/`1000_coins` |
| Mixpanel | token tertanam di app.config; `api.mixpanel.com`; `mixpanelEnabled: false` (tetap ada token + sampleRate 1) |
| MapLibre + CARTO | `libmaplibre.so`; style `basemaps.cartocdn.com/gl/dark-matter-gl-style` + `voyager-gl-style` |
| Expo Notifications / Location / SecureStore / ImagePicker / Video / Sharing / WebBrowser | plugin di app.config + modul native |
| Slack webhook | URL webhook tertanam di `app.config` extra (`SLACK_WEBHOOK`, `SLACK_WEBHOOK_PERSONAL_READING`, `SLACK_WEBHOOK_PURCHASES`) — nilai tidak dikutip |
| Time4J | data kalender (islamic, nengo, dsb.) di `assets/net/time4j/` — komputasi tanggal/astrologi lokal |
| Google Fonts | `fonts.gstatic.com` (Cormorant Garamond, Dancing Script, Newsreader) |

**Catatan kredensial tertanam:** `app.config` (ikut terkirim di dalam APK, bisa diekstrak siapa pun) memuat: kunci RapidAPI, Firebase API key, token Mixpanel, Qonversion project key, dan URL Slack webhook. Nilai-nilainya **sengaja tidak disalin ke laporan ini**. Yang paling sensitif: RapidAPI key + Slack webhook (keduanya bisa dipakai pihak lain bila bocor); Firebase API key & Qonversion project key adalah client key yang memang didesain tertanam di aplikasi.

### 4.4 Proteksi & penyimpanan

- **PairIP license check**: `com.pairip.licensecheck` lengkap (`LicenseClient`, `LicenseActivity`, `LicenseContentProvider`, `ILicenseV2ResultListener`, `TrialClient`, `RepeatedCheckMetadata`) + `com.pairip.application.Application` — verifikasi lisensi Play (LVL v2). Ini satu-satunya proteksi anti-repack yang terdeteksi.
- **Tidak ada** bukti statik untuk: deteksi root (string `isRooted` hanya `isRootedExperimentalAsync` milik expo-device, API standar, bukan enforcement), SafetyNet/Play Integrity, deteksi Frida/Xposed/emulator/debugger (hitungan string kecil itu substring di dalam blob wordlist kelas obfuscated `te/e.smali` + pustaka time4j, bukan cek aktif), SSL pinning (`CertificatePinner` 0 di smali), enkripsi konten lokal khusus.
- **Penyimpanan lokal**: expo-secure-store (EncryptedSharedPreferences + AndroidKeyStore), AsyncStorage (puluhan kunci `@amora/...`, termasuk saldo koin & flag server-coins), DataStore Preferences, SQLite. Tidak ada database Room khusus aplikasi yang teridentifikasi.
- **Tidak ada** aktivitas anti-screenshot (DETECT_SCREEN_CAPTURE hanya permission deklarasi; tidak ada FLAG_SECURE yang terkonfirmasi statik).

## 5. Klasifikasi server vs lokal

| Fitur | Vonis | Bukti |
|---|---|---|
| Pembelian Premium & paket koin | **SERVER-GATED** | Produk Play Billing (`weekly_sub`, `yearly_sub`, `10/30/1000_coins`); entitlement via Qonversion (verifikasi receipt server); paywall NoCodes remote config |
| Potret soulmate AI + bacaan AI | **SERVER-GATED** | Dihasilkan via Cloud Function `ai_proxy` (Firebase `amora-app-c82b4`); klien hanya mengirim data lahir + menerima hasil |
| Auth akun (email/Google) | **SERVER-GATED** | Firebase Auth (`securetoken.google.com`, `getIdToken`) |
| Saldo koin | **BELUM TERVERIFIKASI** | Saldo di-cache lokal (`@amora/coins_balance_owner_v1`, AsyncStorage) TAPI ada mode server-coins (`@amora/server_coins_enabled`, `@amora/server_coins_killed`, `@amora/credited_coin_txns`, `@amora/pending_coin_purchase`) — otoritas akhir (lokal vs server) tidak bisa dipastikan tanpa runtime |
| Perhitungan birth chart / tarot / horoskop (template) | **LOKAL** | Pustaka Time4J + konten teks multibahasa terbundel di bundle JS (ribuan string zodiak/kompatibilitas); peta dihitung dari koordinat lokal |
| Peta astrocartography | **CAMPURAN** | Render lokal (MapLibre) + tile/style dari CARTO CDN |
| Streak / quests / roda hadiah | **LOKAL (kemungkinan)** | Logika + kunci AsyncStorage lokal (`@amora/streak...`, `@amora/grid_drops_v1`, `@amora/wheel...`); tidak ada endpoint server khusus yang teridentifikasi untuk ini — belum terverifikasi |
| Lisensi aplikasi | **SERVER-GATED** | PairIP LVL v2 ke Play |

## 6. Batas jujur

- Analisis **statik saja** (tanpa instal/jalan di perangkat): perilaku runtime, isi respons `ai_proxy`, dan otoritas saldo koin tidak bisa dipastikan dari sini.
- Bundle JS adalah bytecode Hermes — string bisa diekstrak, tapi alur kode tidak di-decompile; klaim di atas didasarkan pada string + konfigurasi + struktur, bukan eksekusi.
- Kelas aplikasi ter-obfuscate R8 (nama paket satu huruf) — tidak ada dekompilasi method-per-method.
- Tidak ada perbandingan dengan APK resmi dari Play Store langsung (yang dipakai adalah file APKPure yang terverifikasi lewat signer Play + hash metadata + stamp Play).

## 7. File bukti

- `Amora_v3.6.0_apkpure.com.xapk` (156.521.630 B, SHA-256 `fc7a5cb8…cc328`)
- `api_response.bin` (respons protobuf API APKPure), `download_url.txt` (URL CDN bertanda tangan), `headers.txt`
- `xapk/` (XAPK terekstrak: base + 20 split + manifest.json), `extracted/` (base APK terekstrak), `extracted-arm64/` (split arm64 terekstrak)
- `apktool_out/` (decode apktool: AndroidManifest.xml, smali, res), `apktool.log`
- `apk_contents.txt` (inventaris 2.799 baris), `dumps_badging.txt` (aapt2 badging), `dump/strings_js.txt` (53.990 string bundle JS), `dump/strings_dex.txt` (113.221 string dex)
