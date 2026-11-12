# REA — Truckers of Europe 3 v0.7.64 (`com.WandaSoftware.TruckersofEurope3`)

Analisis statis (apktool + aapt2 + apksigner + `nm`/`strings` + parser
`global-metadata.dat` IL2CPP v31 buatan sendiri) terhadap XAPK APKPure
`com.WandaSoftware.TruckersofEurope3` versionCode 193.
Tanggal: 7 November 2026.
Tidak ada build/mod yang dibuat — analisis saja.

## 1. Identitas

| Item | Nilai |
|---|---|
| File | `ToE3.xapk` — 659.725.960 byte |
| Isi XAPK | `com.WandaSoftware.TruckersofEurope3.apk` (base) 45.925.337 B, `UnityDataAssetPack.apk` 696.025.417 B, `config.arm64_v8a.apk` 31.123.755 B, `config.armeabi_v7a.apk` 30.079.325 B, `manifest.json`, `icon.png` |
| Package | `com.WandaSoftware.TruckersofEurope3` |
| Version | versionName `0.7.64`, versionCode `193` |
| SDK | minSdk 23, targetSdk 35, compileSdk 35 (Android 15) |
| Launcher | `com.unity3d.player.UnityPlayerActivity`, landscape, `appCategory=game`, `extractNativeLibs=true` |
| Permissions | `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `com.android.vending.BILLING`, `AD_ID` + `ACCESS_ADSERVICES_*`, `VIBRATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, `READ/WRITE_EXTERNAL_STORAGE`, `BIND_GET_INSTALL_REFERRER_SERVICE`, AppLovin AppHub `BIND_APPHUB_SERVICE` |

## 2. Resmi atau repack? — RESMI (Play Store)

Bukti (`apksigner verify --print-certs` pada base APK):

- `Verified using v1/v2/v3 scheme: true`; `Verified for SourceStamp: true`.
- Satu signer, DN `CN=Android, OU=Android, O=Google Inc.`, sertifikat
  SHA-256 `5c388af39778ed7a1aebfdf425719adc5f4e2accf82407cc0085f10a8addc23a`
  (RSA 4096) — ini pola sertifikat **Google Play App Signing**.
- Tidak ada tanda repack: tidak ada kelas/`.so` tambahan yang tidak dikenal,
  tidak ada `debuggable`, tidak ada string "mod"/"crack" di binary.

Yang **tidak** bisa diverifikasi tanpa referensi Play Store: apakah sertifikat
ini sama persis dengan yang dipakai developer untuk rilis ini (Play App
Signing membuat perbandingan langsung tidak dimungkinkan dari luar). Semua
indikator yang bisa diperiksa mengarah ke APK resmi.

## 3. Engine & arsitektur

- **Unity 2022.3.62f3, IL2CPP.** `lib/arm64-v8a/libil2cpp.so` 63.948.512 B,
  ELF aarch64 **stripped**, BuildID
  `e58a580ae0729c2b891bff56c363a2c220c52050`; `libunity.so` 20.848.296 B;
  `libmain.so` = Unity NativeLoader.
- `assets/bin/Data/Managed/Metadata/global-metadata.dat` 11.259.412 B,
  **metadata version 31** — layout berbeda dari v29 yang umum di tutorial:
  field "Count" di header adalah ukuran byte section; `TypeDefinition`
  88 byte; `MethodDefinition` 36 byte; `FieldDefinition` 12 byte;
  `ImageDefinition` 40 byte. Parser di `il2cpp_meta.py` (repo kerja ini).
- Hasil parse: **13.246 tipe, 141 image, 179 assembly**.
  `Assembly-CSharp.dll` 1.340 tipe (kode game, namespace global),
  `VehiclePhysics.dll` 517, `Wanda.GameServices.dll` 33,
  `Wanda.UniversalPackages.dll` 96, `Wanda.WorldBuilder.dll` 60,
  `Wanda.CharacterController.dll` 36, `Wanda.AnimationBuilder.dll` 22,
  `Wanda.UniversalPackages.Rope.dll`, `.ColorPicker.dll`,
  `.DailyRewards.dll`, `kTools.Mirrors.Runtime.dll` 12,
  `Google.Play.Games.dll`, Firebase (Analytics/RemoteConfig/Crashlytics),
  GoogleMobileAds + mediasi, DOTween, FMODUnity, Newtonsoft.Json,
  Sirenix Odin.
- **TIDAK ADA** assembly networking: tidak ada Photon, PlayFab, FishNet,
  Netcode, Mirror (networking). `kTools.Mirrors` adalah **rendering kaca
  spion truk** (`MirrorCameraOverride`, `MirrorMipMap`,
  `kTools.Mirrors.Mirror`) — bukan multiplayer.
- Aset: Unity Addressables dengan katalog **lokal**
  (`StreamingAssets/catalog_2026.03.04.12.08.41.json`; semua internal ID
  `{Wanda.Paths.STREAMING_ASSETS}/...bundle`); `settings.json` tidak
  mengandung URL remote (grep http kosong). Tidak ada OBB terpisah — data
  game ada di `UnityDataAssetPack.apk`.
- Iklan: Unity Ads, AppLovin MAX, Pangle (ByteDance), Meta Audience
  Network, AdMob, InMobi, Mintegral, Vungle/Liftoff. Google Play Games v2
  hadir. Unity Services: core 1.14.0 + **Purchasing 5.0.1**, environment
  production.

## 4. Server vs Lokal — LOKAL (single-player offline)

- **Tidak ada server game-state sama sekali.** Satu-satunya endpoint
  milik developer di string literal:
  `https://gs.wandaservices.net` (Wanda Game Services) — dipakai
  `ServiceManager` (`wandaServicesAPI`) untuk **deteksi negara via IP**
  (`GetCountryByIPAsync`) dan konfigurasi layanan; bukan server
  otoritatif ekonomi. URL lain di literal hanya domain umum
  (Unity dashboard, Firebase, sosial Wanda, skema XML/JSON standar).
- Tidak ada endpoint PlayFab/Photon/API game di `libil2cpp.so` maupun DEX
  (grep terarah `wanda`/`truckersofeurope`/`api`/`playfab`/`photon`
  kosong selain yang di atas). Hitung keyword di metadata:
  `Multiplayer` 0, `Convoy` 0, `Lobby` 0, `Leaderboard` 48,
  `Server` 127 (mayoritas string .NET/Unity generik), `Client` 409
  (mayoritas string .NET/Unity generik), `Purchase` 444, `Billing` 55.
- **Leaderboard & achievement = Google Play Games** (`Canvas/LeaderBoard`,
  `LeaderboardMe`/`LeaderboardTop`, string
  "IncrementAchievement can only be called after authentication") —
  hanya tampilan skor, bukan gameplay online. Tidak ada mode multiplayer,
  tidak ada lawan manusia.
- **Cloud save = Google Play Games Saved Games** (bukan server game):
  `GPG_CloudSaveSystem` — `LoadFromCloud`, `SaveToCloud`,
  `ProcessCloudData`, `ToBytes`, `FromBytes`; wrapper serialisasi
  `CSTruck`, `CSOwnedTrailer`, `CSGarage`, `CSTruckDetail`,
  `CSTruckCondition`, `CSTruckGearBox`, `CSTruckBars`, `CSTruckWheels`,
  `CSTrailerWheels`, `CSTruckInterior` (masing-masing field `ID` + objek
  data). Cloud hanya sinkronisasi/backup profil lokal.
- Firebase Remote Config ada (`remoteConfigFetched` di
  `ServiceManagerGlobal`) — dipakai untuk menala nilai (mis. persentase
  bonus iklan, §5), bukan untuk memvalidasi ekonomi.
- `Radio` (Wanda.UniversalPackages) = radio internet dalam game
  (`RADIO_COUNTRY`) — butuh internet untuk streaming, bukan server game.
- Game bisa dimainkan offline: tidak ada login wajib. Akun Play Games
  bersifat opsional (sign-in, leaderboard, cloud save).

**Klasifikasi: game single-player offline; semua state gameplay (uang,
emas, progres, truk, garasi) tersimpan lokal.**

## 5. Ekonomi & mata uang

### 5.1 Dua mata uang — `Prefs` (aksesori sentral) + `ProfileData` (model)

- **`Prefs`** — kelas aksesori statis untuk seluruh profil
  (`prefIdsWithProfile`, kunci per-profil): `get/set_Balance`,
  `get/set_Gold`, `get/set_AdFree`, `get/set_UnlockTrailers`,
  `get/set_WashTickets`, `get/set_Level`, `get/set_Xp`,
  `get/set_JobFuel`, `get/set_TruckIds`, `get/set_OwnedTrailerIds`,
  `get/set_GarageIds`, `get/set_DriverIds`, `get/set_CompletedJobs`,
  `get/set_MoneyEarnt`, `get/set_MoneySpent`, `get/set_DistanceDriven`,
  `get/set_LastSleep`, `get/set_Time`, `get/set_CurrentJob`,
  `get/set_CurrentTruck`, `get/set_CurrentTrailer`,
  `get/set_CompanyName`, `get/set_CurrentCity`, `get/set_LastPosition`,
  `get/set_LastRotation`, `get/set_LastMapPosition`,
  `get/set_TrailerDamage`, `get/set_CurrentFerry`, `CustomSkins`,
  `TruckDetails`/`TruckBars`/`TruckWheels`/`TruckConditions`/
  `TruckInterior`/`TruckGearBoxes`, `TrailerWheels`, `EditTruck`,
  `EditTrailer`, `OwnableTrailerConnected`, `get/set_PlayerName`,
  `get/set_ProfileImage`, `get/set_CompanyLogo`, plus seluruh
  pengaturan (kontrol, kamera, grafis, audio, radio).
- **`ProfileData`** — model profil: `Balance`, `Gold`,
  `InitialGoldReceived` (flag emas awal sekali), `Level`, `Xp`,
  `JobFuel`, `CompanyName`, `GarageIds`, `GarageDetails`,
  `CurrentTruck`, `TruckIds`, `Trucks`, `CurrentTrailer`,
  `OwnedTrailerIds`, `OwnedTrailers`, `WashTickets`, `LastSleep`,
  `Time`, `DistanceDriven`, `CompletedJobs`, `MoneyEarnt`,
  `MoneySpent`, `CurrentJob`, `CustomSkins`, `TrailerDamage`,
  `PlayerName`, `ProfileImage`, `CompanyLogo`, `TruckInterior`,
  `TruckDetails`, `TruckConditions`, `TruckGearBoxes`, `TruckBars`,
  `TruckWheels`, `TrailerWheels`, `EditTruck`, `EditTrailer`,
  `OwnableTrailerConnected`, `LastPosition`, `LastRotation`,
  `LastMapPosition`, `CurrentCity`.
- **`PlayerData`** — `ProfileIDS`, `CurrentProfile`, `LastTruckID`,
  `LastTrailerID`, `NextProfileID` + 3 field obfuskasi
  (`AlKDkk`, `KYHghsmPmn`, `pmdSsdjgzxw` — kemungkinan anti-tamper/
  checksum, belum terpetakan; hanya punya `.ctor`).
- **Balance** = uang hasil job (mata uang utama). **Gold** = mata uang
  premium. Keduanya dibaca/ditulis lewat `Prefs` — tanpa validasi server.

### 5.2 Produk IAP — Unity Purchasing 5.0.1, Google Play Billing

`IAPInitialize` (Assembly-CSharp): `m_StoreController`,
`InitializeIAP`, `OnProductsFetched`, `OnPurchasesFetched`,
`GrantProductReward`, `OnPurchasePending`, `OnPurchaseConfirmed`,
`OnPurchaseFailed`, `BuyProduct`, `RestoreProduct`, `UpdateBalance`,
field `removeAds`, `isInited`. `IAPButtonData`: `restore`, `button`,
`header`, `price`, `consumable`, `noAds`, `eventTag`,
`OnPurchaseCompleted`.

Daftar produk — dari binding tombol `BuyProduct`/`RestoreProduct` di
prefab toko (bundle Addressables `b80899da…` dan `d7618fdda…`):

| Product ID | Isi (label di UI) | Jenis |
|---|---|---|
| `coins1` … `coins4` | Paket In-Game Money: 30.000 / 70.000 / 150.000 / 300.000 | Consumable |
| `golds1` … `golds4` | Paket In-Game Gold: 10 / 25 / 60 / 120 | Consumable |
| `remove_ads` | Remove Ads | Non-consumable |
| `unlock_trailers` | Unlock All Trailers | Non-consumable |

Catatan: keempat nominal Money dan keempat nominal Gold muncul sebagai
label di prefab yang sama dengan tombolnya, dalam urutan naik
(`coins1`→30.000 … `coins4`→300.000; `golds1`→10 … `golds4`→120).
Pemetaan 1:1 persis tidak terkonfirmasi secara statis — urutan di atas
adalah inferensi dari susunan prefab. `GrantProductReward` adalah
penerima hadiah pasca-pembelian (`OnPurchaseConfirmed` →
`GrantProductReward` → `Prefs.set_Balance`/`set_Gold`/`set_AdFree`/
`set_UnlockTrailers`); tidak ditemukan endpoint validasi pembelian
di server developer — validasi adalah Google Play Billing via Unity IAP.

### 5.3 Alur uang (Balance)

- **Job** (`Job`): `Income`, `BonusMultiplier`, `CargoWeight`,
  `CargoName`, `Km`, `Time`, `Level`, `Trailer`, `OwnedTrailer`,
  `CargoLoaded`, `From`, `To`. `JobManager`: `GenerateJob`,
  `GenerateJobList`, `GenerateCargoList`, `SetAvailableJobs`,
  `GetJobWithBonus`, `GetJob`, `Cancel`, `CheckAd`,
  field `showAdToGetJob`, `trailersUnlocked`.
- **Selesai job** (`JobComplete`): `SetXP`, `SetSocial`, `Completed`,
  `RemovePenaltiesWithAd`, `RemovePenalties`, `LevelUp`,
  field `_income`, `_totalPenalties`, `xpToAdd`, `xpToLevelUp`,
  `currentXp`, `currentLevel`. Penalti mengurangi income; iklan
  rewarded bisa menghapus penalti.
- **Level/XP**: naik lewat penyelesaian job (`JobComplete.SetXP`/
  `LevelUp`); tersimpan lokal di `Prefs.Level`/`Prefs.Xp`; dipakai
  sebagai syarat job/trailer (`Job.Level`,
  `TrailerConfigure.trailerLevel`/`currentLevel`).
- **Belanja**: truk (`TruckManager`: `SetOwnedTrucksID`,
  `TruckDealer`, `sellCurrentVehicle`), trailer (`TrailerManager`:
  `SetOwnedTrailersID`, `TrailerDealer`, `sellCurrentTrailer`),
  garasi (`GarageManager`: `BuyNewGarage`, `SellGarage`,
  `UpgradeGarage`, `VisitGarage`, `SelectGarage`; katalog `Garage`:
  `ID`, `City`, `MaxCapacity`, `Price`), supir (`DriverManager`;
  `Driver`: `Name`, `Experience`, `Wage`, `FinishedJobs`, `Profit`,
  `GarageID` — supir bekerja dan menghasilkan profit, upah dibayar
  dari Balance), kustomisasi (`Configure`/`TrailerConfigure`:
  `AskPurchaseSure`, `ConfirmCustomize`, `SaveAndAssign`).
- **Bahan bakar** (`FillFuel`): `Fill`, `Pay`, `ShowAd`, `Dec`,
  field `literPrice`, `tankCapacity`, `totalToPay`, `fAmount`;
  `TruckController`: `fuel`, `fuelLeft`, `totalJobFuel`,
  `fuelTankCapacity`, `fuelRate`, `idleFuelConsumption`,
  `fuelMultiplier`; `Prefs.JobFuel`; `FuelRepairUI`: `serviceType`,
  `totalToPay`, `towFee`. Isi bensin dibayar Balance (`Pay`) atau
  gratis via iklan rewarded (`ShowAd` → `TSAdManager.targetFillFuel`).
- **Perbaikan & cuci**: `Repair`: `repairPrice`;
  `TruckCondition`: `Fuel`, `Health`, `Dirtiness`, `Dustiness`,
  `TotalKm`; `WashTickets` (tiket cuci gratis) + `WashUI`/`CleanTruck`.
  Semua dibayar Balance / tiket lokal.
- **Gold di dalam gameplay**: sebagian aksesori/kustomisasi truk &
  trailer dibayar dengan Gold — `Configure`: `additionalGold`,
  `additionalAccessoriesGold`, `editAccessoriesGold`
  (`totalPrice`, `additionalPrice`, `colorPrice`,
  `editSelectedChassisPrice`, `editSelectedEnginePrice`,
  `editSelectedGearBoxPrice`, `editSelectedCabinPrice`,
  `editAccessoriesPrice`, `editBarsPrice`, `editWheelsPrice`);
  string `AdditionalGoldFee`, `InsufficientGold`. Emas awal sekali
  via `ProfileData.InitialGoldReceived`. Tidak ditemukan sumber Gold
  dari job (income job selalu Balance); sumber Gold dalam game di luar
  IAP tidak terkonfirmasi (lihat §8, Daily Rewards).

### 5.4 Iklan rewarded — `TSAdManager` + `ServiceManager`

`TSAdManager`: `OnRewardedAdSuccess`, `OnRewardedAdClosed`,
`OnRewardedAdFailed`, `RewardedAdNotAvailable`, `LoadMapAd`,
`ShowMessageInConfigure`; target: `targetJobManager`,
`targetJobComplete`, `targetFuelRepairUI`, `targetWashUI`,
`targetRepair`, `targetFillFuel`, `parkTrailer`. Hadiah iklan
berupa **persentase** (kemungkinan ditala via Firebase Remote Config):
`GetJobBonusPercentage`, `GetGarageBuyDiscountPercentage`,
`GetGarageUpgradeDiscountPercentage`, `GetGarageSellBonusPercentage`,
`GetTruckBuyDiscountPercentage`, `GetTruckSellBonusPercentage`,
`GetTrailerBuyDiscountPercentage`,
`GetTrailerSellBonusPercentage`. `ServiceManager` (122 method):
mediasi iklan, IAP, sign-in Play Games, Firebase Remote Config,
`GetCountryByIPAsync`, `ShowGooglePlayReview`; field `_noAds`,
`purchaseCount`, `adRewardCount`; `ServiceManagerGlobal.products`;
PlayerPrefs keys: `SM_AD_REWARDS`, `SM_IAP_NOADS`,
`SM_IAP_PURCHASES`, `SM_PLAYTIME`, `SM_RETURNING_DAYS`,
`SM_RETURNING_DAYS_LASTDATE`. Event analitik:
"Rewarded Ad: {0}, Data: {1}, Country: {2}, Returned: {3},
Purchases: {4}, Ad Rewards: {5}, Play Time: {6}".

## 6. Save file — PlayerPrefs lokal (kemungkinan terenkripsi)

- Seluruh progres lewat `Prefs` (kunci per-profil,
  `prefIdsWithProfile`) di atas **Unity PlayerPrefs** — di Android
  filenya `shared_prefs/com.WandaSoftware.TruckersofEurope3.v2.playerprefs.xml`
  (path standar Unity; tidak ada file save custom `.dat`/`.json`
  untuk profil — literal `.json` yang ada hanya konfigurasi
  Addressables/Unity Services).
- **`ZPlayerPrefs`** (Wanda.UniversalPackages) adalah wrapper
  PlayerPrefs **terenkripsi AES**: `GetIV`, `Encrypt`, `Decrypt`,
  field `useSecure`, `keyLength`, `Iterations`, `strPassword`,
  `strSalt`. Apakah `Prefs` melewati wrapper ini atau PlayerPrefs
  polos **tidak bisa dikonfirmasi secara statis** (panggilan ada di
  kode native `libil2cpp.so` yang stripped); kunci/password adalah
  literal hardcode di binary bila enkripsi aktif. Implikasi: edit XML
  PlayerPrefs mentah mungkin tidak mempan bila `useSecure` aktif —
  jalur hook runtime (`Prefs.set_*`) lebih andal.
- 3 field obfuskasi di `PlayerData` (`AlKDkk`, `KYHghsmPmn`,
  `pmdSsdjgzxw`) kemungkinan checksum anti-tamper atas profil;
  fungsinya belum terpetakan — butuh verifikasi runtime.
- Penyimpanan truk/trailer kustom: `Configure`/`TrailerConfigure`
  punya `Save`/`_Save`/`Load`/`loadAsync` sendiri (state machine
  async `<_Save>d__160`, `<_Save>d__96`, `<loadAsync>d__158`,
  `<loadAsync>d__94`, `<Load>d__5`) — data kendaraan diserialisasi
  ke `Prefs` (`TruckDetails`, `TruckBars`, `TruckWheels`, dst.).
- Cloud save (§4) hanya menyalin profil lokal ke Play Games; arah
  sinkronisasi lokal-dulu.

## 7. Anti-cheat / root detection — TIDAK ADA

- **Tidak ditemukan** RootBeer, SafetyNet, Play Integrity, PairIP,
  atau deteksi root/emulator/Xposed/Frida/Magisk di DEX/smali
  (grep `rootbeer|isrooted|safetynet|playintegrity|magisk|frida|
  xposed|busybox|pairip` — hanya false positive di internal
  `com.google.android.gms.measurement`, `nearby`, dan Unity Ads).
- `lib/arm64-v8a/libnms.so` (299.528 B, hanya mengekspor
  `JNI_OnLoad`) **bukan anti-cheat**: string di dalamnya
  `com.pgl.ssdk.ces.a` + paket smali `com.pgl.ssdk.ces` membuktikan
  ini komponen native **SDK iklan Pangle (ByteDance)** — membaca
  system property/`environ`/file untuk fingerprint perangkat
  (anti-fraud iklan), bukan untuk game.
- `lib/arm64-v8a/libpglarmor.so` = crypto Pangle (iklan), juga
  bukan anti-cheat.
- Tidak ada proteksi integritas yang menghalangi root injector;
  satu-satunya penghalang potensial adalah checksum profil (§6).

## 8. Verdict per fitur

> `Prefs.set_*` / `Prefs.get_*` adalah method C# di `libil2cpp.so`
> (stripped — tidak ada offset file statis; lihat §9 untuk cara
> resolusi runtime). Indeks method di bawah adalah indeks di
> `global-metadata.dat` (terverifikasi via parser v31).

| Fitur | Verdict | Bukti |
|---|---|---|
| Unlimited Balance (uang job) | **BOLEH (lokal)** | `Prefs.get_Balance`/`set_Balance` (method idx 13632/13633), save PlayerPrefs lokal, tanpa validasi server (§4–6). Balance murni hasil gameplay, bukan mata uang beli. |
| Unlimited Gold | **DITOLAK** | Gold adalah mata uang premium — paket berbayar `golds1`–`golds4` (10/25/60/120 Gold, §5.2) diverifikasi Google Play Billing via Unity IAP. Unlimited Gold = bypass IAP, kelas yang sama dengan penolakan Diamond di HappyMall. |
| Beli truk / trailer / garasi / supir (harga Balance) | **BOLEH (lokal)** | Harga di katalog lokal (`Garage.Price`, `OwnableTrailer.Price`, `TrailerChassis.Price`, `Truck.Value`); pembelian via `Configure.AskPurchaseSure` (idx 12657), `TrailerConfigure.AskPurchaseSure` (idx 12810), `TruckDealer`/`TrailerDealer`, `GarageManager.BuyNewGarage` — semua lokal. |
| Unlock All Trailers (`unlock_trailers`) | **DITOLAK** | Produk IAP non-consumable berbayar (`Prefs.set_UnlockTrailers`); memberikannya tanpa beli = bypass pembelian nyata. Beli trailer satu-per-satu dengan Balance tetap BOLEH (baris di atas). |
| Remove Ads (`remove_ads`) | **BOLEH (lokal)** | Flag lokal `Prefs.get/set_AdFree`, `ServiceManager._noAds`, key `SM_IAP_NOADS` — tanpa cek server. Catatan: secara desain ini produk IAP berbayar; vonis mengikuti preseden laporan HappyMall (flag lokal tanpa validasi). |
| Free fuel / tanpa konsumsi BBM | **BOLEH (lokal)** | `TruckController.fuel`/`fuelLeft`/`fuelRate`, `FillFuel.Pay` (Balance lokal), `Prefs.JobFuel` — semua lokal; isi bensin gratis via iklan memang disediakan game (`FillFuel.ShowAd`). |
| Free repair / no damage | **BOLEH (lokal)** | `TruckCondition.Health`, `Repair.repairPrice`, `FuelRepairUI.totalToPay` — lokal, tanpa validasi server. |
| Free wash | **BOLEH (lokal)** | `WashTickets` di `Prefs`, `WashUI`/`CleanTruck` — lokal. |
| XP / Level instan | **BOLEH (lokal)** | `Prefs.Level`/`Xp`, `JobComplete.SetXP`/`LevelUp` — lokal; level hanya gerbang konten lokal. |
| Income job besar / tanpa penalti | **BOLEH (lokal)** | `Job.Income`, `Job.BonusMultiplier`, `JobComplete._totalPenalties`/`RemovePenalties` — dihitung lokal saat job selesai. |
| Reward iklan tanpa menonton iklan | **SEBAGIAN** | Jalur pemberian hadiah lokal (`TSAdManager.OnRewardedAdSuccess`, idx 13886; persentase bonus/diskon di §5.4), tapi SDK mediasi iklan bisa memverifikasi penayangan di pihaknya; jalur verifikasi tidak terpetakan penuh secara statis. Bukan target utama. |
| Daily / Returning Days reward | **TIDAK TERVERIFIKASI** | Key `SM_RETURNING_DAYS`/`SM_RETURNING_DAYS_LASTDATE` + `returningDaysCount` + assembly `Wanda.UniversalPackages.DailyRewards.dll` ada, tapi assembly tersebut tidak muncul di tabel image metadata (kemungkinan dimuat dari bundle) dan isi hadiahnya (Gold? Balance?) tidak terkonfirmasi. |
| Edit save (PlayerPrefs) | **BOLEH (lokal)** | `Prefs` + PlayerPrefs XML (§6). Catatan: bila `ZPlayerPrefs` aktif (AES), edit XML mentah tidak mempan; dan 3 field obfuskasi `PlayerData` mungkin checksum — butuh verifikasi runtime sebelum mengandalkan jalur ini. |
| Cheat leaderboard / multiplayer | **TIDAK ADA** | Tidak ada multiplayer (§4); leaderboard Play Games hanya tampilan skor. Tidak ada fitur ekonomi yang terikat ke leaderboard. |

## 9. Target hook (root injector, bila dibangun)

`libil2cpp.so` stripped — **tidak ada offset file statis** untuk
method C#. Target yang stabil adalah pasangan (tipe, method) +
indeks metadata; alamat runtime di-resolve lewat API IL2CPP
(`il2cpp_domain_get_assemblies` → `il2cpp_class_from_name` →
`il2cpp_class_get_method_from_name`), lalu hook dengan Dobby —
pola yang sama seperti Hozin UE Hook. APK asli tidak disentuh
(mod APK repack tidak disarankan: build resmi Play App Signing,
§2).

| Target | Method (idx metadata) | Kegunaan |
|---|---|---|
| `Prefs::set_Balance` | 13633 | Set Balance (uang) |
| `Prefs::get_Balance` | 13632 | Baca Balance |
| `Prefs::set_Gold` | 13635 | Set Gold — **DITOLAK (§8), hanya dokumentasi** |
| `Prefs::get_Gold` | 13634 | Baca Gold |
| `Prefs::set_AdFree` | — (nama terverifikasi, idx tidak dicatat) | Flag no-ads |
| `Prefs::set_UnlockTrailers` | — (nama terverifikasi, idx tidak dicatat) | Unlock trailer — **DITOLAK (§8)** |
| `Prefs::set_Level` / `set_Xp` | — (nama terverifikasi) | Level/XP instan |
| `Prefs::set_WashTickets` | — (nama terverifikasi) | Tiket cuci |
| `Prefs::set_JobFuel` | — (nama terverifikasi) | Bahan bakar job |
| `IAPInitialize::GrantProductReward` | 13221 | Titik pemberian hadiah IAP — **jangan dipakai untuk memalsukan pembelian** |
| `IAPInitialize::UpdateBalance` | 13237 | Refresh tampilan Balance pasca-transaksi |
| `TSAdManager::OnRewardedAdSuccess` | 13886 | Callback hadiah iklan (§8: SEBAGIAN) |
| `Configure::AskPurchaseSure` | 12657 | Konfirmasi beli truk (gerbang harga) |
| `TrailerConfigure::AskPurchaseSure` | 12810 | Konfirmasi beli trailer (gerbang harga) |
| `Pause::UpdateBalance` | 14202 | Refresh tampilan Balance di pause menu |

Alternatif tanpa hook: edit PlayerPrefs XML di perangkat root
(`shared_prefs/com.WandaSoftware.TruckersofEurope3.v2.playerprefs.xml`)
— dengan catatan enkripsi/checksum di §6.

## 10. Batasan analisis

- Tanpa Ghidra/IDA dan tanpa runtime: isi persis save di perangkat,
  status aktif `ZPlayerPrefs` (`useSecure`), fungsi 3 field obfuskasi
  `PlayerData`, dan isi hadiah Daily/Returning Days tidak teramati
  langsung.
- Pemetaan 1:1 product ID ↔ nominal paket IAP (§5.2) adalah inferensi
  urutan prefab, bukan konfirmasi statis.
- `GrantProductReward` tidak didekompilasi — alur hadiah per produk
  disimpulkan dari nama method + binding UI + label prefab.
- Perbandingan sertifikat dengan rilis Play Store asli tidak
  dimungkinkan dari luar (§2).
- `libnms.so` diidentifikasi sebagai komponen Pangle dari string
  `com.pgl.ssdk.ces.a` + paket smali terkait; fungsi internal pastinya
  tidak didekompilasi.
