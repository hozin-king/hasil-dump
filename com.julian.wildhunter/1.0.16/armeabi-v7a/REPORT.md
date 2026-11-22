> Catatan arsip: Game ini 32-bit saja (armeabi-v7a) — tidak jalan di perangkat 64-bit only.

# REA — Wild Hunter 3D (com.julian.wildhunter)

**Tanggal:** 17 Nov 2026 · **Metode:** dump + decompile statis (skill `local-rea`) · **Riset saja — TIDAK ada injector yang dibangun, TIDAK ada push.**

> **STATUS: ✅ SELESAI (20:18 WIB).** XAPK resmi 1.0.16 berhasil didapat (unduh via browser dari APKPure, setelah 14 percobaan API dari VM gagal 403). Dump penuh + audit injector selesai. **TEMUAN UTAMA: game ini 32-bit saja (armeabi-v7a) — TIDAK akan jalan di POCO X6 Pro user (64-bit only), sama seperti Granny Smith. Seluruh rencana injector untuk HP user gugur di titik ini** (lihat §0.1).
>
> **KOREKSI 18 Nov 2026 — build ARM64 ADA:** XAPK APKPure di atas memang hanya v7a, tapi **build Play Store 1.0.16 (code 17) punya split `config.arm64_v8a.apk`** — didapat dari APK20 (mirror database Play Store) tanpa file dari HP user; signer SHA-1 identik dengan XAPK ini (`9dbf6ce1…`). REA arm64 lengkap (offset field, RVA fungsi, rantai tembak terverifikasi, pola byte pattern-scan) ada di **`REPORT-ARM64.md`** — laporan ini (v7a) tetap berlaku sebagai arsip, dan klasifikasi fitur di `AUDIT-INJECTOR.md` berlaku untuk kedua ABI.

## 0. Ringkasan eksekutif

| Pertanyaan | Jawaban |
|---|---|
| Engine | **Unity 2022.3.62f2, IL2CPP**, metadata v31, 41.051 method, 44 DLL |
| Arsitektur | **armeabi-v7a SAJA (32-bit)** — tidak ada lib/arm64-v8a di base APK maupun split APK. **Tidak jalan di POCO X6 Pro (64-bit only)** |
| Klaim "full offline" | **TERBUKTI untuk gameplay** — tembakan, damage, hewan/AI, misi, energi, koin, daily bonus semuanya lokal (disassembly-verified). "Online"-nya hanya: iklan, analitik, IAP via Google Play |
| Klaim "online cuma buat beli item" | **Hampir tepat, dengan koreksi** — selain IAP ada juga iklan berhadiah + analitik (Flurry, Unity Analytics). Tidak ada server game, tidak ada sync progres |
| Mode misi | ✅ Misi berburu lawan hewan AI/bot, 4 GameMode (Hunt/Wave/Motion) × 4 MissionMode (Random/Level/Special/Challenge). **Tidak ada PvP** — tidak ada satu pun class/method PvP/multiplayer/leaderboard di dump |
| Anti-cheat | **Tidak ada** — tidak ada Play Integrity, SafetyNet, RootBeer, atau deteksi root. Satu-satunya "attestation" adalah AdMob ads-attestation |
| Ekonomi | **100% lokal** — 2 mata uang (coins + diamond) disimpan lokal (PlayerPrefs-style); IAP 12 SKU ($1.99–$99.99) via Unity IAP 4.11.0 / Google Play Billing |
| Energi | Lokal — maks 15, regen berbasis jam perangkat, tiap misi ada energyCost |
| Daily bonus / 7-day reward | Lokal — "server time"-nya ternyata **jam perangkat sendiri** (`System.currentTimeMillis()/1000` di Java), bukan dari jaringan |
| ESP referensi (`ESP_3_thnu.h`) | Rendering saja — bisa dipakai, tapi butuh sumber posisi dari game (lihat `~/workspace/rea-sniper3d/REPORT.md` §8 untuk penilaian metode yang sama). Enumerasi hewan tersedia: `Animal : ListedUnity<Animal>` |

### 0.1 ⚠️ TEMUAN UTAMA — game 32-bit-only, tidak jalan di POCO X6 Pro

- XAPK berisi **satu split native saja: `config.armeabi_v7a.apk`** (30.642.744 B) dengan `lib/armeabi-v7a/libil2cpp.so`, `libmain.so`, `libunity.so`. Base APK **tidak punya folder `lib/` sama sekali**. `grep` arm64 di kedua APK: **0 hasil**.
- POCO X6 Pro user adalah perangkat **64-bit-only** (tidak ada runtime 32-bit) — persis kasus Granny Smith (14 Nov). APK ini **tidak bisa di-install** di HP user, apalagi di-inject.
- **Konsekuensi:** injector Wild Hunter 3D **tidak ada gunanya dibangun untuk HP user** — tidak ada target yang bisa jalan. Satu-satunya jalan bila user tetap mau: perangkat lain yang masih mendukung 32-bit, atau emulator (bukan yang user pakai). Keputusan ada di user; agen ini tidak membangun apa pun.
- Audit injector di `AUDIT-INJECTOR.md` tetap dilengkapi (klasifikasi BOLEH/DITOLAK + desain payload + alamat/offset) sebagai arsip — berlaku untuk v1.0.16 di perangkat 32-bit, **bukan** untuk POCO X6 Pro.

## 1. Identitas & sumber (metadata publik + verifikasi binary)

| Item | Nilai | Sumber |
|---|---|---|
| Package | `com.julian.wildhunter` | Play Store / APKPure / aapt |
| Nama | Wild Hunter 3D (label APK: "Wild Hunter") | Play Store / aapt |
| Developer | Italic Games | Play Store / AppBrain |
| Versi | **1.0.16 (versionCode 17), 21 Agu 2026** ("Fixed some crash bugs") | APKPure / AppBrain / aapt |
| Format | XAPK 66.627.308 B (63,5 MB): base APK 35.343.024 B + split `config.armeabi_v7a.apk` 30.642.744 B + icon.png | Unduhan terverifikasi |
| Arsitektur | **armeabi-v7a saja** | Isi XAPK (lihat §0.1) |
| minSdk / targetSdk | 23 (Android 6.0) / 36 (Android 16) | aapt + manifest.json |
| Rating | 4,51★, 235.229 ulasan; 10 jt+ install (Play), 32 jt total (AppBrain) | AppBrain |
| Signature APK | SHA-1 `9dbf6ce1def6bca7ff7801360dc8c07b481eb691` (CN=FruitsMobile, Beijing) — **COCOK PERSIS dengan yang dipublikasikan APKPure** | `keytool -printcert -jarfile` |
| SHA-256 XAPK | `402b48438cd90eb196d71b578ac08e1b2508342d02d24655ad4cff3de88d754f` | sha256sum |
| IAP | Ya (12 SKU, §7) | Play Store / smali `WildHunter.SKU_ID` |
| Rilis awal | Agustus 2015 (di Play Store sejak Agu 2015) | AppBrain / SensorTower |
| Deskripsi resmi | "Aim and Shoot! Wild Hunter offers you the unique game-play that you can hunt wild animals not only on foot but also on a fast moving vehicle!" | Play Store (via AppBrain) |

### 1.1 Log percobaan unduhan (17 Nov 2026, 12:16–13:04 WIB)

APKPure API diblokir Cloudflare 403 dari IP egress VM (14 percobaan gagal, 12:22–13:01). Retry loop babak 2 berjalan detached sejak 13:02. **XAPK akhirnya didapat 13:04 via unduhan browser dari APKPure** (file `work/wildhunter-1.0.16.xapk`, ZIP valid, ukuran + SHA-256 terverifikasi, tanda tangan APK cocok dengan publikasi APKPure — binary autentik, bukan MOD). Detail 14 percobaan gagal ada di arsip kerja (`work/retry_loop*.log`); tidak diulang di sini.

## 2. Metode dump

1. XAPK → ekstrak base APK + split; verifikasi ukuran + SHA-256 + tanda tangan APK vs metadata APKPure.
2. `aapt dump badging` (identitas, permission, versionCode).
3. Inventaris `lib/*.so` + `assets/`; engine = Unity IL2CPP (`libil2cpp.so` + `global-metadata.dat`).
4. **Cpp2IL 2022.1.0-pre-release.21** (`~/workspace/rea-bussid-461/tools/Cpp2IL-Linux`, `--force-unity-version 2022.3.62f2`): metadata v31 → 44 DLL (`cpp2il_out/`; `Assembly-CSharp.dll` 331.776 B, 388 class) + `dll_il_recovery` (`cpp2il_ilrec/`).
5. **ilspycmd 8.2.0.7535** (`~/.dotnet/tools/ilspycmd`, `DOTNET_ROOT=~/.dotnet`, `DOTNET_ROLL_FORWARD=LatestMajor`) → `decompiled/` + `decompiled_ilrec/` (keduanya hanya signature — badan method `throw null`).
6. **Il2CppDumper** (`~/workspace/flylm/il2cppdumper/`, metadata v31 didukung; CodeRegistration `0x104d4fc`, MetadataRegistration `0x105e914`) → `dump.cs` (field offset), `script.json` (41.051 method + alamat RVA), `stringliteral.json` (10.161 string).
7. **Badan method dibaca dari disassembly ARMv7** (capstone 5.0.7, skrip `work/disas.py`, alamat dari `script.json`) — karena dump ISIL Cpp2IL mati kena OOM 2× (VM 6 GB) dan ilrec tidak memulihkan badan method untuk binary 32-bit ini.
8. **Smali Java** via apktool 2.10.0 (JDK 17) atas base APK — untuk sisi Java (`WildHunter` Activity, `SharedPreferencesHelper`, billing, ads).
9. `strings` atas dex (5 file) + `libil2cpp.so` + metadata string table — untuk URL/host/SDK.

## 3. Arsitektur game (dari dump)

| Komponen | Bukti |
|---|---|
| Engine | Unity 2022.3.62f2 (string di `libunity.so`: `2022.3.62f2 (7670c08855a9)`), IL2CPP |
| `libil2cpp.so` | 17.905.292 B, ARMv7, `.text` R-X di offset 0 |
| `libunity.so` | 12.691.496 B, ARMv7 |
| `libmain.so` | 8.588 B |
| `global-metadata.dat` | 5.170.412 B, magic `0xFAB11BAF`, version **31** |
| Assembly-CSharp | 388 class, 41.051 method total (semua DLL) |
| Permission | INTERNET, ACCESS_NETWORK_STATE, BILLING, ACCESS_WIFI_STATE, AD_ID, ACCESS_ADSERVICES_AD_ID/ATTRIBUTION/TOPICS, FOREGROUND_SERVICE, DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION |
| Save | Lokal — `PlayerDataManager.Save()` + `PlayerPrefs.GetInt/SetInt/GetString` (terlihat di disassembly `initBouns`); kunci `current_player_energy_`, `current_addenergy_time_`, `use_energy_state_` |
| Asset download | `DownLoadManager` (`DownLoadUri` statis) + `UINecessaryDataDownload` — unduhan data tambahan; **tidak ada URL server game** di metadata string table maupun assets (hanya URL library: Newtonsoft.Json, W3C, GitHub) |

### 3.1 Class kunci (Assembly-CSharp)

| Area | Class |
|---|---|
| Senjata | `Weapon`, `WeaponData`, `WeaponTableData`, `WeaponFactroy`, `WeaponOneShot`, `WeaponMoreShot`, `WeaponRechamber`, `WeaponIdle/Walk/In/Out/None`, `MotionBullet`, `ShotGunBullets`, `BulletsForces`, `RotationBullet`, `WeaponAudioData` |
| Hewan/AI | `Animal`, `AnimalData`, `AnimalFactroy`, `AnimalLoad`, `TargetNavigation`, `LookAtTarget`, `Navigation`, `Node`, `SkinnedCollisionHelper`, `BodyData` |
| Kamera/scope | `PlayerCamera`, `Sight`, `SightReticle`, `CameraShake`, `CameraPath`, `GameInSightUIControl`, `PlayerCamera` |
| Misi/level | `LevelManager`, `LevelData`, `MissionRequireManager`, `GameManger`, `GameInUIControl`, `GameInUIManager`, `GameEndControl`, `GamePreOverControl`, `ShowMissionManager`, `SpecialLevelManager` |
| Pemain | `Player`, `PlayerDataManager`, `PlayerXpData` |
| Ekonomi/toko | `UIShopMenu`, `UIShopWeaponShowMenu`, `UIWeaponUpgradeMenu`, `UIBuyCoinDialog`, `UIBuyCoins`, `GameBuyControl`, `UIGameInBuy`, `ImportUpdateManager` |
| Iklan | `VideoAdsControl`, `VideoAdsManager`, `VideoAdsMoneyControl`, `VideoAdsSpeedUpControl`, `VideoAdsSummonerControl`, `UIVideoRewardDialog` |
| Analitik | `GameManger` (string event `Flurry*`), `FlurrySend` |
| Java | `com.julian.wildhunter.WildHunter` (Activity), `UnityPlayerActivity`, `SharedPreferencesHelper`, `MyReceiver`, `OrientationFixActivity` |

### 3.2 Tembakan — rantai lokal, terverifikasi disassembly

`Weapon.Shoot` (RVA `0x5558b4`) dibaca penuh via capstone:

1. Cek state senjata (`Weapon.get_CurrentFSMState` — harus 4 atau 5).
2. **Kurangi peluru lokal**: `ldr r0,[r5,#0x50]` (= `Weapon.bulletsNum`, offset terkonfirmasi `0x50` di `dump.cs`), `sub #1`, simpan kembali.
3. `Animal.SettingBoundEnable`, ambil `PlayerCamera.get_ScreenCenter`, `Camera.ScreenPointToRay`, `Random.Range` + `Random.insideUnitCircle` (simulasi spread dari radius reticle), `Weapon.GetReticleRadius`.
4. **`UnityEngine.Physics.RaycastAll`** → `Weapon.SortRaycastHit` (RVA `0x5556ac`) → per hit: `RaycastHit.get_collider` → `GameObject.GetComponent<Animal>` → `Animal.DoMoreDetect` (RVA `0x5b2f88`) → bangun `Weapon.WeaponShotInfo` (animal + hitInfoList + damage) → **`Animal.NotifyHit`** (RVA `0x5b5a30`) → `Messager.OnWeaponEffect` → `AudioManager.PlaySound` → `Animal.ProcessingHit` (RVA `0x5b5fac`) → `Weapon.SetFlee`.
5. **Nol panggilan jaringan di seluruh rantai.** Damage, kill, bonus organ, dan flee hewan semuanya in-process.

Field penting (offset dari `dump.cs`, terverifikasi di disassembly):

| Field | Offset | Keterangan |
|---|---|---|
| `Weapon.bulletsNum` | `0x50` | Dikurangi 1 tiap `Shoot()` |
| `Weapon.mIsScope` | `0x4C` | Status scope aktif |
| `Weapon.mWeaponData` | `0x58` | Pointer `WeaponData` aktif |
| `Weapon.damge` | `0x94` | Damage senjata saat ini (typo asli: `damge`) |
| `WeaponData.maxRecoil` / `Shake` / `shock` | — | **Recoil ADA di game ini** (beda dari Sniper 3D yang tidak punya field recoil) |
| `WeaponData.magazineCapacity` | — | Kapasitas magasin |
| `WeaponData.minReticleRadius` / `maxReticleRadius` | — | Spread = radius reticle (membesar saat menembak/bergerak) |
| `WeaponData.rechamberTime` / `loadStartTime` / `loadLoopTime` / `loadEndTime` | — | Timer rechamber + reload |
| `WeaponData.shotStartTime` / `shotloopTime` / `shotEndTime` / `shotfireTime` | — | Timing tembakan |
| `Animal.HeadTransform` | `0x20` | Target bidikan kepala (aimbot) |
| `Animal.mCurrentHealth` / `mHealth` | `0xD8` / `0xDC` | Nyawa hewan (float) — bar HP ESP |
| `Animal.mAnimalData` | `0xC8` | Pointer `AnimalData` (nama, maxHealth, KillValue, kecepatan) |
| `Animal.Position` / `CenterPosition` | — | Posisi 3D (ESP) |
| `Sight.mZoomAmount` | `0x10` | Jumlah zoom scope |
| `Sight.mPower` / `mMinPower` / `mMaxPower` | `0x14` / `0x8` / `0xC` | Power scope (charge) |
| `Sight.mBatteryLifeTime` / `isUseBattery` | `0x20` / `0x30` | Scope thermal/night-vision menguras baterai |
| `PlayerCamera.mMainCamera` | `0xA0` | Kamera utama (proyeksi ESP) |
| `PlayerCamera.currentFov` | `0x240` | FOV saat ini |
| `PlayerCamera.mDefaultFov` / `mFov` / `mMinFov` / `mMaxFov` / `mFovMultiplier` | `0x2A4` / `0x2A8` / `0x2AC` / `0x2B0` / `0x2B4` | Batas + pengali FOV (zoom jauh = naikkan MaxFov/FovMultiplier) |

### 3.3 Hewan / AI

- `Animal : ListedUnity<Animal>` — **registry statis semua hewan di scene** (sumber enumerasi ESP ideal).
- `AnimalState`: Idle, Walk, Alert, Flee, Hit, Die, AttackRun, Attack, Bird_Fly, Bird_Die, Stun, Fish_Swim.
- `Animal.ShotInfo`: damage, bodyData, hitTime, isKilled, `killBouns`, hitResultList. `Animal.HitResult`: RegionName + HitInfo. `GetOrganBodyData(regionName)` — hit per organ; string bonus "Brain Bonus", "Heart Bonus", "Lung Bonus".
- `AnimalData.AnimalType` enum di kode hanya `{Bird, Deer}` — pembeda perilaku terbang vs darat. Spesies/nama/model/hewan lain bersifat data-driven dari asset bundle (1.261 file di `assets/bin/Data/`, nama ter-hash) — roster lengkap tidak dienumerasi dari kode.
- Hewan bisa menyerang pemain: `AttackPlayer`, `isAttack`/`isAttacking`, `attackChance`, `attackDistanceFromCamera`, `attackStartTime/EndTime`, `InitAttackPlayer`, `StartAttack`.
- UI game sendiri menggambar bar HP hewan (`AnimHealthOneSlider`, `AnimHealthTwoSlider`, `AnimTextBodyNameLabel`).

### 3.4 Scope / zoom

- `Weapon.IsScopeEnable`, `mIsScope`, anim `Telescope`, `Sight` + `SightReticle`, `GameInSightUIControl` (slider zoom + label).
- Zoom = matematika FOV client-side: `Sight.SetZoomAmount(float, bool)`, `PlayerCamera.CalcFovFromPower` / `SetFovFromPower` / `InitFovSetting(defaultFov, minFov, maxFov)`. Tidak ada validasi server atas FOV.

### 3.5 Misi / mode

- `LevelData.GameMode`: Wave_Mode, Hunt_Mode, Motion_Wave_Mode, Motion_Hunt_Mode (Motion = berburu dari kendaraan bergerak — sesuai deskripsi resmi).
- `LevelData.MissionMode`: RandomMode, LevelMode, SpecialMode, ChallengeMode.
- `LevelData`: target, goal, minSpwanCount, organName, requireTypeOne..Four (+value), levelTime, attackPlayerValue, bounsValue, playerValue, energyCost, regionIndex/regionCount, CurrentAnimalLevel, RandomAnimalDataName, isMustSpecilaRequire, isMagazineRequire/isTruckDamperRequire/isInfraredRequire/isTruckSpringRequire.
- Tidak ada mode PvP/multipemain: tidak ada class/method `Photon`, `Multiplayer`, `PvP`, `Leaderboard`, `Socket`, `UnityWebRequest` (game code), atau `GameCenter`/`GooglePlayGames` di seluruh dump. Catatan Uptodown yang menyebut "PVP" **tidak tercermin di kode**.

## 4. Anti-cheat & keamanan

| Item | Temuan |
|---|---|
| Play Integrity / SafetyNet / RootBeer / deteksi root | **Tidak ada** — tidak ada satu pun string/class-nya di dex maupun C# |
| "Attestation" | Hanya `gads:*_attestation*` milik Google Mobile Ads SDK (anti-fraud iklan, bukan anti-cheat game) |
| Validasi server atas gameplay | **Tidak ada** — tidak ada server game sama sekali |
| Proteksi lain | Tidak ada obfuscation nama (nama class/method/field utuh); `debugFreeIap` (static bool di `PlayerDataManager`, bersama `debugAutoRun`, `debugRandomLevel`) — sisa flag debug, default false. **Dicatat sebagai observasi saja; bukan jalur yang dipakai** (IAP gratis tetap ditolak, lihat AUDIT §2) |
| IAP | Unity IAP 4.11.0 + Google Play Billing (dex: `IInAppBillingService`); kunci publik RSA Play di `WildHunter.base64EncodedPublicKey` (verifikasi receipt client-side). 12 SKU (lihat §7) |

## 5. Mode misi — verifikasi klaim "full offline"

**TERBUKTI.** Seluruh loop gameplay berjalan lokal:
- Tembakan + damage + mati hewan: `Weapon.Shoot` → `Physics.RaycastAll` → `Animal.NotifyHit` (disassembly §3.2, nol network call).
- Hewan/AI: state machine lokal (`AnimalState`), navigasi lokal (`Navigation`, `Node`, `TargetNavigation`).
- Misi: requirement + goal + timer lokal (`LevelData`, `LevelManager`, `MissionRequireManager`).
- Energi: regen jam lokal (§6). Koin: save lokal (§7). Daily bonus: jam perangkat (§8).
- **Satu-satunya traffic jaringan adalah non-gameplay** (§6): iklan, analitik, IAP/Play Billing, unduhan data tambahan.

## 6. Verifikasi klaim "online cuma buat beli item"

**Hampir tepat — perlu koreksi kecil.** Online-nya bukan cuma IAP:

| Komponen online | Bukti | Pengaruh gameplay |
|---|---|---|
| IAP / Google Play Billing | Unity IAP 4.11.0 (`UnityServicesProjectConfiguration.json`); dex `IInAppBillingService`; 12 SKU `money_*`/`diamond_*`; string harga `$1.99`–`$99.99` BUY | Beli mata uang + item pakai uang asli |
| Iklan berhadiah | DoodleMobile mediation (`DoodleAds`, `DAdsConfig`), Unity Ads game id `1068499` placement `rewardedVideo`, AdMob (+ mediation adapter), Facebook Audience Network | Video iklan → `adsRewardMoney = 150` koin / `adsRewardGold = 2` diamond, maks `adsTimes = 6`/hari; `VideoAdsMoneyControl`, `VideoAdsSpeedUpControl`, `VideoAdsSummonerControl` |
| Analitik | Unity Analytics 6.0.3; Flurry (`FLURRY_ID`, `flurrySend`, string event `FlurryIap*`, `FlurryEnergy*`, `FlurryXP`, `FlurryRewardTitle`, dll.) | Telemetri saja |
| Unduhan data tambahan | `DownLoadManager` + `UINecessaryDataDownload` | Asset bundle tambahan; **nilai `DownLoadUri` tidak berhasil dipulihkan dari dump** (string disusun runtime) — bukan server gameplay |
| **Tidak ada** | Server game, sync progres, leaderboard, PvP, validasi tembakan | — |

Klaim user "online cuma buat beli item" **salah sebagian dengan cara yang sama seperti Sniper 3D** (bedanya: di sini tambahannya hanya iklan + analitik, bukan sync progres/energi/Arena — karena semua itu memang lokal).

### 6.1 "Daily bonus minta internet" (ulasan Play Store) — TERJAWAB

- Bonus 7-hari: `PlayerDataManager.initBouns` / `GetBounsCount` / `GetSevenDayReward` (RVA `0x63808c`) / `SaveSevenDayReward`; state di PlayerPrefs (`bonusCount`, `bonusTime`, konstanta `DAY = 864000000000L` tick/hari).
- `GetSevenDayReward` memanggil `GameManger.GetServerTime` (RVA `0x5fcc0c`) — **tapi "server time" itu ternyata jam perangkat**: `GetServerTime` memanggil method Java `WildHunter.getServerTime()`, yang hanya mengembalikan field `serverTime`, dan field itu diisi di `WildHunter.onCreate()` dengan `System.currentTimeMillis() / 1000`. **Tidak ada jaringan sama sekali.**
- Jadi bonus harian **tidak butuh internet**. Keluhan "minta internet" di ulasan hampir pasti soal **pengganda hadiah via video iklan** (iklan memang butuh internet) atau soal iklan yang muncul di alur bonus. Bonus dasarnya sendiri murni lokal — dan sebagai konsekuensi, mengubah jam perangkat akan menggeser bonus (kelemahan desain game, bukan sesuatu yang dibangun di sini).

## 7. Ekonomi — lokal vs server

**100% lokal, kecuali pembelian uang asli.**

| Item | Bukti |
|---|---|
| Mata uang | `coinsOne` (money) + `coinsTwo` (diamond); `AddCoinsOne`, `UseCoinsOne`, `GetCurrentCoinsOne`, `SaveCoinsOne` — semua lokal |
| Harga consumable | `summonerPrice = 10`, `batteryPrice = 800`, `drinkPrice = 2000` (koin) |
| Iklan → koin | `adsRewardMoney = 150`, `adsRewardGold = 2`, `adsTimes = 6` |
| IAP SKU (12) | `money_199/499/999/1999/4999/9999`, `diamond_199/499/999/1999/4999/9999` — harga `$1.99`–`$99.99` |
| Energi | `Max_Energy = 15`; `currentPlayerEnergy`; `LevelData.energyCost` per misi; `GetPlayerEnergy`, `UsePlayerEnergy` (RVA `0x63b6a4`), `AddEnergy`, `UpdatePlayerEnergy`, `GetEnergyFullTimes`, `isFullEnergy` — regen berbasis jam lokal |
| Upgrade senjata | `WeaponData.WeaponDataType`: Damage/Stability/Zoom/Capacity/Reload/Quality/Thermal/PreTime/Bump/Frequency upgrade; `WeaponTableData`, `ImportUpdateManager` (waktu impor + biaya koin) |
| Save | Lokal (PlayerPrefs-style, §3) — tidak ada upload save |

## 8. Penilaian file referensi ESP — `~/workspace/user/files/ESP_3_thnu.h`

Sama seperti `~/workspace/rea-sniper3d/REPORT.md` §8: file itu hanya sisi **rendering** (Canvas via JNI). Bisa dipakai, tapi yang harus dibangun:
- Enumerasi hewan: `Animal : ListedUnity<Animal>` (registry statis — sumber ideal).
- Posisi 3D: `Animal.Position` / `CenterPosition`; kepala: `Animal.HeadTransform` (`0x20`).
- Proyeksi 3D→layar: `PlayerCamera.mMainCamera` (`0xA0`) + `Camera.WorldToScreenPoint`.
- Bar HP: `Animal.mCurrentHealth` (`0xD8`) / `mHealth` (`0xDC`).
- Class `CanvasView` Java + `StructsCommon.h` (`Color`, `Vector2`, `Rect`) — tidak ada di file referensi, harus dibuat.
- Filter: hanya hewan hidup (`IsALive`), hanya di misi (game ini tidak punya mode online, jadi gate mode tidak diperlukan — lihat AUDIT §1.2).

## 9. Yang masih butuh probe runtime

- **Tidak ada yang bisa di-probe di POCO X6 Pro** — game tidak bisa install (32-bit only, §0.1). Probe runtime hanya mungkin di perangkat 32-bit / emulator.
- Nilai runtime yang belum terverifikasi (butuh perangkat 32-bit): nilai FOV default/min/maks aktual, `maxRecoil`/`Shake` per senjata, `magazineCapacity` per senjata, `energyCost` per misi, alamat runtime `ListedUnity<Animal>` (registry statis), nilai `DownLoadUri`.
- Badan method: Cpp2IL ISIL dump mati OOM 2×; badan yang dikutip di laporan ini berasal dari disassembly capstone atas alamat Il2CppDumper (metode yang sama bisa dipakai untuk method lain bila injector dibangun nanti).

## 10. File kerja

```
~/workspace/rea-wildhunter/
├── REPORT.md                  (file ini — SELESAI)
├── AUDIT-INJECTOR.md          (SELESAI — klasifikasi + desain payload)
├── disas.py                   (helper disassembly ARMv7 via capstone + anotasi BL dari script.json)
└── work/
    ├── wildhunter-1.0.16.xapk (66.627.308 B, SHA-256 terverifikasi)
    ├── xapk/                   (ekstrak: base APK + config.armeabi_v7a.apk + manifest.json + icon.png)
    ├── apk/                    (base APK terekstrak: dex ×5, assets, global-metadata.dat)
    ├── lib/lib/armeabi-v7a/    (libil2cpp.so, libunity.so, libmain.so)
    ├── cpp2il_out/            (44 DLL — dll_default)
    ├── cpp2il_ilrec/          (44 DLL — dll_il_recovery)
    ├── cpp2il_isil/           (parsial — ISIL mati OOM; tidak dipakai)
    ├── decompiled/            (ilspycmd atas dll_default — signature)
    ├── decompiled_ilrec/      (ilspycmd atas dll_il_recovery — signature)
    ├── il2cppdumper_out/      (dump.cs, script.json 41.051 method, stringliteral.json, il2cpp.h, DummyDll)
    ├── smali_out/             (apktool: smali semua dex — sisi Java)
    ├── retry_loop*.py/log      (arsip percobaan unduhan API yang gagal)
    └── *.html / *.apk         (arsip percobaan mirror)
```

**Catatan untuk parent:** perintah user 19:16 (push GitHub + publik + rilis otomatis) + koreksi 19:24 (pola hasil-dump, bukan repo REA terpisah) berlaku; tugas subagent ini "riset saja, JANGAN push" — keputusan push/publikasi/arsip diserahkan ke parent. **Rekomendasi dari temuan: karena game tidak jalan di POCO user, tanyakan dulu ke user apakah laporan + audit tetap mau diarsipkan ke hasil-dump, atau dibatalkan** (injector untuk HP-nya tidak ada gunanya).
