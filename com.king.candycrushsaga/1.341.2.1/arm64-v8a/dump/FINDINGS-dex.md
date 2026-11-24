# FINDINGS — Candy Crush Saga 1.341.2.1 (DEX + Manifest + Aset)

> Dump statis saja. APK **tidak pernah di-install / dijalankan**. Native
> (`libcandycrushsaga.so`, 85 MB) **bukan** urusan dokumen ini — lihat
> `FINDINGS-native.md` di folder yang sama (dibuat agen lain).
> Sumber: `base.apk` (93.578.884 B) + `split_config.arm64_v8a.apk`
> (86.397.543 B) dari `.apkm` APKMirror
> (SHA-256 `7886948de978b25dde0763d0dc14834b12f5c590c19a4d952cf4aa7ab5c8b94a`).
> Package `com.king.candycrushsaga`, versionCode `13412010`,
> versionName `1.341.2.1`, minSdk 24 / targetSdk 37, compileSdk 37 (Android 17).

File-file di folder ini: `zip-inventory.txt`, `hashes.txt`,
`manifest-badging.txt`, `manifest-xmltree.txt`, `signer.txt`, `classes.txt`,
`dex-strings-interesting.txt`, `assets-inventory.txt`, dan dokumen ini.

---

## 1. Arsitektur aplikasi (TERBUKTI dari statis)

Game ini **hampir sepenuhnya native**. Lapisan Java/Kotlin hanyalah selubung
tipis (bridge) di atas satu library C++ raksasa:

- **Entry point**: `com.google.androidgamesdk.GameActivity` (AGDK) →
  `com.king.core.NativeApplication` (`create/init/step/destroy/onTouchEvent/…`)
  → `com.king.candycrushsaga.CandyCrushSagaActivity` (launcher) +
  `PlatformProxy::createNativeInstance`.
- **Seluruh logika game** (board, level, skor, ekonomi, validasi) tinggal di
  `lib/arm64-v8a/libcandycrushsaga.so` (85.487.344 B, hanya ada di split
  arm64; `base.apk` berisi **NOL** file `.so`).
- **Bridge Java→native** (`com.king.usdk.*`, ~92 native method di
  `classes.dex` + 106 di `classes4.dex`): lifecycle, Braze, Facebook SDK,
  AppsFlyer, notifikasi lokal/push, OneTrust consent, popup WebView,
  observo (tracing), sharing, billing callbacks, age-signals. Semuanya
  callback **ke** native — Java tidak memegang logika.
- **Mediation iklan King sendiri ("ABM")**: `com.king.abm.*` (~490 class) +
  JNI `AdProviderModuleAndroid` / `AdProviderSDKAndroid`
  (`collectBidderTokenJNI`, `onAdLoaded`, `onPaidEvent`, …). ABM duduk
  di atas AppLovin MAX, ironSource/LevelPlay, Unity Ads, Vungle, Moloco,
  AdMob, dan Meta Audience Network.
- **Gateway protocol King**: `gatewayprotocol.v1` (704 class, protobuf,
  `classes5.dex`) — `InitializationRequest/Response`,
  `AdPlayerConfigRequest/Response`, `AdDataRefreshRequest/Response`,
  `TransactionEventRequest`, `GetTokenEventRequest` / `LimitedSessionToken`,
  `HeaderBiddingToken`, `FeatureFlags`, `DiagnosticEventRequest`, dsb.
  Transport: Ktor + OkHttp3 + Retrofit2 (`classes5.dex`).
- **Stack**: Kotlin + Jetpack Compose (2.355 class) + media3/ExoPlayer
  (1.923) + DataStore (729) + WorkManager (450) + Room (107) + Coil +
  Glide + Chromium WebView. R8 aktif (nama `$r8$lambda$*`, file proguard
  di `META-INF`).

### DEX — angka (TERBUKTI, dihitung dari header DEX)

| DEX | Ukuran | String | Type | Method | Class |
|---|---|---|---|---|---|
| classes.dex | 9.146.304 | 70.257 | 10.963 | 63.699 | 9.062 |
| classes2.dex | 8.248.776 | 57.802 | 12.774 | 62.343 | 10.030 |
| classes3.dex | 7.955.140 | 39.252 | 13.261 | 61.791 | 11.005 |
| classes4.dex | 9.157.528 | 67.162 | 13.475 | 55.636 | 10.096 |
| classes5.dex | 2.951.756 | 20.581 | 3.883 | 29.019 | 3.328 |
| audience_network/classes.dex | 5.455.144 | 32.685 | 5.040 | 30.913 | 3.605 |
| **Total** | | | | **303.401** | **47.126** |

Semua DEX v037 kecuali Audience Network (v035). Isi per DEX:
`classes.dex` = Compose/media3/King; `classes2.dex` = Google/Braze
(2.623)/AppLovin (1.247)/Facebook/Glide/AppsFlyer/Moloco;
`classes3.dex` = **100% `com.google`** (GMS ads 6.566 class, measurement,
Play Billing internal, Play Integrity, Firebase, Material);
`classes4.dex` = ironSource (3.241) / Unity (2.576) / Moloco (1.910) /
OneTrust (861) / Vungle (767) / King (741);
`classes5.dex` = Kotlin runtime + Ktor + `gatewayprotocol.v1`.

## 2. SDK / framework yang terdeteksi (TERBUKTI)

- **Iklan**: AppLovin MAX, ironSource LevelPlay (+AdQuality), Unity Ads,
  Vungle/Liftoff, Moloco, Google AdMob, Meta Audience Network, OMID
  (IAB, 5 vendor) + MRAID. AdMob App ID (manifest):
  `ca-app-pub-6472038563747829~9001368100`.
- **Analitik/atribusi**: Braze (push + in-app message + content cards),
  AppsFlyer, Firebase Analytics/Messaging/Installations, Facebook SDK
  (App ID `210831918949520`), Google Play Games.
- **Consent/privasi**: OneTrust (861 class), Google UMP, Samsung Age
  Signals, Amazon PrivacyPass (attestation).
- **IAP**: Google Play Billing **8.3.0** (`com.king.store.BillingManager`,
  `com.king.google.billing.GoogleBillingLibGlue`,
  `com.king.storemodule.google.GoogleBillingLibGlue`); permission
  `BILLING` + `CHECK_LICENSE`; Amazon IAP `ResponseReceiver` (exported,
  action `com.amazon.inapp.purchasing.NOTIFY`) — jalur Amazon ada tapi
  dormant di build Play ini.
- **Lainnya**: Ada support SDK (`support.ada`), Braze geofence dimatikan
  (`com_braze_enable_location_collection=false`).

## 3. Permission berisiko (TERBUKTI dari manifest)

21 `uses-permission`, tidak ada yang berbahaya-klasik (tanpa lokasi,
kamera, mikrofon, storage, kontak, SMS, telepon). Yang patut dicatat:

- `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `WAKE_LOCK`, `VIBRATE`,
  `RECEIVE` (FCM), `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`.
- `AD_ID` + `ACCESS_ADSERVICES_*` (AD_ID, ATTRIBUTION, TOPICS,
  CUSTOM_AUDIENCE) — iklan/attribution.
- `BIND_GET_INSTALL_REFERRER_SERVICE`, `CHECK_LICENSE`,
  `com.amazon.privacypass.ATTEST`, `com.applovin.array.apphub.permission.BIND_APPHUB_SERVICE`,
  `com.samsung.android.mapsagent.permission.READ_APP_INFO`,
  `com.huawei.appmarket.service.commondata.permission.GET_COMMON_DATA`.
- Permission kustom `com.king.candycrushsaga.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`
  (protectionLevel signature, 0x2).
- `application`: `allowBackup=false`, `debuggable=false`,
  `extractNativeLibs=false`, `profileable shell=true`,
  `networkSecurityConfig` ada, `backupAgent =
  com.king.usdk.cloudstorage.KingBackupAgentHelper`.
- **Cleartext diizinkan hanya untuk** `127.0.0.1`, `midasplayer.com`,
  `midasplayer.cloud` (semua subdomain) — domain infra King. Sisanya
  wajib HTTPS (menurut config; enforcement runtime tidak diverifikasi).

## 4. Komponen exported (TERBUKTI dari manifest)

56 activity, 14 service, 21 receiver, 12 provider. Yang `exported=true`:

| Komponen | Catatan |
|---|---|
| `CandyCrushSagaActivity` (launcher) | Deep link `candycrushsaga://`, `candycrush://`, `https://ccs.play.king.com` |
| `com.facebook.CustomTabActivity` | `fbconnect://cct.com.king.candycrushsaga` |
| `com.amazon.device.iap.ResponseReceiver` | `com.amazon.inapp.purchasing.NOTIFY` |
| `com.king.usdk.kdid.AnalyticsReceiver` | `BOOT_COMPLETED`, `com.king.analytics.REQUEST_VALUE/RECEIVE_VALUE` — receiver King sendiri, menerima broadcast kustom |
| `com.king.usdk.nativesharing.NativeSharingReceiver` | tanpa intent-filter tercantum |
| `com.google.firebase.iid.FirebaseInstanceIdReceiver` | dilindungi `com.google.android.c2dm.permission.SEND` |
| `androidx.work.impl.background.systemjob.SystemJobService` | dilindungi `BIND_JOB_SERVICE` |
| `androidx.profileinstaller.ProfileInstallReceiver` | dilindungi `DUMP` |
| `androidx.work.impl.diagnostics.DiagnosticsReceiver` | dilindungi `DUMP` |

Tidak ada activity/service/receiver King yang exported tanpa perlindungan
selain dua receiver King di atas (AnalyticsReceiver dan
NativeSharingReceiver — keduanya tanpa `permission` di manifest; dampaknya
tergantung apa yang dilakukan native saat menerima broadcast tersebut,
dan itu **tidak bisa dinilai dari DEX**).

Meta-data penting (manifest): Facebook App ID + ClientToken, AdMob App
ID, `firebase_analytics_collection_enabled=false`,
`google_analytics_default_allow_ad_user_data=false`,
`google_analytics_default_allow_ad_personalization_signals=false`,
`com.facebook.sdk.AutoLogAppEventsEnabled=false` (analytics
consent-gated), `APPSFLYER_ALLOW_CUSTOM_INSTALL_ID=true`,
`android.webkit.WebView.MetricsOptOut=true`, `android.max_aspect=2.1`,
`com.android.stamp.type=STAMP_TYPE_DISTRIBUTION_APK` (Play asset stamp),
`com.android.vending.splits.required=true`.

## 5. Signer (TERBUKTI)

- 1 signer: `CN=Cristian Bidea, OU=Mobile, O=king.com, L=Bucharest,
  ST=Romania, C=RO` — self-signed, RSA 2048, SHA-256 cert
  `ac7f3b3537e8e6797be7270fa4f9f6a2414e660f51a86efd47c75f00603bc328`.
- Berlaku **2012-01-12 → 2039-05-30**; algoritma tanda tangan sertifikat
  `sha1WithRSAEncryption` (legacy — kunci rilis King yang sudah lama).
- base.apk: **v2 + v3 saja** (v1 JAR signing FALSE — tidak ada entri
  `META-INF/*.SF/*.RSA` sama sekali). Split: v1 (bundletool) + v2 + v3.
- SourceStamp Google hadir (RSA 4096, SHA-256 `3257d599…`); blok
  Veracity (0x42726577) juga ada.

## 6. IAP / iklan / anti-cheat / validasi server

### TERBUKTI dari statis
- **IAP = Google Play Billing 8.3.0** via `BillingManager` +
  `GoogleBillingLibGlue`; callback purchase/consume/acknowledge/query
  diteruskan ke native. **Tidak ada satu pun SKU / product-id literal**
  di DEX — katalog produk bersifat server-driven atau berada di native.
- **Iklan dimediasi King (ABM)** di atas 7 jaringan; tidak ada AppLovin
  SDK key, Unity Game ID, atau ironSource app key dalam bentuk literal
  di DEX/resources (kemungkinan disuplai dari native atau config server).
- **Play Integrity API hadir** (`com.google.android.play.core.integrity.*`
  + `com.google.android.play.integrity.internal.*`, `classes3.dex`) —
  satu-satunya mekanisme device-trust yang terbukti ada di DEX.
  Amazon PrivacyPass attestation juga ada (permission + callback).
- **Tidak ada** kelas anti-cheat/tamper (`*AntiCheat*`, `*Tamper*`,
  `*CheatDetect*`), tidak ada string `/system/bin/su`,
  `/system/xbin/su`, Magisk, Xposed, RootBeer, atau SafetyNet di DEX.
- **Dua string yang mudah disalahartikan** (keduanya BUKAN bukti
  anti-cheat):
  - `DeviceRootedStatus` (`classes.dex`) — literal berdampingan dengan
    `DeviceRiskyUtilities.java`/`DeviceUtilities.java`; pemilik kelasnya
    tidak ter-resolusi oleh pemindaian string; kemungkinan besar enum
    device-info milik SDK iklan, **bukan** terbukti pemeriksaan root King.
  - `FRIDA` (`classes2.dex`) — berdampingan alfabetis dengan
    `FYBER`/`FOURSQUARE` di tabel string, yaitu di dalam daftar nama
    jaringan iklan; **bukan** bukti deteksi Frida.
  - `KEY_MOCK_LOCATION` juga ada sebagai literal tanpa pemilik ter-resolusi.
- **Level/balance sepenuhnya lokal di aset**: `levels_batched.db`
  (SQLite, 44,7 MB) berisi **24.005 level** sebagai JSON
  (`protocolVersion "0.3"`: `tileMap`, `scoreTargets[3]`, `moveLimit`,
  `gameModeName`, `levelDefinitionId_meta`, `version_meta`). Indeks
  `levels.xml` (BIN1) merujuk `levels/episodeNlevelM.txt` sampai
  episode 1601. Hanya 4 file level `.txt` standalone di APK; sisanya
  hanya ada di dalam `.db`. Paket OTA (`ota-dynamic_difficulty_*`,
  `ota-first_attempt_challenge-default`, `ota-curved_map-autumn`)
  menunjukkan tuning difficulty bisa diubah dari server.
- **Aset game** memakai format proprietary King (`.ffm/.ffa/.ffsb/.ng/
  .prefab/.manifest`, scene/prefab XML 5.313 file, JSON 1.112 file,
  11 script `.lua` binding native↔Java, 314 `.ogg`, 643 `.webp`).
  WebView GDPR / King-account / consent dikirim sebagai HTML/JS di aset.

### INFERENSI (belum terbukti — butuh analisis native / runtime)
- Host game King kemungkinan `ccs.play.king.com` (deep link) dan/atau
  domain `midasplayer.*` (cleartext-allowed) — **tidak ada** URL endpoint
  King dalam bentuk literal di DEX; endpoint hampir pasti dibentuk di
  native lib atau diterima lewat gateway protobuf.
- Validasi skor/progress kemungkinan server-side (pola King + adanya
  `TransactionEventRequest`, `LimitedSessionToken`, Play Integrity) —
  **tidak terbukti** dari DEX; pembuktian butuh REA
  `libcandycrushsaga.so` dan/atau traffic runtime.
- `DeviceRootedStatus` **mungkin** dipakai salah satu SDK untuk
  memberi sinyal risiko perangkat ke server iklan — bukan kesimpulan.

## 7. Batasan (apa yang TIDAK bisa diverifikasi)

1. **Tidak ada dexdump / jadx / baksmali di VM ini** — hitungan
   class/method, daftar class, daftar native method, dan ekstraksi
   string dikerjakan dengan parser DEX Python tulisan sendiri
   (membaca header, `string_ids`, `type_ids`, `class_defs`,
   `class_data`). Hasilnya konsisten lintas DEX dan cocok dengan
   `aapt2`/apktool, tapi **bukan** dekompilasi: tidak ada isi method,
   tidak ada control-flow, tidak ada cross-reference string→class.
   Atribusi string ke pemilik kelas (mis. `DeviceRootedStatus`,
   `FRIDA`) tidak dimungkinkan dengan tool ini.
2. **Tidak ada dekompilasi mendalam / Ghidra** untuk DEX maupun native.
   Semua kesimpulan perilaku (validasi server, anti-cheat, alur IAP)
   adalah inferensi dari nama class/string, bukan bukti eksekusi.
3. **Native tidak disentuh** sesuai tugas — 85 MB `libcandycrushsaga.so`
   (tempat logika game, endpoint, dan kemungkinan validasi berada)
   tidak dianalisis di sini; lihat `FINDINGS-native.md`.
4. **Tidak ada runtime**: perilaku aktual (request jaringan, token,
   Integrity verdict, isi traffic gateway) tidak diamati.
5. **SDK key / secret**: AppLovin SDK key, Unity Game ID, ironSource
   app key, Braze/AppsFlyer key tidak ditemukan sebagai literal —
   tidak berarti tidak ada (kemungkinan di native / obfuscated /
   server). Nilai `google_api_key` di `res/values/strings.xml` sengaja
   tidak dicantumkan di laporan ini.
6. **Aset proprietary** (`.ffm/.ffa/.ffsb/.ng/.prefab`, isi
   `package.index`, format BIN1 `levels.xml`) hanya diidentifikasi dari
   nama/ukuran/magic — isinya tidak di-parse kecuali `levels_batched.db`
   (SQLite, dibaca skema + 2 baris sampel) dan `levels.xml` (header).
7. **Perubahan runtime**: paket OTA dan gateway `FeatureFlags`
   berarti sebagian perilaku dikendalikan server dan bisa berbeda dari
   dump statis ini.

## 8. Temuan terpenting (ringkas)

1. **Game 100% native** — Java hanya bridge; semua logika di
   `libcandycrushsaga.so` (85 MB, split arm64). REA lanjutan harus ke
   native, bukan DEX.
2. **24.005 level lengkap sebagai JSON di SQLite** (`levels_batched.db`,
   44,7 MB) — board, target skor, move limit, mode, dan ID definisi
   level semuanya terbaca statis (format `protocolVersion 0.3`).
3. **Play Integrity adalah satu-satunya device-trust yang terbukti**;
   tidak ada jejak RootBeer/Magisk/Xposed/Frida-check di DEX
   (`DeviceRootedStatus`/`FRIDA` adalah literal yang mudah disalahbaca —
   lihat §6).
4. **Iklan dimediasi King sendiri (ABM)** di atas 7 jaringan
   (AppLovin MAX, ironSource, Unity, Vungle, Moloco, AdMob, Meta AN)
   dengan header-bidding (`HeaderBiddingToken`) via gateway protobuf
   King (`gatewayprotocol.v1`).
5. **Tidak ada endpoint server King dalam bentuk literal di DEX** —
   host yang terlihat hanya `ccs.play.king.com` (deep link) dan
   `midasplayer.com/.cloud` (cleartext-allowed); endpoint hampir pasti
   di native.
6. **IAP = Play Billing 8.3.0, tanpa SKU literal** — katalog produk
   server-driven; jalur Amazon IAP ada tapi dormant.
7. **Signer King lama** (2012–2039, RSA 2048, `sha1WithRSAEncryption`),
   base.apk hanya v2+v3 (tanpa v1); SourceStamp Google hadir.
8. **Manifest rapi/ketat**: tanpa permission berbahaya, `allowBackup=
   false`, `debuggable=false`, analytics consent-gated (Firebase +
   Facebook auto-log mati di manifest), 2 receiver King exported tanpa
   `permission` (`AnalyticsReceiver`, `NativeSharingReceiver`).
9. **OTA/dynamic difficulty** (`ota-dynamic_difficulty_*`,
   `ota-first_attempt_challenge-default`) + `FeatureFlags` gateway —
   sebagian tuning game dikendalikan server.
10. **Build artefact leakage**: metadata Kotlin Multiplatform (`.knm`)
    dan file proguard ikut terkirim di APK — berguna untuk pemulihan
    simbol pada REA lanjutan.
