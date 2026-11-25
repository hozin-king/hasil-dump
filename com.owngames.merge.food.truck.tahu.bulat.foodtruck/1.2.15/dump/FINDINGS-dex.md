# FINDINGS — DEX (Food Truck City 1.2.15 / code 35)

Sumber: `classes.dex` tunggal, 7.461.256 byte, 11.080 class, 55.460 method, 31.147 field.
Analisis statis via androguard 4.1.4. Detail mentah: `dump-dex.txt`, `classes.txt`.

## 1. Struktur dex

- Single dex (bukan multidex). Package dominan: `com.google` 6.758 class (mayoritas SDK:
  Firebase, AdMob, Play Games, Play Billing), `com.facebook` 566 class,
  `com.owngames` 144 class (game + OwnConnect SDK).
- Main activity: `com.owngames.merge.MainActivity`.
- Activities lain: OwnConnect SDK (Login/Register/Password/Contact/Report/
  UploadAttachment), Facebook, AdMob, Play Games.
- Services: Firebase, AdMob, WorkManager, AppMeasurement.
- Providers: FirebaseInitProvider, FileProvider, Facebook, PlayGames,
  MobileAdsInitProvider. Library `org.apache.http.legacy`.

## 2. OwnSaveData ada di Java — tapi tidak dipakai dari Java

- Class `Lcom/owngames/ownengine/io/OwnSaveData;` ADA di dex
  (`doLoad`/`doSave`/`loadData`).
- `JavaHelper`: **0 hit** — tidak ada tabel key Java seperti Tahu Bulat 15.21.0.
- String `Datadata` / `datadata` / `owndata` / `.own` / `saveDataName` /
  `encryptCode`: **0 hit** di dex.
- Caller scan seluruh dex: **0 method Java yang memanggil
  OwnSaveData/doSave/doLoad** — jalur save sepenuhnya native
  (lihat `FINDINGS-native.md` dan `FINDINGS-save.md`).

## 3. URL menarik di dex

- `https://ownconnect.tahoogle.com/Forum/OCSDK2/` — backend forum OwnConnect.
- Endpoint standar Google / Facebook / AdMob / Firebase.
- Tidak ada Supabase, tidak ada endpoint API game sendiri yang terlihat.

## 4. Billing / IAP

- Google Play Billing Client (SkuDetails / ProductDetails, `ProxyBillingActivity`,
  `ProxyBillingActivityV2`).
- String `Error acknowledge purchase!` ada.
- **Tidak ada product ID / SKU literal di dex** — katalog IAP kemungkinan
  diambil dari Play Console / konfigurasi server. Tidak ada analisis bypass.

## 5. Crypto (dex)

- 303 hit generik — mayoritas dari library Google (Tink / AES).
- Tidak ada implementasi cipher save di Java; cipher save ada di native
  (DES/ECB, lihat `FINDINGS-save.md`).

## 6. Root / debug / anti-cheat (dex)

- 121 hit `[root/debug]` — semuanya generik; `AndroidRootResolver` adalah
  nama class Play Games, **bukan** deteksi root.
- Tidak ada bukti deteksi root / emulator / Play Integrity di dex.
- Tidak ada anti-cheat native yang teridentifikasi (lihat juga
  `FINDINGS-native.md`).
