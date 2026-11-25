# FINDINGS-dex.md — Lapisan Java/DEX Cinta di Citampi 1.87.5

## Identitas
- Package: `com.ikanasinproduction.cintadicitampi`
- Version: **1.87.5**, versionCode **667**, minSdk 29, targetSdk 36,
  compileSdk 36 (Android 16), label "Citampi Stories"
- XAPK APKPure: base APK 236.013.570 B + config `arm64_v8a` 39.676.012 B
- Signer: APK Signature Scheme **v3**, 1 signer, DN `O=Ikan Asin Production`,
  RSA 2048, cert SHA-256 `b3cf2753…` (lengkap: `dump/signer.txt`)

## DEX
12 file dex, total **89.447 class, 580.099 method, 311.472 field,
573.928 string** (rincian per dex: `dump/dex.txt`; daftar class:
`dump/classes.txt`).

| dex | class | method |
|---|---|---|
| classes.dex | 8.387 | 54.490 |
| classes2.dex | 190 | 2.102 |
| classes3.dex | 6.021 | 57.599 |
| classes4.dex | 1.806 | 9.095 |
| classes5.dex | 8.071 | 55.747 |
| classes6.dex | 7.347 | 56.301 |
| classes7.dex | 7.846 | 57.958 |
| classes8.dex | 11.139 | 57.227 |
| classes9.dex | 8.325 | 55.958 |
| classes10.dex | 8.603 | 57.988 |
| classes11.dex | 10.721 | 56.965 |
| classes12.dex | 10.991 | 58.669 |

## Manifest (`dump/manifest.txt`, `dump/badging.txt`)
Permission penting: `INTERNET`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`,
`POST_NOTIFICATIONS`, `VIBRATE`, `ACCESS_WIFI_STATE`,
`READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`,
`com.android.vending.BILLING`, `com.android.vending.CHECK_LICENSE`,
`com.google.android.gms.permission.AD_ID`, `BIND_GET_INSTALL_REFERRER_SERVICE`,
`RECEIVE` (C2DM/FCM), `FOREGROUND_SERVICE`, AdServices (attribution/ad-id/
custom-audience/topics).

Manifest juga mendeklarasikan banyak `queries/provider` Noctua
(`*.noctuaaccountprovider`) lintas game Noctua — akun Noctua dipakai bersama
antar game publisher yang sama.

## SDK / library pihak ketiga (dari classes + manifest)
- **Google Play Billing** — `com.android.billingclient` (274 class) +
  permission `BILLING` + `CHECK_LICENSE`.
- **Unity Purchasing** — `Purchaser`, `IAPLibrary`, `NoctuaIAPProcessor`
  (lihat bagian IAP).
- **Firebase C++** — App 13.9.0, Analytics, Crashlytics, Messaging,
  RemoteConfig (+ `libcrashlytics*` native).
- **AppLovin MAX** — mediasi iklan (+ `libapplovin-native-crash-reporter.so`).
- **Adjust** — atribusi (`app.adjust.com/1ov3t8e0`, `libsigner.so` =
  `Java_com_adjust_sdk_sig_NativeLibHelper_nSign`).
- **Noctua SDK** — akun + IAP + liveops (`sdk-api-v2.noctuaprojects.com`,
  `sandbox-sdk-api-v2.noctuaprojects.com`, `geoip.noctuaprojects.com`,
  `liveops-progress-tracker.noctuaprojects.com`, `sdk-tracker.noctuaprojects.com`).
- **Pangle / ByteDance PGL** — `libpglarmor.so` (`PglCryptUtils`), `libbuffer_pgl.so`,
  `libfile_lock_pgl.so`.
- **Mintegral** — `com.mbridge.msdk.*` (FastKV dll.).
- **Unity Ads / Unity Services** — `com.unity3d.services.*`, `com.unity3d.ads.*`.

## IAP (In-App Purchase)
- Jalur: Google Play Billing via Unity Purchasing + Noctua.
- `IAPLibrary` (static, TypeDefIndex 590): ~60 field product-ID string
  (`adFreeIAP`, `jetpackIAP`, `jualPraktisIAP`, `onlineSaveIAP`,
  `kostumRobotIAP`, `kostumPocongIAP`, `kostumAnjingIAP`, `bundle1IAP`…`bundle3IAP`,
  `limitedStarterBundle(02)`, `coupon1IAP`, `coupon2IAP`, `coupon3IAP`,
  `coupon5IAP(_IOS)`, `ojegIAP(_IOS)`, `motorIAP(_IOS)`, `AutoSaveIAP`,
  `BajuPinkIAP`, `BajuYomartIAP`, `BajuAlfamartIAP`, `AccessAlfamartToken`,
  `cupboardInstantIAP`, `AnakYatimIAP(_IOS)`, `InteractiveDateIAP(_IOS)`,
  `DSN_inside_*IAP` per toko/area, `DSN_area01..06IAP`, …) + method
  `IsConsumableProductId`, `ResolveUnityProductType`,
  `IsRedeemEventCostumeProductId`, `GetRedeemProductIdsGrantingCostume`,
  `GetPaidProductIdsGrantingCostume`, `RedeemProductGrantsAlfamartPet`,
  `IsAnakYatimProductId`.
- `Purchaser` (TypeDefIndex 616+): `IAPProduct`, `purchaseHistory`.
- `NoctuaIAPProcessor` (TypeDefIndex 615): pemrosesan IAP via Noctua.
- **67 product ID** terdaftar di `stringliteral.json`, semua pola
  `com.ikanasinproduction.cintadicitampi.*` (contoh: `.autosave`, `.bajupink`,
  `.bajualfa`, `.bajuyomart`, `.belimotor`, `.bundle1/2/3`, `.coupon1/2/3/5`,
  `.cupboardinstant`, `.doaanakyatim(2)`, `.interactivedate(2)`, `.jetpack`,
  `.jualpraktis`, `.kostumanjing`, `.kostumpocong`, `.kostumrobot`,
  `.limitedstarterbundle(two)`, `.motor`, `.ojeg*` per area/toko, …).
- Save offline menyimpan status IAP per produk (`ADSIAP`, `WIAP_20..22`,
  `GOJIAP`, `GOArea*IAP`, `GO*IAP` per toko) — lihat FINDINGS-save.md.
  **IAP adalah pembelian server-side (Google Play + Noctua); mengedit flag
  IAP di save lokal tidak sama dengan membeli, dan server dapat memvalidasi
  (`/download_purchase`, `/update_newpurchase`, `/validate_newlootboy`,
  `checkTampering` — save yang di-tamper tidak di-merge nilai CG/IAP-nya).**

## Kelas game penting (IL2CPP, dari `dump.cs`)
- `saveHelper` (static, TypeDefIndex 579) — load/save offline + online,
  anti-tamper, UniPin.
- `Ikaan.Utility.IkaanDataFormat` (TypeDefIndex 1285) — enkripsi save.
- `saveObject` (TypeDefIndex 376) — `{key, value}`.
- `CurrencyChangeDetector` (TypeDefIndex 836) — memantau perubahan mata uang.
- `FirstLaunchDetector` (837), `DeepLinkManager` (380), `vehicle` (377),
  `wifeCostume` (378), `PurchasePage` (12), `PurchaseRowPrefab` (3),
  `FBWindowsPurchaseManager` (36).
- CodeStage Anti-Cheat Toolkit (ACTk) hadir sebagai library di binary —
  lihat FINDINGS-native.md.
