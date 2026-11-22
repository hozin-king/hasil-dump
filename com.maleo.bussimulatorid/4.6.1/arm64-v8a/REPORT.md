# REA + Audit — Bus Simulator Indonesia (BUSSID) 4.6.1

**Tanggal:** 14 Nov 2026
**Status:** Full dump + REA statis SELESAI. Injector TIDAK dibangun (sesuai perintah).
**Lokasi kerja:** `~/workspace/rea-bussid-461/`

---

## 1. Ringkasan eksekutif

- **Game ASLI, resmi Maleo.** Unity **2022.3.62f2** + IL2CPP (metadata v31.1), arm64-v8a.
- **KOREKSI PENTING — package name:** paket ASLI adalah **`com.maleo.bussimulatorid`**,
  BUKAN `com.maleo.bussimulatorindonesia` seperti tertulis di brief awal. Terbukti dari
  XAPK manifest + `aapt dump badging` + indeks APKPure (API mengembalikan
  `INVALID_COMMAND` untuk nama yang salah).
- **Ekonomi game ini SERVER-GATED via PlayFab** (akun, login, inventory, pembelian,
  stamina). Uang (`cash`) memakai `ObscuredInt` (CodeStage AntiCheatToolkit) DAN
  disinkronkan ke PlayFab UserData. Emas (`gold`) plain int tapi pembelian lewat
  backend PlayFab + IAP Play Store.
- **Yang murni LOKAL dan bisa dimod solo/offline:** perhitungan bahan bakar
  (`FuelController`), kecepatan/maxSpeed (`StableCar`/`StableCarSettings`),
  damage kendaraan lokal (`DamageManager`), parameter kendaraan.
- **Multiplayer NYATA dan besar:** Photon Fusion (`NetworkRunner`) + Photon Realtime
  (lobby/room) + daftar server via PlayFab — mode konvoi & balapan (BUSSID Online /
  BUSSIDOL). **Semua yang menyentuh multiplayer DITOLAK untuk injector.**
- **Assembly-CSharp.dll: ADA** (DummyDll lengkap, 132 file) — tapi isinya **stub
  tanpa isi method** (bukan DLL asli APK; kode asli ada di `libil2cpp.so`). Sudah
  didecompile dengan ILSpy: terbukti kosong.
- **Cpp2IL: BERHASIL dimuat (114.306 method terpetakan) tapi GAGAL memulihkan isi
  method** — 0 dari 2.118 method di Assembly-CSharp punya isi lebih dari
  `throw null`. Bukti angka ada di §5.2. REA ini bersandar pada struktur statis
  (signature, field, RVA) — bukan logika C# hasil recovery.

---

## 2. Identitas APK terverifikasi

| Item | Nilai |
|---|---|
| Package | `com.maleo.bussimulatorid` |
| versionName / versionCode | **4.6.1 / 2006547** |
| Developer | Maleo |
| Format | **XAPK** (bukan APK tunggal) — 11 split |
| Ukuran XAPK | **914.302.090 byte** (= metadata APKPure `s=914302090`) |
| SHA-1 XAPK | `89bb51043aff93cf98abecfadbaf604716261976` (cocok persis dengan metadata APKPure) |
| SHA-256 XAPK | `06bb07acca9e9b4c954cfd75275123e427d33a9771e0b3bc83e0b13164b89d36` |
| Base APK | `com.maleo.bussimulatorid.apk` 15.510.410 B, SHA-256 `7e5882aec59e9f8359d7943be9331f56253e7468a329ae4d4bdcc8c1a617792a` |
| Split native | `config.arm64_v8a.apk` 106.342.239 B, SHA-256 `36026e4aae1d2767f8680640166f2faa598d67b84f75ed9ba9cd5830262f35c9` |
| Split aset | `base_assets.apk` 489.053.016 B, `default.apk` 147.833.251 B, map packs `d_bali/d_jatim/d_jateng/d_kalimantan/d_sulawesi/d_sumatera` |
| minSdk / targetSdk / compileSdk | 24 / 36 / 36 (Android 16) |
| Main activity | `com.unity3d.player.UnityPlayerActivity` |
| `libil2cpp.so` (arm64) | 69.889.736 B, SHA-256 `dab544ff74478bbad70e93ecf18638b2a8fa34fbc757ced03e10354b64cb64e3` |
| `global-metadata.dat` | 14.918.512 B, SHA-256 `b2b16a9eebbf6fa3f42844a554cb7435f86717242cb5c4d197d51a82dc512efb` |

### 2.1 Sumber unduhan

- **Link user (APKMirror) GAGAL:** `apkmirror.com/.../download/?key=3324f18b…` → 403
  halaman Cloudflare "Just a moment..." untuk curl biasa maupun curl + header
  Chrome/Referer. Link ini TIDAK dipakai.
- **Fallback yang dipakai: APKPure API** (`api.pureapk.com/m/v3/cms/app_version`,
  GET `?hl=en-US&package_name=com.maleo.bussimulatorid`, header `x-sv: 29`,
  `x-abis: arm64-v8a,armeabi-v7a,armeabi`, `x-gp: 1`, TANPA `x-cv`).
  URL XAPK bertanda tangan tersimpan di `download_url.txt` (kedaluwarsa
  2026-11-16 14:13:30 UTC — berisi token, jangan disebar apa adanya).
- **Verifikasi:** ukuran unduhan 914.302.090 B + SHA-1 `89bb5104…` cocok persis
  dengan metadata API; `aapt dump badging` memastikan package + versi.
- Jalur lain yang dicoba dan gagal: `d.apkpure.com` (403 Cloudflare),
  Aptoide API v7 (BUSSID tidak terindeks), mirror winudf (tidak ada untuk 4.6.1).

---

## 3. Arsitektur hasil dump

| Item | Nilai |
|---|---|
| Engine | Unity **2022.3.62f2** (dari `globalgamemanagers` + `libunity.so`) |
| IL2CPP | Metadata version **31.1**, Il2Cpp version 31 |
| CodeRegistration / MetadataRegistration | `0x3D8DE90` / `0x3EB2660` (Il2CppDumper & Cpp2IL sepakat) |
| `dump.cs` | 30.381.831 B, 18.129 namespace, 15.628 class/struct |
| `script.json` | 76.247.428 B — 176.456 method, 22.211 string, 27.949 metadata-method |
| `stringliteral.json` | 1.832.257 B |
| `il2cpp.h` | 67.065.953 B |
| `DummyDll/` | **132 file** (lihat §5.1) |
| Assembly game utama | `Maleo.Game.dll` (1.733 tipe), `Maleo.CarSimulator.dll` (3.701 tipe), `Assembly-CSharp.dll` |

Tidak ada `Assembly-CSharp-firstpass.dll` — kode game terbagi ke tiga assembly di
atas (pola Assembly Definition Files Unity).

---

## 4. Sistem game — peta audit

### 4.1 Mata uang: `cash` + `gold`

- `BusSimulator.Core.Player : IPlayerData<Player>` (`Maleo.Game.dll`):
  ```csharp
  public ObscuredInt cash;      // 0x18 — CodeStage AntiCheatToolkit
  public int gold;              // 0x2C — plain int
  private int _stamina;         // 0x30
  public string selectedBusID;  // 0x50
  public List<ItemInstance> inventory; // 0x68 — PlayFab.ClientModels.ItemInstance
  ```
- `CurrencyType` enum: `cash = 0`, `gold = 1`. `Reward { CurrencyType type; int value; }`.
- **Sinkronisasi server:** `Player` mengimplementasi
  `IPlayerData<Player>.ConvertFromDictionary(Dictionary<string, UserDataRecord>)`
  — `UserDataRecord` adalah model **PlayFab**. `BackendEvent.LoadPlayerData`
  + `BackendListener` memuatnya. `PlayerDataKeys`: `facebookData`,
  `lastConnectedDeviceID`, `achievementProgress`, `gameplayStat`,
  `claimedAchievement`, `assetPurchasedList`.
- **Pembelian lewat backend:** `BackendEvent.PurchaseItem` (ctor
  `PurchaseModel item, Action<PurchaseItemResult> onComplete, Action<PlayFabError> onError`,
  ada varian diskon) → `BackendListener.PurchaseItem`.
- **Login/akun = PlayFab penuh:** `Account : MonoBehaviour` menyimpan
  `playfabSessionTicket` (0x48) + `playfabId` (0x50) + data login FB/Google;
  SDK PlayFab mengekspos `LoginWithAndroidDeviceID`, `LoginWithCustomID`,
  `LoginWithFacebook`, `LoginWithGooglePlayGamesServices`, `LoginWithEmailAddress`.
- **IAP:** Unity Purchasing (`CodelessIAPAutoLog`, `IAPReadyResult`) — gold dijual
  via IAP Play Store. AdMob (`GoogleMobileAds.*`) untuk iklan.
- **Klasifikasi: SERVER-GATED.** Cash di-obscure DAN disinkronkan ke PlayFab;
  pembelian & inventory lewat backend. Menulis `cash`/`gold` dari memori akan
  desync saat sinkronisasi berikutnya (dan `cash` ObscuredInt punya checksum
  internal — tulis mentah = terdeteksi/terkoreksi). **DITOLAK untuk injector.**

### 4.2 Bahan bakar

- `FuelController : MonoBehaviour` (ns global, `Maleo.CarSimulator.dll`):
  - `CalculateFuel(float speed)` — RVA **0x2D10C5C**
  - `UpdateFuel(float value)` — RVA **0x2D10D28**
  - `SetFuel(float value)` — RVA **0x2D10DF4**
  - `StartFuelCalculation()` — RVA **0x2D10EC0**, `StopFuelCalculation()` — RVA **0x2D10F7C**
  - `Initialize(FuelInitializeParameters)` — RVA 0x2D10B78
  - Singleton statis + `IFuelControllerBridge bridge` (implementasi default:
    `DefaultFuelControllerBridge`, `get_FuelLevel` RVA 0x2D10A8C).
- `Fuel { string id; float price; }` — katalog jenis BBM + harga.
- `BuyFuel : GameEvent { fuelId, currentFuelAmount, fuelAmount, bool useMoney,
  OnComplete(JsonDatabase.BuyFuelReturnData) }` — pembelian BBM mengembalikan
  data dari backend. `JsonDatabase.FuelData` / `BuyFuelReturnData`.
- `FuelRunOut`, `PayFuel`, `MoneyExchangeEmptyFuel`, `BackendEvent.ResetUserFuel`.
- **Klasifikasi: CAMPURAN.**
  - **LOKAL:** level BBM saat mengemudi dihitung lokal dari kecepatan
    (`CalculateFuel(speed)` + bridge `FuelLevel`). Hook `SetFuel`/`UpdateFuel`
    atau NOP-kan `CalculateFuel` = "BBM tak habis" saat solo — layak diusulkan.
  - **SERVER-GATED:** pembelian BBM (`BuyFuel` → `BuyFuelReturnData` backend)
    dan tukar stamina→BBM (`StaminaExchangeToFuel(Action<bool>, Action<PlayFabError>)`).
    **DITOLAK.**

### 4.3 Stamina

- `Player._stamina` + properti `Stamina`, `LastStaminaUpdated`,
  `SecondsToRecharge`, `MaxStaminaRecharge`, `StaminaRechargeRate`
  (`get_Stamina` RVA 0x2F0ECC8).
- `BackendEvent.GetAvailableStamina`, `BackendEvent.StaminaBonusReward`,
  `TimeTokenBackend.StaminaBonusReward(Action<TimeTokenBackend.ReturnData>,
  Action<PlayFabError>)` — semua lewat backend PlayFab (CloudScript/time-token).
- **Klasifikasi: SERVER-GATED. DITOLAK.**

### 4.4 XP / level pemain

- **Tidak ditemukan class level/XP pemain.** Yang ada hanya util
  `LevelExperience(int level, int experiencePerStep)` (konteks util di
  `dump.cs`), key `PlayerDataKeys.GameplayStat`, `JsonDatabase.GameplayState`,
  dan `achievementProgress`/`claimedAchievement`.
- **Klasifikasi: BELUM KETEMU — perlu REA lanjutan.** Jangan klaim ada sistem
  level yang bisa dimod sebelum class-nya ditemukan.

### 4.5 Bus, unlock, inventaris

- `Player.inventory` = `List<PlayFab.ClientModels.ItemInstance>` — inventaris
  (termasuk bus) hidup di **PlayFab** (`ItemId`, `ItemInstanceId`, `UnitPrice`,
  `PurchaseDate`, `CatalogVersion`).
- `Player.selectedBusID` (0x50) + `selectedBusDriverID` (0x58).
- `BusSelectionSubMenu : GarageSubMenu`, `BusAccessoriesPurchase` /
  `BusAccessoriesPurchasedSuccessfull` (GameEvent), `DiscountKeyManager`
  (`bus_discount`, `busAccessory_discount`, `driver_discount`).
- `VehicleData.Load(string filePath)` / `Load(byte[])` — data kendaraan (part,
  material, livery) dimuat dari file — sistem mod/livery resmi.
- `LiveryManager` — livery pemain di-cache lokal (`playerCachedLivery`,
  `playerCachedLiveryKey`).
- **Klasifikasi: SERVER-GATED** (unlock/pembelian bus & item via PlayFab
  inventory + `AssetPurchasedList`). **DITOLAK.** Yang lokal hanya file data
  kendaraan/livery (mod kosmetik resmi — bukan unlock).

### 4.6 Rute / trayek / karir

- `CareerMode : GameModeBUSSID` (ns `BUSSID`, RVA awal 0x1AD93B8):
  `IsPayFuelExchange()`, `IsPayToll()`, `IsPayBuyFuel()`, `IsPayCrane()`,
  `CalculateRouteSegmentDistance(string from, string to)` RVA 0x1AD9E68,
  `CalculateFullRouteDistance()` RVA 0x1ADA5F4, `StartGameLocally()`,
  `LoadGameplayState()` / `SaveState()`.
- `RouteDetailMenu`, `RouteScrollView`, `RouteSceneLoader` (+ varian Game/Mod),
  `RouteScenePortal`, `RouteLengthData`.
- `TripDetail { sourceCity, destinationCity, routePassed, routeCompleted }`,
  `TripRecord { destinationCity, totalPassengersDropped, totalFares }`,
  `PassengerInfo { id, departureCity, destinationCity, myValue, seatPos }`.
- `FarePaymentSimple : GameEvent { ObscuredInt earning; string careerToken;
  string gameModeId; }` — pembayaran ongkos penumpang memakai **careerToken**
  (sesi karir server) dan `earning` ObscuredInt.
- **Klasifikasi: CAMPURAN.**
  - **LOKAL:** rute, jarak, penumpang, simulasi perjalanan (semua dihitung lokal).
  - **SERVER-GATED:** pembayaran ongkos (`FarePaymentSimple` + `careerToken`) —
    hasil trip yang masuk ke `cash`/`gold` lewat backend. **DITOLAK** (menaikkan
    `earning` = memengaruhi ekonomi server).

### 4.7 Multiplayer / online (BUSSID Online — BUSSIDOL)

- `NetworkManager : MonoBehaviour, INetworkRunnerCallbacks` (ns global, RVA awal
  0x2E5399C): `NetworkRunner Runner`, `IsConnectedToTheRoom`,
  `IsMasterClient`, `ConnectPhotonBestServer()` RVA 0x2E545E0,
  `ConnectToTheLastSelectedServer()` RVA 0x2E54544, `Shutdown()`.
  Prefab: `NetworkRPCManager`, `NetworkTimeAndWeather`, `ConvoyProperties`.
  Konstanta `PHOTON_ROOM_NAME`, `PHOTON_REGION`.
- `MultiplayerMode : GameModeGame`, `MultiplayerLobby`,
  `MultiplayerRoomListMenu`, `MultiplayerCreateRoomMenu`, `MultiplayerRoomMenu`,
  `MultiplayerServerLogin`, `MultiplayerGameModeSelection`,
  `MultiplayerConfig`, `MultiplayerConvoyConfig`, `MultiplayerRaceConfig`,
  `MultiplayerLodgerConfig`, `BUSSIDOLRoomButton`, `BUSSIDOLImage`,
  `OnlinePlayerCountText`, `MultiplayerRaceSceneItem`,
  `MultiplayerStartPointsPart`, `MultiplayerTerminalPortal`,
  `MultiplayerRaceLapTrigger`, `MultiplayerServerSummary : PlayFabBaseModel`
  (daftar server via PlayFab).
- `NetworkVehicleController : NetworkBehaviour` (Fusion) — kendaraan pemain lain
  direplikasi via Fusion; `StableCar.isNetworkOpponent` (0xA1).
- `DamageManager.InitMultiplayerVehicle(...)` — damage multiplayer-aware.
- SDK yang ter-link: **Photon Fusion** (`Fusion.Runtime/Realtime/Common/Sockets`),
  **Photon Realtime + Photon Chat**, **PlayFab**.
- **Klasifikasi: SERVER-GATED PENUH. DITOLAK TOTAL untuk injector** — semua yang
  terlihat pemain lain (posisi, kecepatan, bus, livery, damage, skor balapan,
  konvoi) tidak boleh disentuh. Injector WAJIB nonaktif saat
  `NetworkManager.IsConnectedToTheRoom` (fail-closed; cek tiap tick dari hook,
  bukan sekali di awal).

### 4.8 Kendaraan & fisika (target mod lokal)

- `StableCarBUSSIDController : CarController` (ns global, RVA awal 0x2D303D4):
  membungkus `StableCar car` (0x50). Method kunci:
  - `SpeedKMH()` — RVA **0x2D30F2C**; `SpeedMPS()` — 0x2D30F48
  - `SetMaxSpeedForward(float speedKMH)` — RVA **0x2D30F80**
  - `SetGearboxRatio(float)` — 0x2D30F64; `SetVelocity(Vector3)` — 0x2D30DBC
  - `TeleportTo(Vector3, Quaternion)` — 0x2D307C4
  - `set_throttleInput(float)` — 0x2D303F0, `set_brakeInput` — 0x2D3040C,
    `set_steerInput` — 0x2D30460, `set_handbrakeInput` — 0x2D30498
- `StableCar : MonoBehaviour` (ns global, RVA awal 0x2D3256C) — fisika inti:
  - `maxSpeed` float **0x64**, `gearboxRatio` 0x68, `maxSpeedBrokenEngine` 0x6C
  - `speed` 0xBC, `speedMPS` 0xC0, `displaySpeed` 0xE8, `displayMaxSpeed` 0xEC
  - `settings` (`StableCarSettings`) 0x48, `body` (Rigidbody) 0x28,
    `isNetworkOpponent` 0xA1, `controlByPlayer` 0xC4
- `StableCarSettings` (ns global): `accForce` 0x5C, **`maxSpeed` 0x68**,
  `brakeForce` 0x78, `maxBrakeSpeed` 0x7C, `dragBraking` 0x88, `shiftUp` 0x20,
  `extraForceUpHill` 0x64.
- `VehicleParameters : VehiclePart` (ns global): `mass`, `tireFriction`,
  `antiRoll`, `maxSteerAngle`, `rollingResistance`, `maxDriveSlip`,
  `maxSpeedReverse`, `maxBrakeForce`, traksi/rem/kemudi assist.
- `CarController` (base): properti `throttleInput`/`brakeInput`/
  `handbrakeInput`/`steerInput` — input kemudi bisa ditulis hook-side.
- **Klasifikasi: LOKAL.** Fisika dihitung di perangkat; `SetMaxSpeedForward`
  + field `StableCar.maxSpeed` adalah analog langsung "pengali speed" TR.
  **Layak diusulkan (solo/offline saja).**

### 4.9 Damage kendaraan

- `DamageManager` (ns `BusSimulator.Modules.DamageAndDirtSystem`):
  - `InitLocalPlayerVehicle(GameObject, string)` — RVA 0x2CEB9CC
  - `IsVehicleHalfDamaged(GameObject, bool isMultiplayer=false)` — RVA **0x2CEF1F0**
  - `IsVehicleHeavyDamaged(GameObject, bool isMultiplayer=false)` — RVA **0x2CEF2F4**
  - `ResetData()` — RVA 0x2CEF0DC; `isRepairing` (statis)
  - `DamageData`, `DamagePivot`, `CustomDamagePivot`, `DamageIndicator`,
    event `VehicleDamageUpdated`, `DamageAndDirtInitialized`.
  - `NoDamageRun : MilestoneBasedChallenge` (tantangan tanpa damage).
- **Klasifikasi: LOKAL (solo).** Analog "god mode" TR: hook
  `IsVehicleHeavyDamaged` → return false saat ON (atau hook pemicu damage).
  WAJIB gate solo-only (`isMultiplayer=false` path saja; di room multiplayer
  hook nonaktif). **Layak diusulkan dengan gate tersebut.**

### 4.10 Anti-cheat / proteksi

- **CodeStage AntiCheatToolkit (Obscured Types) — TERBUKTI DIPAKAI:**
  `ObscuredInt` untuk `Player.cash`, skor, `FarePaymentSimple.earning`,
  lap balapan, jumlah pemain; `ObscuredFloat` untuk `currentTime`, `_lastFuel`.
  Struct terdefinisi di `il2cpp.h` sebagai
  `CodeStage_AntiCheat_ObscuredTypes_ObscuredInt`.
- **Detector (SpeedHackDetector / ObscuredCheatingDetector / InjectionDetector):
  TIDAK DITEMUKAN di dump** — tidak ada class detector di `dump.cs` maupun di
  `DummyDll/`. Bukan bukti tidak ada (bisa di-strip atau di assembly lain),
  tapi tidak ada jejak statisnya. Jangan klaim ada/tidak ada secara mutlak.
- `LocalUserData : ScriptableObject` — penyimpanan lokal per-perangkat
  (`SetUserDataToDevice`, `HasUserDataOnDevice`, `SyncMissingUserDataFromDevice`)
  — sebagian data disimpan lokal lalu disinkronkan; tetap di bawah payung
  PlayFab untuk data pemain.
- `BussidAPI : MonoBehaviour` — REST API milik Maleo sendiri (`Upload`, `Get`,
  `Hit`, `Touch`, `Delete`, `get_Environment`) — dipakai untuk livery/komunitas.
  Endpoint tidak ditemukan di string literal biner (kemungkinan dari config
  aset / Firebase RemoteConfig).

### 4.11 Tabel klasifikasi (ringkas)

| Fitur | Bukti | Klasifikasi | Injector? |
|---|---|---|---|
| Uang `cash` | `Player.cash` ObscuredInt 0x18 + sync PlayFab UserData | SERVER-GATED | ❌ DITOLAK |
| Emas `gold` | `Player.gold` int 0x2C, beli via PlayFab + IAP | SERVER-GATED | ❌ DITOLAK |
| Stamina | `TimeTokenBackend` + `PlayFabError` callback | SERVER-GATED | ❌ DITOLAK |
| Beli BBM | `BuyFuel` → `BuyFuelReturnData` backend | SERVER-GATED | ❌ DITOLAK |
| Tukar stamina→BBM | `StaminaExchangeToFuel` PlayFab | SERVER-GATED | ❌ DITOLAK |
| Ongkos trip (`earning`) | `FarePaymentSimple` ObscuredInt + `careerToken` | SERVER-GATED | ❌ DITOLAK |
| Unlock bus / inventaris | `inventory` = PlayFab `ItemInstance` | SERVER-GATED | ❌ DITOLAK |
| XP / level pemain | class tidak ketemu | BELUM KETEMU | ❌ (tunggu REA lanjutan) |
| Multiplayer (konvoi/balap/lobby) | Photon Fusion + Realtime + PlayFab | SERVER-GATED | ❌ DITOLAK TOTAL |
| Level BBM saat nyetir | `FuelController.CalculateFuel/UpdateFuel/SetFuel` lokal | LOKAL | ✅ diusulkan (solo) |
| Kecepatan / maxSpeed | `StableCar.maxSpeed` 0x64, `SetMaxSpeedForward` 0x2D30F80 | LOKAL | ✅ diusulkan (solo) |
| Damage kendaraan | `DamageManager.IsVehicleHeavyDamaged` 0x2CEF2F4 | LOKAL (solo) | ✅ diusulkan (solo, gate MP) |
| Parameter kendaraan | `VehicleParameters`, `StableCarSettings` | LOKAL | ✅ diusulkan (solo) |
| Rute / jarak / penumpang | `CareerMode`, `TripDetail`, `RouteSceneLoader` | LOKAL (simulasi) | ✅ baca saja / info |

---

## 5. Assembly-CSharp.dll — penjelasan + hasil decompile

### 5.1 DummyDll Il2CppDumper: LENGKAP, tapi stub

`dump/DummyDll/` berisi **132 file**, termasuk yang diminta user:
- `Assembly-CSharp.dll` — 482.304 B, SHA-256
  `cb02babb4fdae3547abb80938a0919f2dcfd3d41b5aaa92376821181eb362f9c`
- `Maleo.Game.dll` — 2.703.872 B, SHA-256
  `7a29b925b82aa12712324028f2683b8c660d69b98aad38f6db63f06347510521`
- `Maleo.CarSimulator.dll` — 2.319.360 B, SHA-256
  `64a9aefce1e3c2b8a3ebee7d6602c9959be18bb91e8be96658d657d4b5075d09`
- Plus: `Fusion.*`, `PhotonRealtime`, `Photon3Unity3D`, `PhotonChat`,
  `PlayFab.dll`, `Firebase.*`, `GoogleMobileAds.*`, `Google.Play.Games.dll`,
  `Facebook.Unity.dll`, `DOTween.dll`, `FMODUnity.dll`, `Newtonsoft.Json.dll`.
- **Tidak ada `Assembly-CSharp-firstpass.dll`** (normal untuk proyek ini).

**Penjelasan untuk user:** di game IL2CPP, file `Assembly-CSharp.dll` ini
**BUKAN DLL asli dari APK** — APK tidak mengandung DLL .NET sama sekali (kode
C# sudah dikompilasi ke native `libil2cpp.so`). File ini adalah **dummy hasil
Il2CppDumper**: struktur class/method/field + RVA, tanpa IL beneran. Gunanya
untuk navigasi struktur & referensi RVA, bukan untuk membaca logika.

### 5.2 Decompile ILSpy (DummyDll) — terbukti stub

- `decompiled/Assembly-CSharp/Assembly-CSharp.decompiled.cs` — 18.843 baris.
- `decompiled/Maleo.Game/Maleo.Game.decompiled.cs` — 108.623 baris.
- `decompiled/Maleo.CarSimulator/Maleo.CarSimulator.decompiled.cs` — 96.711 baris.
- Semua method body **kosong** (`{ }`) — hanya signature + atribut
  `[Address(RVA=...)]`. Contoh: `FuelController.CalculateFuel` → body kosong.
- Tool: `ilspycmd` 8.2.0.7535 (instal via `dotnet tool install -g ilspycmd
  --version 8.2.0.7535`; butuh `DOTNET_ROLL_FORWARD=LatestMajor` karena runtime
  net6.0 tidak terpasang; shim `ilspycmd` gagal `libhostfxr.so` — jalankan DLL
  langsung: `~/dotnet/dotnet ~/.dotnet/tools/.store/ilspycmd/8.2.0.7535/ilspycmd/8.2.0.7535/tools/net6.0/any/ilspycmd.dll`).

### 5.3 Cpp2IL — berhasil dimuat, GAGAL memulihkan isi method

Percobaan sesuai permintaan user (Cpp2IL dari `libil2cpp.so` +
`global-metadata.dat`):

- Tool: **Cpp2IL 2022.1.0-pre-release.21** (unduh dari GitHub releases
  SamboyCoding/Cpp2IL; tersimpan di `tools/Cpp2IL-Linux`).
- Perintah yang akhirnya jalan (force options butuh **tiga** nilai — binary,
  metadata, **dan versi Unity**; tanpa `--force-unity-version` selalu gagal
  `Invalid force option configuration`):
  ```
  ./tools/Cpp2IL-Linux \
    --force-binary-path cpp2il_in/libil2cpp.so \
    --force-metadata-path cpp2il_in/global-metadata.dat \
    --force-unity-version 2022.3.62f2 \
    --output-as dll_il_recovery --output-to cpp2il_out
  ```
- Hasil pemuatan: metadata v31.1, codereg `0x3D8DE90`, metareg `0x3EB2660`,
  **114.306 method terpetakan** — pemuatan BERHASIL.
- Hasil recovery: **GAGAL total.** Bukti (diukur dari IL hasil `ilspycmd -il`
  atas `cpp2il_out/Assembly-CSharp.dll`):
  - 2.118 method total; **2.001 method berisi tepat 2 instruksi IL**
    (`ldnull; throw` = stub `throw null`); 117 method berisi 0 instruksi;
    **0 method berisi >2 instruksi IL.**
  - `decompiled/cpp2il/` (172.495 baris dari 3 assembly utama) tidak mengandung
    satu pun statement `if (` / `for (` — semua body `throw null`.
- **Kesimpulan jujur:** Cpp2IL **tidak berhasil memberi isi method beneran**
  untuk biner ARM64 Unity 2022.3.62 ini (kemungkinan keterbatasan IL recovery
  Cpp2IL di ARM64 / biner ini). Satu-satunya jalan ke logika asli adalah
  analisis native ARM64 di `libil2cpp.so` (disassembly per-RVA) atau observasi
  runtime di perangkat — keduanya di luar cakupan REA statis ini.
- File hasil tetap disimpan: `cpp2il_out/` (DLL hasil recovery, 8,2 MB) +
  `decompiled/cpp2il/` (hasil ILSpy atas DLL tersebut).

---

## 6. Usulan injector berbasis kerangka Traffic Rider v2.4

Kerangka acuan: `~/workspace/hozin-trafficrider-v13/` (HEAD remote `2932de7`,
v2.4/code 16). Arsitektur TR: `payload.cpp` (~2.300 baris) + `il2cpp_resolve`
+ `patterns.h` (fallback) + `injector.c` (ptrace dlopen) + `ModInjector.java`
+ `OverlayService` + `WatchService` + workflow `android.yml`
(assembleDebug + auto-release `gh release upload --clobber`).

### 6.1 Yang dipakai APA ADANYA (tanpa ubah logika)

| Komponen TR | Status untuk BUSSID |
|---|---|
| `il2cpp_resolve.{h,cpp}` (resolusi nama via export C API libil2cpp) | **Pakai apa adanya.** BUSSID memakai libil2cpp standar; resolver sudah iterasi SEMUA assembly + fallback namespace `""` — cocok karena class BUSSID tersebar di `Maleo.Game.dll`, `Maleo.CarSimulator.dll`, `Assembly-CSharp.dll` dengan namespace global / `BusSimulator.Core` / `BUSSID`. |
| `injector.c` (ptrace dlopen) | **Pakai apa adanya.** Mekanisme inject generik (staging `.so` di `/data/local/tmp` agar bisa dibaca UID game — SELinux). |
| `ModInjector.java` (staging + 3× dlopen + probe) | **Pakai apa adanya**, ganti nama file/paket target + path JSON (`tr_mod_*` → `bussid_mod_*`). |
| `WatchService` (poll `pidof`, auto-inject) | **Pakai apa adanya**, ganti paket target `com.maleo.bussimulatorid`. |
| `OverlayService` + `EspOverlayView` | **Pakai polanya** (poll status JSON 1 dtk via satu `su`); isi panel diganti diagnosis BUSSID. ESP kendaraan multiplayer **DITOLAK** — overlay hanya status + toggle solo. |
| Workflow `android.yml` (assembleDebug + auto-release) | **Pakai apa adanya**, ganti nama APK/tag. |
| Pola fail-closed per-situs + status JSON | **Pakai apa adanya** (hook/patch yang gagal resolve = "gagal", bukan crash). |
| Dobby (hook) | **Pakai apa adanya** (sudah dipakai TR v2.4). |

### 6.2 Yang tinggal ganti target (nama + RVA bukti)

Semua alamat di bawah dari `dump.cs` (RVA = offset dari base `libil2cpp.so`).
Resolver nama adalah jalur utama; RVA hanya fallback/pembanding — JANGAN
hardcode RVA sebagai satu-satunya jalan (pelajaran TR v1.9→v2.0).

| Target BUSSID | Namespace / Assembly | RVA (bukti statis) | Peran di injector |
|---|---|---|---|
| `FuelController.CalculateFuel(float)` | `""` / Maleo.CarSimulator | **0x2D10C5C** | Hook → return langsung saat "BBM tak habis" ON (hentikan pengurangan BBM) |
| `FuelController.SetFuel(float)` | `""` / Maleo.CarSimulator | **0x2D10DF4** | Alternatif: panggil berkala dengan nilai penuh (perlu verifikasi runtime — lihat §6.4) |
| `FuelController.UpdateFuel(float)` | `""` / Maleo.CarSimulator | **0x2D10D28** | Sama seperti di atas |
| `DefaultFuelControllerBridge.get_FuelLevel` | `""` / Maleo.CarSimulator | **0x2D10A8C** | Baca level BBM untuk diagnosis (read-only) |
| `StableCarBUSSIDController.SetMaxSpeedForward(float)` | `""` / Maleo.CarSimulator | **0x2D30F80** | Tulis maxSpeed baru (pengali kecepatan ala TR v2.3) |
| `StableCarBUSSIDController.SpeedKMH()` | `""` / Maleo.CarSimulator | **0x2D30F2C** | Baca kecepatan untuk diagnosis |
| `StableCar.maxSpeed` (field float) | `""` / Maleo.CarSimulator | offset **0x64** | Tulis langsung via `il2cpp_find_field` (fallback bila hook setter gagal) |
| `StableCar.speed` (field float) | `""` / Maleo.CarSimulator | offset **0xBC** | Baca kecepatan (diagnosis) |
| `StableCarSettings.maxSpeed` (field float) | `""` / Maleo.CarSimulator | offset **0x68** | Tulis maxSpeed per-bus (alternatif setter) |
| `DamageManager.IsVehicleHeavyDamaged` | `BusSimulator.Modules.DamageAndDirtSystem` / Maleo.Game | **0x2CEF1F0** | Hook → return false saat "anti-damage" ON (analog god mode TR; solo-only) |
| `DamageManager.IsVehicleHalfDamaged` | sama | **0x2CEF2F4** | Sama |
| `NetworkManager.IsConnectedToTheRoom` (property) | `""` / Maleo.Game | — (resolve nama) | **Gate wajib:** semua hook gameplay nonaktif bila true |
| `Player.cash` / `Player.gold` | `BusSimulator.Core` / Maleo.Game | offset 0x18 / 0x2C | **HANYA BACA untuk diagnosis; JANGAN ditulis** (server-gated, §4.1) |

### 6.3 Fitur yang diusulkan (solo/offline SAJA, default MATI)

1. **BBM tak habis** — hook `FuelController.CalculateFuel` → return saat ON.
   Bukti lokal: perhitungan BBM lokal dari kecepatan (§4.2).
2. **Pengali kecepatan / maxSpeed** — hook `SetMaxSpeedForward` atau tulis
   `StableCar.maxSpeed` (0x64) = pengali × maxSpeed natural bus; lepas gas =
   natural. Analog torsi instan TR v2.3, tapi di sini via setter resmi.
   Bukti lokal: `StableCar.maxSpeed` + `StableCarSettings.maxSpeed` (§4.8).
3. **Anti-damage (god mode lokal)** — hook `IsVehicleHeavyDamaged` /
   `IsVehicleHalfDamaged` → false saat ON. Bukti lokal: `DamageManager` (§4.9).
4. **Diagnosis** — status JSON: fuel level (`get_FuelLevel`), kecepatan
   (`SpeedKMH`), maxSpeed aktif, mode game (`GameMode.Current` /
   `NetworkManager.IsConnectedToTheRoom`), `cash`/`gold` **read-only** tampil
   saja (bukan target tulis).
5. **TIDAK ADA fitur uang/emas/stamina/beli BBM/unlock bus/multiplayer.**
   Daftar penolakan lengkap di tabel §4.11.

### 6.4 Yang masih butuh verifikasi runtime (TIDAK boleh diasumsikan)

- Apakah `FuelController.CalculateFuel` benar-benar satu-satunya jalan
  pengurangan BBM saat mengemudi (atau ada jalur kedua via bridge/event)?
  Cpp2IL gagal memberi isi method — butuh observasi runtime / disassembly
  ARM64 di RVA 0x2D10C5C.
- Apakah menulis `StableCar.maxSpeed` (0x64) bertahan (tidak ditimpa tiap
  frame oleh `StableCarSettings` / `SetMaxSpeedForward`)?
- Apakah `DamageManager` dipakai sebagai satu-satunya penentu "rusak berat"
  (atau ada cek kedua di `VehicleDamageUpdated` / UI)?
- Apakah `NetworkManager.IsConnectedToTheRoom` cukup sebagai gate (atau ada
  mode hybrid: solo tapi tetap login PlayFab — hook tetap aman karena hanya
  memengaruhi simulasi lokal, BUKAN nilai yang dikirim ke server; perlu
  dipastikan tidak ada nilai hasil hook yang ikut terkirim saat sinkronisasi
  trip — `FarePaymentSimple` memakai `earning` dari simulasi; **risiko:
  bila pengali kecepatan memperbesar `earning`, itu menyentuh ekonomi server —
  maka fitur kecepatan WAJIB dimatikan otomatis sebelum trip berakhir /
  sebelum `FarePaymentSimple` dipanggil, atau dibatasi ke mode non-karir
  (Free Mode / `GameModeBUSSID` non-career)**.
- Versi game di perangkat user harus dicek ulang sebelum build (pelajaran TR:
  game auto-update → pola/RVA pindah; resolver nama menahan ini, tapi field
  offset tetap perlu verifikasi).

### 6.5 Perbedaan arsitektur TR vs BUSSID (yang harus diadaptasi)

- TR: satu assembly game (`Assembly-CSharp.dll`) + class global. BUSSID: tiga
  assembly game + namespace campuran — resolver TR sudah menanganinya (iterasi
  semua assembly), tapi pemetaan nama di `patterns.h` (fallback) harus ditulis
  per-assembly.
- TR: game 100% offline. BUSSID: hybrid (login PlayFab wajib untuk sebagian
  mode) — **gate multiplayer + gate akhir-trip** adalah komponen BARU yang
  tidak ada di TR.
- TR: `MotorMover.Crash()` satu pintu mati. BUSSID: damage berlapis
  (`DamageManager` + event + tantangan `NoDamageRun`) — hook harus di titik
  yang tepat, bukan asal NOP.
- TR: skor lokal. BUSSID: `earning` ObscuredInt + `careerToken` server —
  **tidak ada analog "skor" yang boleh disentuh**.

---

## 7. Kesiapan arsip hasil-dump

**SIAP, dengan catatan.** Struktur yang diusulkan (mengikuti preseden TR v2.20):

```
dump/com.maleo.bussimulatorid/4.6.1/arm64-v8a/
  REPORT.md
  dump.cs
  script.json
  stringliteral.json
  il2cpp.h
  DummyDll/            (132 file, termasuk Assembly-CSharp.dll)
  AndroidManifest.xml
```

- Yang **TIDAK** diarsipkan (preseden hasil-dump): `libil2cpp.so`, XAPK, APK,
  split APK (file game tidak disebar; hash tercantum di REPORT ini).
- File arsip siap di `~/workspace/rea-bussid-461/dump/` (sudah berisi
  `dump.cs`, `script.json`, `stringliteral.json`, `il2cpp.h`, `DummyDll/`,
  `AndroidManifest.xml`); REPORT ini (`REPORT.md`) di root folder kerja.
- Catatan: `dump/` lokal juga berisi `libil2cpp.so` + `global-metadata.dat`
  (keperluan kerja) — **buang keduanya saat push arsip**.
- Belum di-push (sesuai perintah: JANGAN push).

---

## 8. File-file hasil

| Path | Isi / ukuran |
|---|---|
| `~/workspace/rea-bussid-461/REPORT.md` | Laporan ini |
| `~/workspace/rea-bussid-461/bussid-4.6.1.xapk` | XAPK terverifikasi, 914.302.090 B |
| `~/workspace/rea-bussid-461/xapk/` | Isi XAPK terekstrak (11 split + manifest.json) |
| `~/workspace/rea-bussid-461/apk/` | Base APK + config arm64 terekstrak |
| `~/workspace/rea-bussid-461/dump/` | dump.cs (30 MB) + script.json (76 MB) + stringliteral.json + il2cpp.h (67 MB) + DummyDll/ (132 file) + AndroidManifest.xml (+ libil2cpp.so & global-metadata.dat untuk kerja) |
| `~/workspace/rea-bussid-461/decompiled/` | ILSpy atas DummyDll (stub, 3 assembly) + `cpp2il/` (ILSpy atas DLL hasil Cpp2IL — juga stub, bukti §5.3) |
| `~/workspace/rea-bussid-461/cpp2il_out/` | DLL hasil Cpp2IL `dll_il_recovery` (8,2 MB) |
| `~/workspace/rea-bussid-461/tools/Cpp2IL-Linux` | Cpp2IL 2022.1.0-pre-release.21 |
| `~/workspace/rea-bussid-461/download_url.txt` | URL XAPK APKPure bertanda tangan (kedaluwarsa 16 Nov 2026 14:13:30 UTC) |
| `~/workspace/rea-bussid-461/api_response.bin` | Respons protobuf APKPure `app_version` (517.600 B) |

---

## 9. Batasan & langkah lanjutan

1. REA ini **statis penuh** — tidak ada observasi runtime (game tidak dijalankan).
   Semua klaim "lokal" bersandar pada signature/field/RVA + pola arsitektur,
   bukan eksekusi.
2. **Cpp2IL gagal memulihkan isi method** (§5.3) — logika internal method
   kunci (rumus BBM, rumus damage, alur `FarePaymentSimple`) belum terbaca.
   Langkah lanjutan: disassembly ARM64 per-RVA di `libil2cpp.so`, atau probe
   runtime di perangkat (baca `get_FuelLevel`/`SpeedKMH` saat main).
3. Sistem **XP/level pemain belum ketemu** — butuh pencarian lanjutan sebelum
   klaim apa pun soal level.
4. Endpoint backend (PlayFab TitleId, host API Maleo, Photon AppId) tidak
   ditemukan di string literal biner — kemungkinan dari config aset /
   Firebase RemoteConfig; bukan blocker untuk injector (tidak dipakai).
5. **Sebelum build injector:** (a) cek versi BUSSID terpasang di POCO user
   (harus 4.6.1 / code 2006547); (b) putuskan gate akhir-trip untuk fitur
   kecepatan (§6.4 — risiko `earning`); (c) verifikasi runtime 4 poin §6.4.
6. Injector TIDAK dibangun dan TIDAK ada push GitHub dalam tugas ini.
