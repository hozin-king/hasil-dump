# REA — HappyMall v3.1.3 (`com.happylabs.happymall2`)

Analisis statis (apktool + aapt2 + apksigner + `nm`/`strings`/`llvm-objdump`)
terhadap `HappyMall_3.1.3_5_i059.apks`. Tanggal: 7 Nov 2026.
Tidak ada build/mod yang dibuat — analisis saja.

## 1. Identitas

| Item | Nilai |
|---|---|
| File | `HappyMall_3.1.3_5_i059.apks` — 20.626.819 byte |
| Isi | `base.apk` 23.609.272 B, `split_config.arm64_v8a.apk` 4.719.016 B, `split_config.in.apk` 24.985 B (locale Indonesia), `split_config.xxhdpi.apk` 70.845 B |
| Package | `com.happylabs.happymall2` |
| Version | versionName `3.1.3`, versionCode `23` |
| SDK | minSdk 26, targetSdk 36, compileSdk 36 (Android 16) |
| Launcher | `com.happylabs.happymall2.MainActivity`, landscape, `appCategory=game` |
| Permissions | `INTERNET`, `ACCESS_NETWORK_STATE`, `com.android.vending.BILLING`, `com.android.vending.SUBSCRIPTIONS`, `com.android.vending.CHECK_LICENSE` |
| `allowBackup` | `true` (dengan `CustomBackupAgent`), `extractNativeLibs=false` |

## 2. Resmi atau repack? — RESMI (Play Store)

Bukti (`apksigner verify --print-certs` pada `base.apk`):

- `Verified using v2 scheme: true`, `v3 scheme: true`; `Verified for SourceStamp: true`.
- Satu signer, DN `CN=Android, OU=Android, O=Google Inc., L=Mountain View, ST=California, C=US`,
  sertifikat SHA-256 `785f34e19846d851496758e84bf87fa3a7c8c53d593d676d35ad45e97a346fcc`
  (RSA 4096) — ini pola sertifikat **Google Play App Signing**.
- Manifest membawa stamp Play: `com.android.stamp.source = https://play.google.com/store`,
  `com.android.stamp.type = STAMP_TYPE_DISTRIBUTION_APK`.
- Tidak ada tanda repack: tidak ada kelas/`.so` tambahan yang tidak dikenal,
  tidak ada `debuggable`, tidak ada string "mod"/"crack" di binary.

Yang **tidak** bisa diverifikasi tanpa referensi Play Store: apakah sertifikat
ini sama persis dengan yang dipakai developer untuk rilis ini (Play App Signing
membuat perbandingan langsung tidak dimungkinkan dari luar). Semua indikator
yang bisa diperiksa mengarah ke APK resmi.

## 3. Engine & arsitektur

- **Bukan Unity, bukan Unreal, bukan Cocos.** Engine C++ custom milik HappyLabs.
- Satu DEX (`classes.dex`, 6.662.760 B) — Java hanya jembatan tipis:
  `MainActivity`, `MainApplication`, `OpenGLRenderer`, `CustomView`,
  `AssetsManager`, `SystemManager`, `NativeMain`, `IAPManager`, `BackupHelper`.
- Satu native lib: `lib/arm64-v8a/libhappymall.so` (4.684.608 B, ELF aarch64,
  **stripped**, BuildID `17cce5c0c8960e1aae6ac2c452f7fb59b0e16bbc`),
  dikompilasi clang 18.0.1. 1.081 kelas C++ teridentifikasi dari simbol dinamis
  (mayoritas `C*Shop` — game ini tycoon mall: `CRamenShop`, `CBakery`,
  `CBookShop`, `CCandyShop`, … ratusan tipe toko/fasilitas).
- Aset: sprite PNG, `Sounds/*.ogg|mp3`, font `hobostd.ttf`, dan string table
  biner `assets/english.bin` (+ `indonesian.bin`, `japanese.bin`, dll).
- **PairIP** terpasang (`smali/com/pairip/`, application class
  `com.pairip.application.Application`) — lihat §6.

## 4. Server vs Lokal — LOKAL (offline penuh)

- **Tidak ada host server game sama sekali.** Grep URL di seluruh smali +
  `.so` hanya menemukan domain Google/Play (`play.google.com`,
  `googleapis.com` scopes: games, drive.appdata, userinfo) dan Firebase
  telemetry (`datatransport/cct`). Tidak ada endpoint `happylabs` / API game.
- Tidak ada OkHttp/Retrofit/Volley; satu-satunya HTTP adalah ke Google
  (Billing, License, Backup, telemetry).
- Game bisa dimainkan offline: tidak ada login wajib. Akun bersifat opsional
  ("Secure Your Account" via Facebook/Google, "Restore Your Account").
- `CAccountData` punya `SetSecondsSinceGameSavedOnServer` dan
  `SetBannedStatus`/`IsBanned` — tapi "server" di sini adalah **cloud backup**
  (Google Drive app-data / Play Games), bukan server otoritatif game.
  `CBackupManager::TrySave/TryDownloadBackup/IsSignedIn/GetBackupInfo`
  adalah backup save, bukan validasi ekonomi.
- Satu-satunya validasi server adalah **Google Play Billing** (pembelian
  subscription) dan **PairIP License Check** (lisensi Play) — keduanya
  dari Google, bukan dari developer.

**Klasifikasi: game single-player offline; semua state gameplay (uang,
progress, toko) tersimpan lokal.**

## 5. Ekonomi & mata uang

- Dua mata uang (string di `assets/english.bin`): **Gold** (`Gold: %d`) dan
  **Diamond** (`Diamond: %d`). Keduanya disimpan di `CPlayerData` di dalam
  save file lokal:
  - `CPlayerData::GetCoins()` @ `0x30dff0`, `AdjCoin(int)` @ `0x30e014`
  - `CPlayerData::GetDiamonds()` @ `0x30dfcc`, `AdjDiamond(int)` @ `0x30e0a8`
- Gold didapat dari pengunjung toko (`CNPCObject::PerformEarnMoney`,
  `DeductCoins`, `SetCmdEarnMoney`); Diamond dipakai untuk beli Gold
  (`CShopWindow::OnClickPurchaseCoins/PerformPurchaseCoins`,
  `CalculateDiamondNeeded`), mempercepat pembangunan
  (`CTourData::GetSpeedUpDiamondCost`), dan beli item
  (`CItemManager::GetShopDiamondCost`).
- Diamond gratis juga bisa didapat: quest/reward (`CRewardsData::GetDiamondRewardNum`),
  "Free Diamonds", nonton video ("Watch the video to earn \d now?"),
  anniversary ("1 Year Anniversary! 250\d Get!").
- **Satu-satunya produk Play Billing: subscription bulanan**
  `com.happylabs.happymall.monthly` (`IAPManager.smali`,
  field `SUBSCRIPTION_STR`; Billing Client 8.0.0). Tidak ada paket Diamond
  consumable di build ini.
- Manfaat subscription (string `english.bin`): "You get the below bonuses
  for 1 month — Double \m during FEVER!! / Higher Chance of getting \d too!!"
  + status VIP ("Thank you for becoming a VIP!") + hapus iklan
  (`CPlayerData::RemoveAdvertisements()` @ `0x30e3d8`,
  `IsAdvertisementRemoved()` @ `0x30e3cc`).
- Iklan: ada konsep rewarded video + flag `RemoveAdvertisements`, tapi
  **tidak ditemukan SDK iklan pihak ketiga** (tidak ada AdMob/AppLovin/
  UnityAds/Vungle di DEX maupun `.so`). Aset `HS_GenericAd_128x128.png`
  mengarah ke house-ad. Jalur pemberian reward video tidak bisa
  dipetakan statis — status: tidak terverifikasi.

## 6. PairIP & license check — penghalang repack, bukan root

- `Application.attachBaseContext()` langsung memanggil
  `com.pairip.licensecheck.LicenseClient.checkLicense()` sebelum
  `super.attachBaseContext()`.
- `LicenseClient` adalah verifikasi lisensi Google Play (LVL v2-style):
  tanda RS256 diverifikasi (`"Response must be signed with RS256 algorithm."`,
  `"Signature verification failed."`), cek nama paket
  (`"Package name doesn't match."`), cek berulang terjadwal
  (`"Repeated license check is scheduled in %d ms..."`), gagal → paywall
  intent (`LicenseActivity`, `"Paywall intent is not provided."`).
- Tidak ditemukan string deteksi root/emulator/Xposed/Frida/Magisk di
  smali PairIP. Satu kelas ter-obfuscate
  (`.../djYh/.../sllurwbjuqaymwbwyrrspquusrswp.smali`) hanya berisi 3
  konstanta int (kemungkinan kunci/checksum integritas) — fungsinya tidak
  bisa dipastikan statis.
- **Implikasi praktis: mod dalam bentuk APK repack hampir pasti gagal**
  (tanda tangan berubah → license check gagal). Jalur mod yang realistis
  adalah **root injector** (APK asli tidak disentuh, payload hook
  `libhappymall.so` saat runtime), seperti pola Hozin UE Hook / Unity
  Controller.

## 7. Save file — lokal, XOR + zlib + SHA-256

- File: `save.dat` di files dir (`SystemManager`: `"SystemMgr cFilesDir null"`;
  string `save.dat` di `.so`).
- `ProcessSaveFile()` @ `0x30edc4`: header 120 byte (`0x78`), magic/version
  check (`w8 & ~1 == 2`), ukuran data di offset `0x54`, lalu data di-XOR
  per-word 32-bit dengan kunci yang tersimpan di header offset `0x4`
  (kunci ada di dalam file — obfuscation, bukan enkripsi kuat).
- Lalu `CCompressor::UncompressData` (zlib — `libz.so`, simbol `inflate*`)
  dan `CSHA256::GenerateHash` @ `0x23b458` dipanggil 2x dari
  `ProcessSaveFile` (via PLT `0x3a9b60`) — integritas save dicek dengan
  **SHA-256 biasa** (bukan HMAC berkunci; `CSHA256::HmacHash` @ `0x23b558`
  ada di binary tapi **tidak punya pemanggil**).
- `CAccountData::SaveGame()` @ `0x308d10`, `LoadGame()` @ `0x308f10`;
  `CPlayerData` dan semua `C*Shop`/`CMapObject` punya
  `GetSaveDataSize/LoadData/SaveData` — seluruh progress ada di blob ini.
- **Edit save offline dimungkinkan** (XOR + zlib + SHA-256 semuanya bisa
  dihitung ulang tanpa server), tapi butuh tooling khusus karena formatnya
  custom; tidak ada editor jadi yang diverifikasi di sini.

## 8. Verdict per fitur

> Alamat di bawah adalah **offset file** di `libhappymall.so` (simbol
> dinamis terverifikasi via `nm -D`); alamat runtime = base lib + offset.
> Bukan hasil tebakan.

| Fitur | Verdict | Bukti |
|---|---|---|
| Unlimited Gold | **BOLEH (lokal)** | `CPlayerData::GetCoins/AdjCoin` di `.so`, save lokal `save.dat`, tanpa validasi server (§4–5, §7). Gold murni hasil gameplay, bukan mata uang beli. |
| Unlimited Diamonds | **DITOLAK** | Diamond adalah mata uang premium — manfaat subscription & "purchase of diamonds" terikat pembelian uang asli (§5). Unlimited Diamond = bypass IAP, kelas yang sama dengan penolakan Sand:box. |
| Free shopping / unlock semua toko | **SEBAGIAN** | Item berharga Gold → lokal, bisa. Item berharga Diamond (`GetShopDiamondCost`) → premium, ditolak (alasan sama seperti Diamond). |
| VIP / subscription gratis | **DITOLAK** | Produk `com.happylabs.happymall.monthly` diverifikasi Google Play Billing server-side (`IAPManager::acknowledgePurchase`, `checkSubscriptionStatus`). `CIAPManager::SetPlayerSubscription` @ `0x337be8` tidak bisa dipalsukan tanpa pembelian. |
| No ads | **BOLEH (lokal)** | Flag lokal `CPlayerData::RemoveAdvertisements()` @ `0x30e3d8` / `IsAdvertisementRemoved()` @ `0x30e3cc`; tidak ada cek server. Catatan: di desain game ini penghapusan iklan adalah manfaat berbayar — tapi implementasinya boolean lokal tanpa validasi. |
| Instant build / percepat timer | **TIDAK TERVERIFIKASI** | Timer & biaya speed-up ada (`GetSpeedUpDiamondCost`), tapi tidak ditemukan satu fungsi tunggal penentu timer secara statis. Butuh analisis runtime. |
| Free Diamonds via video ads | **TIDAK TERVERIFIKASI** | String reward video ada, tapi tidak ditemukan SDK iklan maupun jalur pemberian reward di binary. |
| Edit save (`save.dat`) | **BOLEH (lokal)** | Format custom XOR + zlib + SHA-256, semua bisa dihitung ulang offline (§7). Belum ada tool jadi — perlu dibuat/dites. |

## 9. Target hook (root injector, bila dibangun)

Simbol dinamis terverifikasi (`nm -D -C libhappymall.so`), offset file:

| Simbol | Offset |
|---|---|
| `CPlayerData::GetCoins()` | `0x30dff0` |
| `CPlayerData::AdjCoin(int)` | `0x30e014` |
| `CPlayerData::GetDiamonds()` | `0x30dfcc` |
| `CPlayerData::AdjDiamond(int)` | `0x30e0a8` |
| `CPlayerData::RemoveAdvertisements()` | `0x30e3d8` |
| `CPlayerData::IsAdvertisementRemoved()` | `0x30e3cc` |
| `CIAPManager::SetPlayerSubscription(signed char)` | `0x337be8` |
| `CIAPManager::TryUpdatePurchases(signed char)` | `0x337be0` |
| `CAccountData::SaveGame()` / `LoadGame()` | `0x308d10` / `0x308f10` |
| `CAccountData::IsBanned()` / `SetBannedStatus(signed char)` | `0x308d30` / `0x308ce4` |
| `ProcessSaveFile(...)` | `0x30edc4` |
| `CSHA256::GenerateHash(...)` | `0x23b458` |

## 10. Batasan analisis

- Tanpa Ghidra/IDA/Hopper di VM ini — tidak ada dekompilasi native
  mendalam; kesimpulan native berasal dari simbol dinamis + disassembly
  `llvm-objdump` pada fungsi yang relevan (`ProcessSaveFile`).
- Tanpa runtime: perilaku license check saat gagal, isi persis `save.dat`,
  dan jalur reward video tidak teramati langsung.
- Perbandingan sertifikat dengan rilis Play Store asli tidak dimungkinkan
  dari luar (§2).
