# REA — Hotel Story (Hotel Story 2) v3.0.3

Reverse-engineering analysis (statis + emulasi string). Analisis saja — **tidak ada mod yang dibangun**.
Tanggal: 7 Nov 2026. File sumber: `Hotel_Story_3.0.3_4_2fb5.apks` (15.385.075 byte).

## Ringkasan eksekutif

| Item | Hasil |
|---|---|
| Package | `com.happylabs.hotelstory2` |
| Versi | 3.0.3 (versionCode 5), minSdk 26, targetSdk 36 |
| Asli / repack | **Kemungkinan besar ASLI (Play-distributed)** — lihat §2 |
| Engine | **C++ native custom** (OpenGL ES 2.0 + JNI), bukan Unity |
| Online / offline | **Hybrid online-first** — simulasi lokal, akun + ekonomi di-sync ke server |
| Mata uang | Coins (soft) + Diamonds (hard/IAP) |
| Proteksi | PairIP (license check Play saat startup) + flag anti-fraud native |

## 1. Struktur paket

- `Hotel_Story_3.0.3_4_2fb5.apks` = ZIP berisi 2 APK (bundletool-style):
  - `base.apk` — 20.304.553 B, 561 file, 3 DEX (`classes.dex` 8.638.472 B,
    `classes2.dex`, `classes3.dex`), total 7.063 file smali.
  - `split_config.arm64_v8a.apk` — 3.125.673 B, berisi satu-satunya native lib:
    `lib/arm64-v8a/libnative-lib.so` (3.091.680 B).
- Tidak ada `.so` di `base.apk`; tidak ada split DPI/bahasa lain.
- `assets/`: `m10.bin` (14.740 B) dan `tcid.bin` (5.660 B) — keduanya
  high-entropy (header `01 00 00 00` lalu byte acak) = tabel/data game
  yang di-obfuscate; `lang/*.bin` (9 bahasa, termasuk `indonesian`? —
  file `lang/` berisi english/germany/japanese/korean/portuguese/russian/
  simplified/spanish/traditional; bahasa UI dipilih runtime,
  `GameSystem.smali` mengenal kode `id`, `en`, `ja`, `ko`, `zh`, dst);
  `shaders/UI2DShader.{vsh,fsh}`; font `BPreplayBold.otf`.

## 2. Tanda tangan — asli atau repack?

**Verdict: hampir pasti APK resmi dari Play Store (bukan repack).**

Bukti (`apksigner verify --verbose --print-certs`, build-tools 34.0.0):

- `base.apk`: v2 = true, v3 = true, v1 = false, SourceStamp = true,
  1 signer.
- `split_config.arm64_v8a.apk`: v1/v2/v3 = true, signer **identik** dengan base.
- Signer cert DN: `CN=Android, OU=Android, O=Google Inc., L=Mountain View,
  ST=California, C=US` — pola sertifikat **Google Play App Signing**.
  SHA-256 cert: `78d33f6f68c166ecc1b0c6ab0e81968e91707e70bd9774c5b4d1151924a59dbc`.
- Manifest (`decoded/AndroidManifest.xml`) membawa stamp Play:
  `com.android.stamp.source = https://play.google.com/store`,
  `com.android.stamp.type = STAMP_TYPE_DISTRIBUTION_APK`,
  `com.android.vending.derived.apk.id = 3`.
- Tidak ada tanda tampering: `android:debuggable` tidak ada,
  `allowBackup="true"` (default-ish, dengan `CustomBackupAgent`),
  PairIP license check utuh (lihat §5), tidak ada file asing di dalam APK.

Batas verifikasi: DN sertifikat Play App Signing bersifat generik (Google),
jadi identitas developer tidak bisa dikonfirmasi dari cert saja tanpa
membandingkan listing Play Store. Tapi semua indikator konsisten dengan
unduhan Play yang belum disentuh.

## 3. Manifest & komponen

`decoded/AndroidManifest.xml` (package `com.happylabs.hotelstory2`):

- Permissions: `INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`,
  `com.android.vending.BILLING`, `com.android.vending.CHECK_LICENSE`.
- Application: `android:name="com.pairip.application.Application"`,
  `extractNativeLibs="false"`, orientasi `userLandscape`,
  `backupAgent="com.happylabs.common.backup.CustomBackupAgent"`,
  `appCategory="game"`.
- Activity utama: `com.happylabs.hotelstory2.MainActivity`
  (exported, `sensorLandscape`, fullscreen).
- Deep link: `RedirectActivity` (exported) — scheme `https`,
  host `api-hs.hotel-story.com`, path `/v1/action`; dan scheme
  `com.happylabs.hotelstory` host `action`.
- `com.android.billingclient.api.ProxyBillingActivity` (+V2) —
  Google Play Billing Client **8.0.0** (meta-data
  `com.google.android.play.billingclient.version = 8.0.0`).
- `com.pairip.licensecheck.LicenseActivity` (exported=false).
- Service: `com.amazonaws.mobileconnectors.s3.transferutility.TransferService`.
- Google Play Games scopes di smali (auth/games, games_lite, userinfo).

## 4. Engine & arsitektur kode

**Engine: C++ native custom, bukan Unity.**

Bukti:

- `lib/arm64-v8a/libnative-lib.so`: ELF 64-bit ARM, stripped (tapi simbol
  C++/JNI masih terbaca), BuildID `b92976a6…`, NEEDED hanya
  `liblog, libGLESv2, libz, libm, libdl, libc` — tanpa `libil2cpp.so`,
  tanpa `libunity.so`, tanpa `libmono`.
- JNI bridge (`strings` di `libnative-lib.so`):
  `Java_com_happylabs_common_util_Native_{InitializeJNI,RenderJNI,
  OnTouchActionJNI,OnPauseJNI,OnResumeJNI,OnGLLostContextJNI,…}`,
  `Java_com_happylabs_common_aws_AmazonManager_On{CallLambdaFunctionReply,
  DownloadFileReply,UploadFileReply}Native`,
  `Java_com_happylabs_common_iap_IapManager_On{PurchasedProduct,
  QueryProductsReply,TryPurchaseCallback}Native`,
  `Java_com_happylabs_common_util_HttpManager_SimpleHttpPostCallbackNative`,
  `Java_com_happylabs_common_util_Native_{GenerateBackupAccountData,
  GetAdmobAppID,IsDebug}`.
- Logika game sepenuhnya native: simbol C++ seperti
  `_ZN10CNPCObject15TryToEnterHotelEv`,
  `_ZN17CMapObjectManager10AdjustZoomEf`,
  `_ZN11CPlayerData8SaveGameEPhj`, `_ZN11CGameServer16TryFetchRankingsEa`.
- Java/smali hanya lapisan tipis: `com/happylabs/common/{aws/AmazonManager,
  iap/IapManager, util/{GameSystem,HttpManager,Native}, render/MainGLRenderer,
  sound/SoundManager, resource/ResourceManager}` — 7.063 file smali itu
  mayoritas SDK (AWS SDK, AndroidX, Play services, Jackson, Firebase
  encoders) + PairIP (30 file di `smali_classes2/com/pairip/`).
- Tidak ada Ghidra/IDA/Hopper di VM ini — analisis native terbatas pada
  `strings` + simbol; tidak ada dekompilasi fungsi native.

## 5. Proteksi: PairIP + license check

- `Application.smali` (`smali_classes2/com/pairip/application/`) memanggil
  `LicenseClient.checkLicense(Context)` saat startup.
- `LicenseActivity.smali` menampilkan error/dialog bila license gagal
  ("Check that Google Play is enabled…", "Paywall intent is not provided.",
  "Couldn't process license activity correctly.").
- Native: `Java_com_happylabs_common_util_Native_IsDebug` ada (pemeriksaan
  debug), plus string `happylabs_appl_check` / `happylabs_appl_verify`
  di `.so`.
- Artinya: salinan yang di-repack/dimodifikasi harus melewati license check
  ini — proteksi masih utuh di file yang dianalisis.

## 6. Server & endpoint

- Host game: `api-hs.hotel-story.com` (deep link `/v1/action`, manifest).
- Backend AWS: `AmazonManager` (Lambda invoke, S3 upload/download,
  Cognito identity, region `us-east-1`, bucket S3 `s3-us-west-1`),
  `HttpManager` (POST generik, log `[doSimpleHttpPost] url:`),
  `LambdaInvoker`/`LambdaParam` di smali.
- Tidak ada hostname game-server plaintext di `.so` (kemungkinan dirakit
  runtime / di-obfuscate); endpoint yang terlihat di smali hanya endpoint
  generik AWS/Google (`acs.amazonaws.com`, `s3.amazonaws.com`,
  `googleapis.com/auth/games`, dsb).
- Satu nilai konfigurasi AWS ditemukan di `AmazonManager.smali` dan
  **sengaja tidak dikutip di laporan ini** (nilai sensitif — dikecualikan).

### `CGameServer` — lapisan online (simbol di `libnative-lib.so`)

Semua balasan berbasis JSON (`Json::Value`):

| Fungsi | Arti |
|---|---|
| `TryGenerateNewGameID` / `OnNewGameIDReply` | ID game baru dari server |
| `TryUpdateSelfOnServer` / `OnUpdateSelfReply` | upload state pemain ke server |
| `OnFileUploadReply` / `OnFileDownloadReply` | upload/download file save |
| `TryFetchRankings` / `OnFetchRankingReply` | leaderboard |
| `TrySearchUserByID/ByName`, `TryFollowUser`, `TryUnFollowUser`, `TryFetchFollowList` | sosial (cari & follow pemain lain) |
| `TryGiveTip` / `TryFetchTips` | kirim/terima tip antar pemain |
| `TryWriteShopSale` / `TryFetchShopSaleRequests` / `TryUpdateShopSaleResult` | jual-beli antar pemain (shop sale) |
| `TryFetchSelfPlayTime` | waktu main dari server |

## 7. Akun & penyimpanan

- Akun server-backed, tapi login tidak wajib di awal (guest flow lewat
  `TryGenerateNewGameID`):
  - `CAccountData`: `NewAccount`, `GetUserID/SetUserID`, `GetSaveData`,
    `SaveGame/LoadGame`, `TryBackupData`, `GetEmailAddress`,
    `SetEmailVerified/SetEmailPendingVerification`,
    `SetSecuredWithFacebook`, `CanSecureAccount/IsAccountSecured`,
    `IsBanned/SetBannedStatus`, `GetSecondsSinceGameSaved`,
    `SetSecondsSinceGameSavedOnServer`.
  - `CAccountManager::OnReceiveHTTPResponseRescueLogin{,Confirm}` —
    pemulihan akun via HTTP.
- Save lokal = blob biner: `CPlayerData::SaveGame(uint8_t*, uint32_t)` /
  `LoadGame(const uint8_t*)`; semua objek game punya
  `GetSaveDataSize/SaveData/LoadData` (`CBasicRoom`, `CMapObject`,
  `CNPCObject`, `CReception`, `CDecoObject`, `CGameStudio`, `CTempleGate`,
  `CTourAgency`, …). Save ini yang di-upload ke server
  (`CGameServer::OnFileUploadReply`).
- **Anti-tamper / anti-fraud (bukti langsung):**
  - `_ZN11CPlayerData12IsFraudulentEv` — flag fraud pada data pemain.
  - `_ZNK19CBaseBuildingObject17IsEarningsCheatedEv` — deteksi
    kecurangan pendapatan bangunan.
  - `CIAPManager::TryVerifyReceipt` / `OnVerifyReceiptReply` —
    **verifikasi struk IAP di sisi server**.

## 8. Ekonomi: coins & diamonds

- Dua mata uang (string literal `coin`, `diamond` di `.so`):
  - **Coins** (soft): `CPlayerData::AdjCoin/GetCoins`,
    `CNPCObject::DeductCoins`, `PerformEarnMoney`, `SetCmdEarnMoney`,
    `CPlayerData::AdjDonatedCoinNum`, `CRewardsData::{Auto,Upgraded}
    CoinCollectionQuest`, `CCameraWindow::GetCameraRewardCoinNum`,
    `CShopWindow::PerformPurchaseCoins`, `CItemManager::GetShopCoinCost`.
  - **Diamonds** (hard/premium): `CPlayerData::AdjDiamond/GetDiamonds`,
    `LoadDiamondAndCoin`, `CIAPManager::GetDiamond`,
    `CShopWindow::CalculateDiamondNeeded/PerformPurchaseDiamonds`,
    `CItemManager::GetShopDiamondCost`, `CRewardsData::GetDiamondRewardNum`.
- Saldo disimpan di `CPlayerData` (in-memory native) → persist ke blob save
  lokal → di-sync/upload ke server. Bukan penyimpanan SharedPreferences
  sederhana; nilai melewati `LoadDiamondAndCoin(const uint8_t*, …)`.
- IAP (Play Billing 8.0.0, tipe `inapp`, `IapManager.smali`): 5 SKU diamond
  di string native —
  `com.happylabs.hotelstory2.200`, `.500`, `.1200`, `.3600`, `.6500`
  (kemungkinan paket 200/500/1200/3600/6500 diamonds; jumlah persis per SKU
  tidak terverifikasi dari string saja).
- Iklan: `CPlayerData::RemoveAdvertisements/IsAdvertisementRemoved`,
  `GetHouseAdFetchTime/SetHouseAdFetchTime`, `SetAdvertisementEnabled` —
  ada konsep remove-ads (berbayar) dan house ads. **Tidak ada** AdMob SDK
  di DEX (0 file `gms/ads`), tidak ada string `ca-app-pub-…` di mana pun;
  `GetAdmobAppID` hanya JNI getter native. Bentuk iklan yang ditayangkan
  tidak bisa dikonfirmasi dari analisis statis ini.
- Tidak ada subscription/VIP/season pass (tidak ada string terkait di `.so`).

## 9. Online vs offline — klasifikasi

**Hybrid online-first.**

- Yang jalan lokal: render loop OpenGL, simulasi hotel (NPC, bangunan,
  pendapatan), save blob lokal — game bisa dibuka dan dimainkan tanpa
  server untuk inti simulasinya.
- Yang butuh server: akun (ID, backup, banned status), upload/download save,
  ranking, follow/tips/shop-sale antar pemain, verifikasi struk IAP.
- Tidak ada bukti mode offline penuh: string `Offline` di `.so`
  (offset `0xf8482`) berada di antara string error libpng/JSON — konteksnya
  library, bukan mode permainan; tidak bisa dipakai sebagai bukti mode offline.
- Konsekuensi: edit nilai lokal (coins/diamonds) akan di-upload ke server
  sebagai bagian dari save, dan ada flag `IsFraudulent` +
  `IsEarningsCheated` yang menandai anomali. Klaim "bisa offline lalu aman"
  **tidak terbukti**.

## 10. Verdict per fitur mod

Aturan: server dulu, lokal kemudian. Tidak ada offset/alamat memori yang
diklaim — semua verdict berbasis bukti di atas.

| Fitur | Verdict | Bukti (satu baris) |
|---|---|---|
| Unlimited coins | **REFUSED** | Saldo di `CPlayerData`, save di-upload ke server (`OnFileUploadReply`) + flag `IsFraudulent` + `IsEarningsCheated` — ekonomi server-synced, bukan lokal murni |
| Unlimited diamonds | **REFUSED** | Diamond = mata uang IAP (5 SKU Play Billing) + struk diverifikasi server (`TryVerifyReceipt`); sama dengan bypass pembelian |
| Free shopping (bypass harga coin/diamond) | **REFUSED** | Harga ditegakkan native (`GetShopCoinCost/GetShopDiamondCost`, `OnCoinCheckSuccess/OnDiamondCheckSuccess`) dan pembelian tercatat server (`TryWriteShopSale`) |
| Unlock all (bangunan/item) | **UNVERIFIABLE** | State unlock ada di blob save lokal (objek `SaveData/LoadData`), tapi save di-sync ke server dan tidak ada bukti mana yang divalidasi — tidak bisa diklaim aman/moddable tanpa uji runtime |
| No ads | **UNVERIFIABLE** | `RemoveAdvertisements` adalah flag IAP berbayar; tidak ada AdMob SDK / app ID di APK, jadi bentuk iklan yang dihapus pun tidak terkonfirmasi |

Catatan tambahan: PairIP license check di startup berarti build mod dari APK
ini juga harus menghadapi proteksi itu; analisis ini tidak menyentuh cara
melewatinya.

## 11. Batasan analisis

- Tidak ada Ghidra/IDA/Hopper di VM — native hanya dibaca lewat `strings`,
  simbol ELF, dan `readelf`; tidak ada dekompilasi fungsi native.
- Endpoint game-server tidak terlihat plaintext di `.so`; alur pastinya
  (apa saja yang divalidasi server) hanya bisa dipastikan lewat uji runtime
  / traffic — tidak dilakukan di sini.
- Isi `m10.bin` / `tcid.bin` (data game ter-obfuscate) tidak di-decode.
- Verdict "asli" bertumpu pada tanda tangan + stamp Play; pembanding
  dengan listing Play Store tidak dilakukan.

## 12. Artefak

- `Hotel_Story_3.0.3_4_2fb5.apks` (asli, 15.385.075 B)
- `base.apk`, `split_config.arm64_v8a.apk`
- `decoded/` — hasil apktool base.apk (manifest, smali, res, assets)
- `native/lib/arm64-v8a/libnative-lib.so` — native lib dari split
- `apktool.log`
