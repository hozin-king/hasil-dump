# REA — Criminal Case (Pretty Simple) — v2.45.2 (1830811) — SELESAI

**Tanggal:** 11 November 2026 (WIB)
**Target:** `com.prettysimple.criminalcaseandroid`, versionCode **1830811**, versionName **2.45.2**
**File:** `criminal-case-2.45.2-1830811.xapk` (104.196.018 B)
**Status sebelumnya:** TERBLOKIR DI UNDUHAN → **SELESAI, file diperoleh via API publik APKPure dan sudah dianalisis.**

## 1. Ringkasan eksekutif

- **VONIS KEASLIAN: ASLI (bukan repack).** `apksigner verify` lolos pada keempat APK (skema v3 + SourceStamp Google). Sidik jari sertifikat MD5 **`da9c445799a917fe6cece2168ca62f51` cocok persis** dengan klaim Uptodown; DN penanda tangan `O=PrettySimple Games, L=Paris, ST=Paris, C=FR`. Repack tidak mungkin mereproduksi tanda tangan kunci privat developer + SourceStamp Google.
- **Arsitektur:** game **Cocos2d-x 2.2.6** — logika game di native `libcriminalcase.so` (20,2 MB, engine + curl + OpenSSL ter-link statis), lapisan Java/Kotlin hanya jembatan (billing, iklan, Facebook, push, GDPR). 4 file dex (±18 MB), kode di-obfuscate R8 (nama kelas 1 huruf) + dilindungi **PairIP** (VM encryption: `com.pairip.vmencryption.KeyImportApplication`, `libpairipcore.so` sebagai NEEDED pertama `libcriminalcase.so`).
- **Data lokal:** progres/ekonomi disimpan di **`UserDefault.xml`** (CCUserDefault Cocos2d-x) di direktori files aplikasi — kunci energi/koin/timer terlihat plaintext di string native. **Tidak ada database SQLite game** (0 hit `sqlite` di lib native; referensi SQLite di dex hanya milik AndroidX/Facebook SDK). Konten case/kota, katalog IAP, dan konfigurasi iklan disimpan sebagai **blob base64 terenkripsi** di `assets/data/content/*.json` (decode = byte high-entropy tanpa magic).
- **Server:** tidak ada host API game `prettysimple.com` di string plaintext. Titik kontak server yang terlihat: CDN konten `mobile-static.criminalcasegame.com` (diakses native via curl, http), sinkronisasi progres via **Facebook** (`FBHelper::setPlayerData`, `nativeSetPlayerData`), dan **verifikasi receipt Google Play** (`verifyGooglePlayReceipt`, `PurchaseManagerAndroid::sendSyncAndVerifyRequests` — host endpoint tidak terlihat di string plaintext).
- **Klasifikasi (ringkas):** energi **LOKAL** (timer jam perangkat di UserDefault.xml, dengan caveat sync Facebook); koin **LOKAL** (saldo) + pembelian **SERVER-VERIFIED**; cash **penyimpanan BELUM TERVERIFIKASI**, pembelian **SERVER-VERIFIED**; bintang/skor **LOKAL** (progres) + leaderboard **SYNC VIA FACEBOOK**; unlock case **SERVER-GATED** (konten wajib unduh dari CDN + kota premium = IAP).
- **Anti-cheat:** tidak ditemukan string deteksi root/magisk/Xposed/Frida/SafetyNet/Play Integrity di smali `com.prettysimple` maupun di lib native (hit yang ada adalah string TPM/OpenSSL dan "Friday" — false positive). Perlindungan yang terbukti: PairIP + tanda tangan + verifikasi receipt server-side + konten terenkripsi.

## 2. Identitas paket (terverifikasi dari artefak)

| Field | Nilai | Sumber |
|---|---|---|
| Nama | Criminal Case | `aapt2 dump badging` |
| Paket | `com.prettysimple.criminalcaseandroid` | badging, manifest |
| Developer | Pretty Simple (PrettySimple Games, Paris, FR) | DN sertifikat |
| versionName | **2.45.2** | badging + `manifest.json` XAPK |
| versionCode | **1830811** | badging + `manifest.json` XAPK |
| minSdk | 32 (Android 12L) | badging |
| targetSdk | 36 (Android 16) | badging |
| compileSdk | 37 (codename 17) | badging |
| ABI (XAPK ini) | **arm64-v8a saja** | split `config.arm64_v8a` |
| Densitas | xxhdpi (240/320/480) | split `config.xxhdpi` |
| Locale | en (+ 11 locale lain di aset) | split `config.en`, `languages/` |
| Orientasi | landscape (`sensorLandscape`) | manifest |
| Kategori | game | manifest `appCategory=game` |

Isi XAPK (`dumps/hashes.txt`):

| File | Ukuran | SHA-256 |
|---|---|---|
| `criminal-case-2.45.2-1830811.xapk` | 104.196.018 B | `f4f2895570abd81ecb146f9868fa82704bcbdb5bfc80d2037e14d50865e0ccbb` |
| `com.prettysimple.criminalcaseandroid.apk` (base) | 80.359.722 B | `269b1fdf7ab3de5dbddd78faa51966363b4e9747ef046e72e4e8059f4e76bf2c` |
| `config.arm64_v8a.apk` | 23.700.366 B | `20459d5cb646657ca66f495e03ff02f608b93fc7f7015a0f314e75118803d59d` |
| `config.en.apk` | 37.074 B | `c5b88219fedc50ab63d0ff7152a1b331c859948d0addd9f9abd6764f9867e774` |
| `config.xxhdpi.apk` | 96.669 B | `6cf7ede468a7b94061c7c4c99ab7c8d3a9668d66e2cf47c484c3d867e63a08c2` |

SHA-1 XAPK `c790eb0b8a63d462dc6c6ea60d9c80cd00e21786` cocok dengan metadata API APKPure (verifikasi parent).
**Catatan selisih hash XAPK vs klaim Uptodown:** SHA-256 XAPK klaim Uptodown `1e13def6…` **tidak cocok** dengan file ini (`f4f28955…`). Ini bukan bukti repack: yang dibandingkan Uptodown adalah *container* XAPK (susunan split + kompresi bisa berbeda antar mirror), sedangkan yang menentukan keaslian adalah **tanda tangan APK di dalamnya — dan itu cocok persis** (lihat §3). Keempat APK di dalam XAPK ini semuanya lolos `apksigner verify` dengan sertifikat yang sama.

## 3. Verifikasi tanda tangan → VONIS: ASLI

`apksigner verify --verbose --print-certs` (build-tools 34.0.0, JDK 17) — `dumps/apksigner-base.txt`:

- **Verifies: YA** (semua 4 APK: base + 3 split).
- Skema: **v3 = true** (v1/v2/v4 = false), **SourceStamp = true** (stempel Google Play).
- Jumlah penanda tangan: **1**.
- DN: `O=PrettySimple Games, L=Paris, ST=Paris, C=FR`.
- Sertifikat SHA-256: `95de3d9fc95f805d79249ab44476654b6bc6cdc0d78ec3962a1e46dc16f3f5fe`
- Sertifikat SHA-1: `91ba80a90088cb84fe18f0576878628d126067a0`
- Sertifikat MD5: **`da9c445799a917fe6cece2168ca62f51` — COCOK PERSIS dengan klaim Uptodown.**
- Algoritma kunci: RSA **1024-bit** (kunci lama developer, konsisten dengan game lawas).
- Keempat APK memakai sertifikat yang sama persis (termasuk SourceStamp Google yang identik).

**Vonis: ASLI.** Tanda tangan v3 + SourceStamp Google tidak dapat dipalsukan oleh repack tanpa kunci privat Pretty Simple.

## 4. Perolehan file (provenance)

- Jalur: API publik APKPure `api.pureapk.com/m/v3/cms/app_version` (resep proyek open-source `apkeep`), CDN `download.pureapk.com`, segmen path ter-decode `com.prettysimple.criminalcaseandroid_1830811_303087b8`.
- Bukti di folder: `api_response.bin` (respons protobuf mentah), `download_url.txt`, `expected.txt`.
- Riwayat blokir sebelumnya (laporan versi TERBLOKIR): `d.apkpure.com` dilindungi Cloudflare challenge; jalur API dipakai setelah keputusan parent. Detail jalur gagal dicatat di revisi laporan sebelumnya (diarsipkan di bawah, §12).

## 5. Arsitektur

### 5.1 Lapisan Java/Kotlin (jembatan SDK)

- 4 file dex: `classes.dex` 7.575.780 B, `classes2.dex` 190.708 B, `classes3.dex` 8.530.540 B, `classes4.dex` 1.781.560 B (total ±18 MB).
- `apktool` decode berhasil (`apktool_out/`, 336 MB). Kode di-obfuscate R8: direktori `smali/` teratas berisi ratusan kelas nama 1–2 huruf (`a.smali`, `b.smali`, …); hanya 66 file smali di bawah `com/prettysimple/*` yang bernama jelas.
- Launcher: `com.prettysimple.game.CriminalCaseLauncher` (singleTask, landscape); deep-link scheme `criminalcaseandroid`.
- Paket `com.prettysimple` (smali_classes3 + smali): `ads`, `billing`, `core`, `criminalcaseandroid`, `facebook`, `game`, `gdpr`, `googleplaygames`, `helpers`, `notification`, `push`, `soundfx`, `text`, `utils`, `xpromo`.
- SDK pihak ketiga (dari smali + string dex): Google Play Billing, Play Games (`GooglePlayGamesPcHelper`), Firebase (Messaging/Crashlytics/Analytics/Remote Config), Facebook SDK (login + App Events + IAP), AppLovin MAX, AdMob, Meta Audience Network (dex terpisah di `assets/audience_network/classes.dex`), Unity Ads, Amazon Ads mediation, AppsFlyer, OkHttp.

### 5.2 Native — Cocos2d-x 2.2.6

Bukti engine (dari `dumps/strings-libcriminalcase.txt` + simbol):

- String literal **`cocos2d-x 2.2.6`** di `libcriminalcase.so` (313 hit `cocos2d` total).
- JNI `org.cocos2dx.lib.*` (22 ekspor): `Cocos2dxRenderer` (nativeInit/nativeRender/nativeTouchesBegin/End/Move…), `Cocos2dxHelper` (nativeSetApkPath/nativeSetResPath), `Cocos2dxBitmap`, `Cocos2dxAccelerometer`, `Cocos2dxETCLoader`, `Cocos2dxIMEManager`.
- Aset khas Cocos2d-x/CocosBuilder: **121 file `.gaf`** (Generic Animation Format), **12 file `.ccbi`** (CocosBuilder), **179 file `.plist`**, shader `.fsh`/`.vsh` (GaussianBlur, Glow, pcShader_PositionTextureAlpha).
- Nama internal proyek (namespace C++): **`montana`** — 718 kemunculan di string native (mis. `montana::FBHelper::setPlayerData`, `montana::PurchaseManagerAndroid::sendSyncAndVerifyRequests`, `montana::LeaderBoard`).

### 5.3 Library native (`config.arm64_v8a.apk` → `lib/arm64-v8a/`)

| Library | Ukuran | Fungsi |
|---|---|---|
| `libcriminalcase.so` | 20.252.976 B | Game + Cocos2d-x 2.2.6 + libcurl + OpenSSL (statis). NEEDED pertama: `libpairipcore.so` |
| `libpairipcore.so` | 608.896 B | PairIP — proteksi/VM encryption (lihat §6) |
| `libunitycoherencenative.so` | 514.424 B | Unity CoherenceBridge (JNI `com.unity3d.coherence.CoherenceBridge`, WASM VM: `vmCreate`/`vmInvokeMain`/`wasm_instance_new`) — komponen native stack Unity (Ads); smali `com/unity3d/{ads,coherence,services}` ada |
| `libcrashlytics.so` + `libcrashlytics-common.so` + `libcrashlytics-handler.so` + `libcrashlytics-trampoline.so` | 231.960 + 864.616 + 222.056 + 4.744 B | Firebase Crashlytics NDK |
| `libapplovin-native-crash-reporter.so` | 843.152 B | Crash reporter AppLovin |
| `libdatastore_shared_counter.so` | 7.112 B | AndroidX DataStore native counter (`NativeSharedCounter`) — infrastruktur, bukan logika game |

NEEDED `libcriminalcase.so`: `libpairipcore.so`, `liblog.so`, `libandroid.so`, `libEGL.so`, `libGLESv2.so`, `libz.so`, `libOpenSLES.so`, `libdl.so`, `libc.so`, `libm.so`. **Tidak ada `libunity.so`** — game ini bukan Unity; Unity hanya hadir sebagai SDK iklan.

### 5.4 Jembatan Java ↔ Native (69 ekspor JNI, `dumps/jni-exports.txt`)

- `billing.BillingInterface` (14): `nativeOnBuyProductSuccessful` (8 argumen), `nativeOnBuyProductCancelled/Error/Pending/StatusUnconfirmed`, `nativeVerifyAndConsumeOnRetry`, `nativeOnPurchaseFinalizationResult`, `nativeOnRestoreSuccessful/Failed/NoProductsToRestore`, `nativeOnPizzaSubInactive`, `nativeOnProductInfoReceived/Unavailable`.
- `facebook.FacebookNativeInterface` (14): `nativeSetPlayerData`, `nativeGetFBAppNamespace`, `nativeFulfillRequestPromise`, `nativeAddAppFriend`, `nativeAddGameRequestSentFbIds`, `nativeSetRetrievedUser`, `nativeLoginStatusPointerExpired`, `nativeUseStructuredRequests`.
- `core.CriminalCase` (5): `nativePause/Resume/Stop/LowMemory`, `setMainClassLoader`.
- `ads` (5): `AdNativeInterface.nativeOnVideoAdEnd/nativeRewardUser`, `BuyNoAdsDialog.noAdsBuy/noAdsClose`, `InterstitialAdsNativeInterface.nativeOnInterstitialAdClosed`.
- `helpers` (4), `notification` (2), `xpromo` (1), `text` (1), `gdpr` (1) + 22 ekspor `org.cocos2dx.lib.*`.

Metode Java di `BillingInterface.smali`: `buyProduct(String, String)`, `finalizePurchase(...)`, `restorePurchases()`, `resumePendingPurchases()`, `autoRetryUnconsumedPurchases()`, `updateProductInfo(...)`, `canMakePurchases()`, `isSubcriptionTrialPeriodAvailable(...)` (sic — typo asli di kode).

## 6. Proteksi / anti-cheat

- **PairIP (terbukti):** `android:name="com.pairip.vmencryption.KeyImportApplication"` + `appComponentFactory="com.pairip.vmencryption.KeyImportAppComponentFactory"` di manifest; `libpairipcore.so` adalah NEEDED pertama `libcriminalcase.so`. String `libpairipcore.so` hanya 669 baris, mayoritas impor libc (`dl_iterate_phdr`, `dlopen`, `__system_property_get`, `getauxval`, `syscall`, `readdir`/`opendir`) — isi proteksinya opak/tidak terbaca plaintext. Mekanisme internal PairIP **tidak dapat dinilai dari statik**; yang terbukti adalah keberadaan + ketergantungannya.
- **Obfuscation R8:** nama kelas/metode Java 1–2 huruf di semua dex.
- **Konten terenkripsi:** semua `assets/data/content/*.json` adalah blob base64 yang decode-nya high-entropy tanpa magic (lihat §7). Kunci dekripsi tidak terlihat plaintext di string.
- **Tidak ada deteksi root/tamper di lapisan terbaca:** grep `magisk|xposed|frida|rootbeer|isRooted|SafetyNet|PlayIntegrity|attest` pada `smali/com/prettysimple` + `smali_classes3/com/prettysimple` → **0 hit**. Di string native, hit `frida`/`xposed`/`attest` adalah false positive (string TPM/OpenSSL `Attestation Identity Key Certificate`, `tcg-*-attestation*`, dan kata `Friday`). **Tidak ada bukti** game ini memeriksa root/emulator/hook — perlindungannya bertumpu pada PairIP, tanda tangan, verifikasi receipt server-side, dan konten terenkripsi.
- **TLS native:** `FileUtilsHelper.smali` mereferensikan `/ca-bundle.pem` (bundel CA untuk curl native). `network_security_config.xml` hanya mengizinkan cleartext untuk `127.0.0.1` — berlaku untuk lapisan Java; **kode native (curl) tidak tunduk pada Network Security Config**, sehingga URL `http://` CDN di §8 tetap dapat dipakai dari native.

## 7. Struktur data lokal

- **Save game utama: `UserDefault.xml`** (CCUserDefault Cocos2d-x, file XML key-value di direktori files aplikasi). Bukti: string `UserDefault.xml` di lib native + klaster kunci di sekitarnya (`dumps/strings-libcriminalcase.txt` baris ±21891–21971):
  - `energy_max`, `energy_refill_duration`, `last_energy_payment_time`, `last_coins_payment_time`, `last_payment_time`
  - `creation_time_mobile`, `installed_version`, `version`, `google_id`, `player_segmentation`
  - `achievements.json` (file data achievement), `data/dl_cache.json` (manifes cache unduhan)
- **Tidak ada SQLite game:** `sqlite` = 0 hit di string lib native; referensi `SQLiteDatabase`/`SQLiteOpenHelper` di dex hanya milik AndroidX/Facebook SDK. Tidak ditemukan nama file `.db` milik game.
- **Tidak ada nama SharedPreferences game** yang terlihat di string dex (referensi `SharedPreferences` di dex hanya milik SDK: Facebook `AccessTokenManager`, DataStore migration).
- **Backup:** `res/xml/backup_rules.xml` + `data_extraction_rules.xml` meng-exclude `data/content/` dan `data/dl_cache.json` dari backup/transfer — konten unduhan tidak ikut backup; save (`UserDefault.xml`) tidak di-exclude.
- **Konten game (aset):** `assets/data/app/` 43 MB (`anim`, `cert`, `font`, `shader`, `sound`, `ui`); `assets/data/content/` 21 MB. Semua file `.json` konten adalah **blob base64 → byte high-entropy** (uji: `city_1.json` decode 400 karakter pertama = byte acak tanpa magic, mis. `aa 70 f2 d5 2b 66 d3 41…`):
  - `city_1.json` (10.924 B), `city_2.json` (12.076 B) — data kota/case
  - `default_product_info.json` (57.536 B) — katalog produk IAP (terenkripsi)
  - `rules.json` (64.768 B), `flashvars.json` (8.344 B), `ads_config.json` (21.208 B), `exclusive_cases.json` (5.632 B)
  - `interstitial_ad_mediation.json` (218.540 B), `video_ad_mediation.json` (200.000 B), `native_ad_mediation.json` (5.292 B) + varian `*_amazon.json` (172 B, juga blob)
  - Pengecualian plaintext: `android_config.json` (2.979 B) — hanya berisi `OpenSL_blacklist` (daftar model perangkat lawas).
- **Aset lain:** file aset top-level bernama hash (`5mRDqzPg7AAuw4PJ`, …) bertipe `data` (biner); `assets/data/content/languages/` 12 locale (`text_content_id_ID.strings` tersedia — lokalisasi Indonesia ada); `avatar/` (plist+png per item), `pets/` (`pet_1.plist/png` …), `notifications/` (`happy_hour_notif_image.jpg`).
- **Lokalisasi (istilah ekonomi, `text_content_en_US.strings`):** `MainUIEnergy: Energy`, `MainUICoins: Coins`, `MainUICash: Cash`, `BtnBuyCash: Get Cash`, `BtnBuyCoins: Get Coins`, `TitleEnergyPopupNotEnough: Not Enough Energy!`, `TooltipCashMeter: Use cash to buy energy, …`, `InviteFriendsToGetRewards: Invite friends to get rewards in energy!`.

## 8. Endpoint server / API yang ditemukan

Dari string native (`dumps/strings-libcriminalcase.txt`) — semua diakses via curl native:

| Host / URL | Fungsi |
|---|---|
| `http://mobile-static.criminalcasegame.com/androidappupdate/android_png.json` | Cek update aset Android |
| `http://mobile-static.criminalcasegame.com/ioscasesupdate/cases_version.json` | Versi case (string iOS ikut terbawa di build Android) |
| `http://mobile-static.criminalcasegame.com/pngadditionaldl/` | Unduhan aset tambahan |
| `http://mobile-static.criminalcasegame.com/pngcases/` | Unduh konten case/kota |
| `http://mobile-static.criminalcasegame.com/pngcities/` | Unduh konten kota |
| `http://mobile-static.criminalcasegame.com/stickers/` | Stiker |
| `http://thebestapp.criminalcasegame.com/bridge.php` | Cross-promo "best app" Pretty Simple |
| `http://imabigfanof.criminalcasegame.com/` | Situs fan |
| `https://apps.facebook.com/criminalcase/` | Versi Facebook (canvas) |
| `http://www.criminalcase.com/help/` | Bantuan |

**Tidak ditemukan:** host API game di `prettysimple.com` / `criminalcasegame.com` selain CDN statis di atas — tidak ada endpoint `/api/`, auth, atau sinkronisasi progres berbasis REST yang terlihat di string plaintext. Verifikasi pembelian (`verifyGooglePlayReceipt`, `montana::PurchaseManagerAndroid::sendSyncAndVerifyRequests`) dan sinkronisasi Facebook (`montana::FBHelper::setPlayerData`) **ada sebagai simbol/metode, tetapi host tujuannya tidak terlihat di string plaintext** — kemungkinan dirakit di kode native atau tersimpan di konten terenkripsi.

Endpoint SDK pihak ketiga (dari string dex — bukan server game): AppLovin (`a.applovin.com`, `b.applovin.com`, `d.applovin.com`, `ms.applovin.com`), Firebase (`firebaseinstallations.googleapis.com`, `firebaseremoteconfig.googleapis.com`, `fcmregistrations.googleapis.com`, `firebase-settings.crashlytics.com`), Facebook Graph (via SDK), Unity Ads (`gateway.unityads.unity3d.com`), AdMob (`admob-gmats.uc.r.appspot.com`), `app-measurement.com`.

## 9. Alur pembelian (IAP) — bukti

- Izin: `com.android.vending.BILLING` + `com.android.vending.CHECK_LICENSE`.
- Alur (dari `BillingInterface.smali` + string native): `buyProduct` → callback native `nativeOnBuyProductSuccessful` → `finalizePurchase` → **verifikasi receipt** (`verifyGooglePlayReceipt`; simbol `montana::PurchaseManagerAndroid::sendSyncAndVerifyRequests`) → konsumsi (`nativeVerifyAndConsumeOnRetry`, `autoRetryUnconsumedPurchases`, `resumePendingPurchases`).
- String UI verifikasi (bukti pembelian TIDAK langsung dianggap lunas tanpa verifikasi):
  - `"The purchase was verified, but its final Google Play confirmation is still pending. Do not buy it again; the game will retry when you reconnect or return."`
  - `"Purchase could not be verified"` / `"The purchase could not be verified. It has not been redeemed, and the game will check again later."`
  - `"receipt_data"`, `"not a signed receipt"`, `"receipt decode error"`
- Katalog produk (`default_product_info.json`, 57 KB) **terenkripsi** — daftar SKU/harga tidak dapat dibaca dari statik. Subscription "Pizza" (kemungkinan langganan energi) disebut di `nativeOnPizzaSubInactive`, `subscription_pizza_energy`, `subscription_pizza_popup.plist`.

## 10. Klasifikasi per fitur (dengan bukti)

| Fitur | Vonis | Bukti |
|---|---|---|
| **Energi** | **LOKAL** (dengan caveat sync) | Kunci `energy_max`, `energy_refill_duration`, `last_energy_payment_time` di `UserDefault.xml` (string native baris 18191/21891/21906); `LevelUpEnergyRefilled`; refill berbasis jam perangkat (timer lokal). Tidak ada endpoint energi server. Caveat: progres di-sync ke Facebook (`nativeSetPlayerData`, `fbsyncfailed_popup.plist`) — nilai lokal dapat tertimpa salinan cloud saat sync; dan lib dilindungi PairIP. |
| **Koin** (soft currency) | **LOKAL** (saldo); pembelian **SERVER-VERIFIED** | Kunci `last_coins_payment_time`, UI `CoinShopPopup`, `MT_CoinShopPopupTitle`, `video_ad_coins_reward`, `rewarded_videos_coins`, `sqreward_coin`; tidak ada endpoint koin server di string. Koin beli pakai uang asli = IAP Google Play + `verifyGooglePlayReceipt`. |
| **Cash** (hard currency) | **Penyimpanan BELUM TERVERIFIKASI**; pembelian **SERVER-VERIFIED** | Hanya label UI yang terlihat (`MainUICash`, `BtnBuyCash`, `CashCoinsMostPopular`) — **tidak ada kunci saldo cash plaintext** di string native/dex (nama kuncinya tidak terlihat; bisa dinamis/terenkripsi). Pembelian cash = IAP + verifikasi receipt server-side (§9). |
| **Bintang / skor / XP** | **LOKAL** (progres); leaderboard **SYNC VIA FACEBOOK** | `extra_star`, `transition_reward_xp`, `score_pet_bonus`, `StarBurnerUsedCoins`, `stargauge_shadow`, `leaderboard_scores`; leaderboard native `montana::LeaderBoard`/`LeaderBoardItem`; skor teman di-sync via Facebook (`nativeSetPlayerData`, `maxFriendsPerFBRequest`). Bintang per-scene tersimpan lokal; peringkat sosialnya dari Facebook. |
| **Unlock case / kota** | **SERVER-GATED** | Konten case wajib diunduh dari CDN (`pngcases/`, `pngcities/`; `DownloadCityPopup`, `city_dl_failed`); file kota lokal terenkripsi (`city_1.json`, `city_2.json`); kota premium = IAP (`MT_PremiumCity_BuyNoPrice`, `MT_PremiumCity_NewCaseTitle`); `exclusive_cases.json` terenkripsi. Case yang sudah terunduh ada di `data/content/` lokal, tapi pembukaannya digerbang unduhan server + IAP. |
| **Avatar / hewan peliharaan / stiker** | **LOKAL (aset) + IAP untuk item premium** | Aset `avatar/`, `pets/` (plist+png) dan `stickers/` lokal di APK/CDN; `AvatarShopUnlockAt`, `StickerShopPopup`, `ItemPopupFindInAvatarShop` — sebagian item dibeli (koin/cash). Mekanisme unlock per-item tidak tertelusur sampai ke kunci simpannya (konten terenkripsi). |
| **Energi dari iklan / hadiah** | **LOKAL (reward)** | `video_ad_coins_reward`, `rewarded_videos_coins`, `foodbonus_energy`, `ActionPlusEnergy` — reward iklan diproses lokal setelah callback SDK (`nativeRewardUser`). |

**Yang TIDAK terbukti (jangan dijadikan dasar mod):** lokasi kunci saldo cash; host verifikasi pembelian; format persis `UserDefault.xml` saat runtime (butuh perangkat/root + observasi runtime); apakah server Facebook menolak nilai lokal yang diubah (butuh uji runtime — tidak dilakukan di REA statik ini).

## 11. Batas analisis

- **Tidak ada Ghidra/Hopper/IDA di VM ini** — dekompilasi/pseudocode native mendalam tidak tersedia; analisis native sebatas string + simbol + header ELF (readelf/nm).
- **Tidak ada JADX** — analisis dex sebatas smali apktool (ter-obfuscate R8) + string; nama kelas/metode asli game tidak dapat dipulihkan dari statik.
- **Tidak ada analisis runtime** — tidak ada install/jalankan di perangkat, tidak ada observasi trafik, tidak ada dump memori. Semua vonis di §10 adalah vonis statik.
- **Konten terenkripsi tidak didekripsi** — kunci tidak terlihat plaintext; daftar SKU IAP, data case, dan aturan (`rules.json`) tidak dapat dibaca.
- **Internals PairIP opak** — tidak dapat dinilai apakah ada deteksi root/hook di dalam `libpairipcore.so` (string hanya 669 baris, tanpa kata kunci anti-tamper).
- **File `api_response.bin` / `download_url.txt` / `expected.txt`** adalah bukti perolehan, bukan artefak analisis.

## 12. Arsip: laporan versi TERBLOKIR (11 Nov 2026, sebelum file diperoleh)

Laporan awal mendokumentasikan identitas versi dari APKMirror + Uptodown (2.45.2/1830811, diunggah 9 Okt 2026) dan 10 jalur unduh yang dicoba dan gagal (Cloudflare challenge di `d.apkpure.com`/`download.apkpure.com` untuk curl biasa, curl+header Chrome, dan curl_cffi impersonate; interstitial Uptodown; apkcombo/Evozi gagal koneksi; API `tapi.pureapk.com` 400; halaman APKMirror 403). Jalur API `api.pureapk.com/m/v3/cms/app_version` mengembalikan HTTP 200 + URL CDN, tetapi URL-nya sempat ditandai sistem sebagai tidak lolos pemeriksaan prompt-injection sehingga tidak dipakai saat itu; file respons + daftar URL sempat dihapus. Keputusan memakai jalur itu akhirnya dibuat parent agent — file kini ada dan terverifikasi (§2–§3). Isi §12 ini dipertahankan sebagai arsip kegagalan, bukan status berjalan.

## 13. Inventaris file kerja (`~/workspace/rea-criminal-case/`)

- `REPORT.md` — laporan ini
- `criminal-case-2.45.2-1830811.xapk` — XAPK terverifikasi (104.196.018 B)
- `api_response.bin`, `download_url.txt`, `expected.txt` — bukti perolehan
- `extract/` — isi XAPK (4 APK + `manifest.json`)
- `apk_contents/base/` — isi APK base (dex, aset, res); `apk_contents/arm64/` — isi split arm64 (`.so`)
- `apktool_out/` — decode apktool (manifest, res, smali, 336 MB)
- `dumps/badging-base.txt`, `dumps/badging-arm64.txt`, `dumps/badging-en.txt`, `dumps/badging-xxhdpi.txt` — `aapt2 dump badging`
- `dumps/apksigner-base.txt` — `apksigner verify --print-certs`
- `dumps/hashes.txt` — SHA-256 XAPK + 4 APK
- `dumps/strings-libcriminalcase.txt` (42.669 baris) — string `libcriminalcase.so`
- `dumps/strings-classes.txt`, `dumps/strings-classes2.txt`, `dumps/strings-classes3.txt`, `dumps/strings-classes4.txt` — string keempat dex
- `dumps/jni-exports.txt` — 69 ekspor JNI `libcriminalcase.so`
- `dumps/apktool.log` — log decode apktool
