# REA Report — Dr. Driving 1.73 (com.ansangha.drdriving)

- **Tanggal REA:** 18 Nov 2026
- **Sumber:** `Dr._Driving_1.73_0_azpk.apks` (14.792.262 B)
  SHA-256 `d24e10f15bf5c81d0121cd334ff1946dde7bde7ebf5c58726ab8349120c3ab2e`
- **Isi .apks:** `base.apk` 21.096.379 B + `split_config.arm64_v8a.apk` (37.303 B)
  + `split_config.in.apk` (20.889 B, resource Indonesia) + `split_config.xxhdpi.apk` (50.954 B)

## 1. Identitas APK (terverifikasi, bukan asumsi)

| Item | Nilai |
|---|---|
| Package | `com.ansangha.drdriving` |
| versionName / versionCode | **1.73 / 73** |
| minSdk / targetSdk / compileSdk | 23 / 36 / 36 (platform 16) |
| Label | Dr. Driving |
| Aktivitas utama | `com.ansangha.drdriving.DrDrivingActivity` (landscape, fullscreen) |
| Signer | CN=Sangha An, O=Studio AnSangha, L=Daejeon |
| Signer SHA-256 | `f60fd9af328f7afa27a764b6a7855696e887f4ba8c75081c5312eff96f40f63d` |
| Signer SHA-1 | `376880ea1446f7a181d75ed0226cbd4b05775f0a` |
| Source stamp | Google (Play App Signing) |
| Izin penting | INTERNET, ACCESS_NETWORK_STATE, BILLING (`com.android.vending.BILLING`), AD_ID, WAKE_LOCK, FOREGROUND_SERVICE |

## 2. Engine — BUKAN Unity

**Game ini native Java/Kotlin Android dengan engine OpenGL custom, bukan Unity.**

Bukti:

- `base.apk` **tidak mengandung `lib/` sama sekali** — tidak ada `libil2cpp.so`,
  tidak ada `global-metadata.dat`, tidak ada `.so` game apa pun. Satu-satunya `.so`
  di seluruh bundle adalah `lib/arm64-v8a/libdatastore_shared_counter.so`
  (7.112 B, library AndroidX DataStore) di split arm64.
- Kode game = **2 file DEX** (`classes.dex` 8.148.912 B + `classes2.dex` 2.467.476 B,
  total 16.243 class) — mayoritas library (Play Billing 8.0.0, Play Games 21.0.0,
  Firebase, AdMob, Facebook SDK).
- Aset mentah di `assets/`: model mobil/lingkungan **`.obj` + tekstur `.png/.jpg`**
  langsung (`assets/cars/car00..car17` + `AI_car01/02`, `assets/envi/`, `assets/interior/`,
  `assets/sounds/`) — loader OBJ sendiri, bukan asset bundle Unity/Unreal.
- Framework render: `com.ansangha.framework` / `com.ansangha.framework.impl.GLGame`
  (GLGameState, GLSurfaceView-style game loop) — framework OpenGL ES buatan
  developer sendiri (SUD Inc. / Studio AnSangha).
- Kode game **diobfuscate R8** (nama class 1 huruf, `r8-map-id-5a493a65fc435e6a4dd1248b1d0d353b0fe72fbc11e2aecc11db77d20ba63c32`).
  Il2CppDumper / Cpp2IL **tidak relevan** — tidak ada yang perlu di-dump dari native.
  Analisis dilakukan via **jadx** (dekompilasi DEX, 7.318 class, 31 error minor)
  + **apktool** (smali untuk method yang gagal di-decompile jadx).
- **Konsekuensi untuk injector:** tidak ada `.so` untuk di-hook Dobby/PLT.
  Jalur injector adalah **DEX-level** (LSPosed/Frida hook method/field Java,
  atau patch smali) — anchor method/field ada di §6.

## 3. Arsitektur kode game (package `com.ansangha.drdriving`)

| Class | Peran | Ukuran |
|---|---|---|
| `DrDrivingActivity` | Activity + billing + Firebase + Play Games + multiplayer | 2.108 baris |
| `d` | Layar game utama: misi, ekonomi, beli mobil/upgrade/repair, hadiah | 3.921 baris |
| `l` | Map/fisika: mobil pemain, bahan bakar, skor, tabrakan, misi | ~1.100+ baris |
| `o` | **SaveGame** — seluruh state pemain (JSON lokal) | 423 baris |
| `c` | Konstanta/suara | — |
| `e`, `m`, `n` | Layar/UI pendukung, hasil misi (`n` = result) | — |
| `tool/a..s` | Utilitas: `tool.d` = info mobil, `tool.e` = `carinfo[30]`, `tool.l` = mobil (player/opponent) | 1.157 baris |
| `framework/*` | Engine GL custom (`GLGame`, batcher, input pad) | — |

## 4. SaveGame — ekonomi 100% LOKAL (`o.java`)

Seluruh progres tersimpan sebagai **satu JSON di SharedPreferences**
(`getPreferences(0)`, key `"game"`, `"version":"1.0"`), tanpa server:

- `iCoin`, `iGold` (mata uang), `iCoinC`/`iGoldC` (salinan "bersih"),
  `iBoughtGold` (total gold hasil IAP), `iDriverLevel`, `iDriverExp`,
  `iTravelDistance`, `iDriftDistance`, `iAccidentNo`, `iMissionsClearCount`,
  `iTravelSecond`, `iMaxSpeed`, `iPerfectTurn`, `iSubMission`, `iCS`,
  `iWin`, `iLose`, `iRating` (multiplayer), `iMB`,
  `bHasCar[32]`, `bAchievement[32]`, `iCarDamage[32]`, `iCarRent[32]`,
  `iUpgrade[32][6]` (6 ability/mobil, level 0–10, disimpan nibble 4-bit),
  `iRecord[9]`, `iMissionClear[9]`.
- **Anti-tamper lokal (lemah):** `DrDrivingActivity.rs` =
  `new Random().nextInt(1000) + 1` **per proses** (static init, `DrDrivingActivity.java:586-588`).
  Nilai tersimpan = nilai asli + `rs` (ditambah saat load, dikurangi saat save:
  `o.loadFromJson` / `o.toString`). Mengedit JSON mentah tanpa menyesuaikan
  `rs` hanya menggeser angka sebesar offset acak 1–1000 itu — bukan proteksi
  kriptografis; `rs` hidup di memori dan berubah tiap launch.
- **Clamp saat load** (`o.loadFromJson`): `iRecord[0..2,5] ≤ 10000`,
  `iRecord[3,4] ≤ 12000`, `iRecord[6] ≤ 12000`, `iCarRent` 0–30000,
  damage ≤ 9000 (di `d.onMissionFinished`). Tidak ada validasi silang
  (mis. coin vs. histori tidak diperiksa).
- **Cloud backup (bukan otoritas):** `DrDrivingActivity.saveToCloud()`
  menulis string JSON yang sama ke **Firestore** `Users/{myID}` field `"game"`
  (`myID` = Play Games player id, fallback `"id"`). Restore via
  `processStateLoaded()`. Tidak ada validasi server — salinan mentah dari save lokal.
- Tidak ada enkripsi save, tidak ada checksum.

## 5. Ekonomi

### 5.1 Mata uang

| Mata uang | Sumber | Keterangan |
|---|---|---|
| **Coin** | Hadiah misi, koin di jalan, achievement, balon iklan, tukar gold | Mata uang hasil main |
| **Gold** | IAP (lihat §5.2), balon iklan (jarang), tukar dari… tidak ada sumber gratis besar | Mata uang premium/berbayar |

- Tukar gold→coin: `d.buyCoin(coin, gold)` — bayar gold, terima coin.
- Harga mobil (`tool.e.carinfo[30]`, `tool.d.iPrice`; **negatif = coin, positif = gold**):
  mobil 1–6 coin 2.000/2.000/5.000/5.000/9.000/9.000; mobil 7–15 gold
  100/100/200/200/300/300/400/400/500; mobil 16–27 gold 10–80 (rental,
  `iCarRent`); mobil 28 BUS / 29 TRUCK harga 0 (kendaraan misi).
  `d.buyCar(i3)` hanya mengizinkan 1–15.
- Nama mobil (samaran): 0 KOS, 1 AYH, 2 SH, 3 ESDAS, 4 JUNO, 5 SHC, 6 SJ,
  7 JIO, 8 BKS, 9 RHS, 10 YMJ, 11 KEJ, 12 ISHS, 13 KAIST, 14 JBU, 15 MANE,
  16 KYUBIN, 17 SUBIN, 18 MINHA, 19 BORAM, 20 RANI, 21 AERO, 22 JANGGI,
  23 KOREA, 24 NAR, 25 CHOCO, 26 WON.H, 27 CHESS, 28 BUS, 29 TRUCK.
- Upgrade: 6 ability/mobil (`iAbility[6]`), level maks 10, **dibayar Coin**
  (`d.java:2693`: `iCoin - rs >= iGetUpgradeCost(car, ability)`).
  Biaya dasar terkait `iAbility` (jadx: `iGetUpgradeCost` — formula lengkap
  di smali `d.smali:4274`, gate: mobil dimiliki / rental ≥ 1).
- Repair: `d.iGetRepairCost()` (smali `d.smali:4184`) =
  `carinfo[car].iRepairCost × clamp(iCarDamage, 1000…9000) / 40000`,
  dibayar Coin, reset `iCarDamage[car] = 0` (`d.java:1026-1032, 1247-1253`).
  `iRepairCost` per mobil 100–600 (lihat `tool/e.java`).
- Damage: tiap misi `iCarDamage += 0.05 × jarak + jarak drift`; kecelakaan
  `+= 300 + speed×3000 / (ability[5]+10+upgrade[5])`, maks 9.000
  (`d.onMissionFinished`, `d.java:709+`).
- Level pengemudi: `iGetBaseExpForLevel`: basis 4.096, ×1,25/level
  (`d.java:452`); hadiah misi menambah `exp += reward × 15`.

### 5.2 IAP — Gold (Play Billing 8.0.0, grant LOKAL)

| SKU | Harga default | Gold diterima |
|---|---|---|
| `drdriving.gold200` | $1,99 | 200 |
| `drdriving.gold600` | $4,99 | 600 |
| `drdriving.gold1500` | $9,99 | 1.500 |

- Query `ProductDetails` di `DrDrivingActivity.java:748`, harga tampil dari Play.
- **Grant sepenuhnya lokal:** `onConsumeResponse` (`DrDrivingActivity.java:1420+`)
  langsung `iGoldC += n; iGold += n; iBoughtGold += n; SaveSettings(true)`
  setelah consume berhasil. Tidak ada verifikasi receipt ke server developer —
  otoritasnya hanya Play Billing client-side. (Tetap: memberi gold gratis =
  bypass IAP berbayar → DITOLAK di audit.)
- Tidak ada SKU lain (tidak ada remove-ads / VIP / paket mobil).

### 5.3 Misi (9 tipe) & hadiah

`d.strMission` (`d.java:613`): SPEED, HIGHWAY, DRIFT, **FUEL**, **VIP ESCORT**,
PARKING, BROKEN BRAKE, TRUCK, LANE. (`VIP` di sini = tipe misi escort, bukan
fitur berbayar. `MISSION_VIP = 4` di `l.java:26`.)

- Hadiah sukses (`d.onSuccessMission`, `d.java:848`):
  `rewardCoin = max(25, skor×0,3 + jarak×0,01 + 7)`; `exp += reward×15`;
  `iMissionsClearCount++`, `iMissionClear[type]++`.
  Skor akhir (`g_fScore`, `l.java:1086-1096`): FUEL = `gasLeft×150/gasInitial`;
  VIP = `150 − (waktu×0,4 + drift + brakeTime) × comfort`; BROKEN BRAKE/TRUCK =
  `150 − waktu`; lainnya `135 − waktu`. Skor int 0–100 (`(int)(100×g_fScore)`)
  dikirim ke leaderboard (`SubmitHighScore`).
- Koin di jalan: `g_iAcquiredCoinForThisStage` (sub-misi, belok sempurna)
  ditambah ke `iCoin` di `onMissionFinished`.
- Gagal misi (kecelakaan / kehabisan bensin / timeout 180 dtk):
  `onMissionFinished(1/2)` — tetap simpan jarak/drift/waktu + damage,
  tanpa hadiah misi (`d.java:340-370`).
- Achievement: 32 achievement lokal (`tool/a` lists, `iType` 0–16:
  jarak, drift, misi clear, per-tipe misi, sub-misi, perfect turn, max speed,
  driver level, **multi win**, dsb.), masing-masing `iRequiredAmount` +
  hadiah coin `iReward`; saat tercapai → `bAchievement[i]=true` +
  `unlockAchievements(achievementID)` ke Play Games (`d.onMissionFinished`).

### 5.4 Bensin — BUKAN resource persisten

- `l.g_fGasLeft` / `g_fGasInitial`: **per misi saja**, init **500,0**
  (100,0 untuk misi FUEL) — smali `l.smali:7690-7701`.
- Konsumsi (`l.java:866-926`): `gasLeft -= fuelConsume × dt × faktor gigi
  (1,0–1,6)`; idle `0,2×`; rem pelan `0,8×`. `g_fFuelConsume` default 1,0
  (dipengaruhi upgrade/ability).
- Habis bensin + mobil berhenti (`speed < 0,1` dan `gasLeft < 0` atau
  `travelTime > 180 dtk`) → misi gagal (`d.java:360`). Tidak ada tangki
  persisten / isi bensin antar misi.

### 5.5 Iklan & balon hadiah

- AdMob: banner, interstitial, rewarded (`DrDrivingActivity.initAds`,
  `showVideo`, `onVideoWatched`).
- Balon melayang di dalam misi (`d.adBalloon`, class `b`): ketuk balon →
  hadiah **coin** (`bCashItem=false`) atau **gold** (`bCashItem=true`)
  sebesar `iAmount`; mode reward mengharuskan tonton rewarded ad dulu
  (`bWatched`, `d.processAdBalloon`, `d.java:891+`). String UI:
  "You found a chance to collect … coins/gold!", "You found … free coins/gold!".

## 6. Multiplayer — NYATA, via Firebase (client-authoritative)

Game ini **punya mode multiplayer online real-time** (bukan bot):

- **Transport:** Firebase Realtime Database, project **`crucial-bonsai-821`**,
  `https://crucial-bonsai-821.firebaseio.com` (dari `res/values/strings.xml`).
  Node: `Waiting/` (matchmaking), `Gaming/{room}/` (`Live` presence,
  `ToCreator` / `ToJoiner` antrian pesan). Firestore dipakai hanya untuk
  backup save (`Users/{myID}`), RemoteConfig untuk gate versi
  (`iAppVersion` vs `verCode`), Analytics untuk event.
- **Syarat:** login Play Games (`isSignedIn()`, `myID` = Play Games player id,
  panjang ≥ 5) + `startQuickOnlineGame` (`DrDrivingActivity.java:766+`).
  Versi internal multiplayer `verCode = 69` (bukan versionCode 73).
  Bila `iFBAppVersion > verCode` → dipaksa update via Play Store.
- **Protokol pesan string** (diparse `onRealTimeMessageReceived`,
  `DrDrivingActivity.java:1577+`; dikirim `sendMessage`, dibatasi
  `iSendCount ≤ iReadCount + 300`):

  | Pesan | Arti |
  |---|---|
  | `R <verCode>` | Cek versi lawan; cocok → `setGameState(3)` + `sendMyProfile()`; lawan lebih baru → leave + prompt update; lawan lebih lama + friendly match → toast |
  | `P <rating> <carMode> <country> <nama…>` | Profil lawan — **rating dikirim oleh client lawan sendiri** |
  | `I <missionType> <20 directions> <40 aicar>` | Host (creator) mengirim seed lintasan bersama agar kedua pemain balapan di jalan yang sama |
  | `U <travelTime> <missionDistance> <cx> <cy> <vx> <vy> <angle>` | Update posisi/kecepatan lawan (ghost) |
  | `O Y` / `O N` | Lawan selesai (Y = lawan finish duluan → kita kalah) / lawan gagal/keluar (N → kita menang); dikirim `sendGameOver(true/false)` via `g_iInfoToSend` (1 = sukses, 2 = gagal) |
  | `S` | Start | 
  | `A <carType> <rating>` | Minta rematch |
  | `T` | Ping |

- **Penentuan menang/kalah & rating sepenuhnya client-side**
  (`d.onMultiFinished`, `d.java:3055+`): menang → coin `max(5, jarak×0,06)` +
  exp; rating Elo-like via `Q.d.a(ratingKu, ratingLawan)` (ekspektasi),
  perubahan 1–199, clamp rating ±10.000, `iWin++`/`iLose++`.
  Rating lawan = angka yang lawan kirim di pesan `P`/`A` — **tidak ada
  validasi server atas rating, kemenangan, atau posisi ghost**.
- **Leaderboard Play Games** (app id `943954155630`, SDK 21.0.0):
  11 leaderboard — `leaderboard_brake/drift/fuel/highway/lane/multirating/
  multiwin/parking/speed/truck/vip` (id `CgkI7rC1wLwbEAIQ…`) +
  achievement `ach_multiwin1/10/100`. Submit:
  `SubmitHighScore(missionType, skor)` (`DrDrivingActivity.java:1226`,
  jadx gagal decompile — logika mapping di smali) dan
  `uploadMultiLeaderboard(z2, rating)` (`:1989-1992`): `multirating` bila
  1–20.000, `multiwin` = `iWin − rs` bila menang.
- **Anti-cheat: praktis tidak ada.** Yang ada hanya: offset `rs` (lokal),
  clamp saat load, cek `verCode`, gate versi RemoteConfig. **Tidak ditemukan**
  Play Integrity / SafetyNet / App Check / verifikasi receipt server di kode game.
  Facebook SDK App ID `888820248211182` hanya tercantum di manifest
  (tidak ada pemakaian di kode game yang ditemukan).

## 7. Anchor untuk injector (DEX-level, bukan native)

- `com.ansangha.drdriving.o`: field `iCoin`, `iGold`, `iCoinC`, `iGoldC`,
  `iBoughtGold`, `iCarDamage[]`, `iUpgrade[][]`, `bHasCar[]`, `iWin`, `iLose`,
  `iRating`, `iDriverLevel`, `iDriverExp`, `iRecord[]`, `iMissionClear[]`;
  method `loadFromJson(String)`, `toString()`, `save(SharedPreferences, String)`.
- `com.ansangha.drdriving.DrDrivingActivity.rs` (static int, offset acak 1–1000);
  `mSaveGame` (static `o`); `SKU_GOLD200/600/1500`; `verCode = 69`;
  `onConsumeResponse`, `SubmitHighScore(int,int)`, `uploadMultiLeaderboard(boolean,int)`,
  `onRealTimeMessageReceived(String)`, `sendMessage(String)`, `sendGameOver(boolean)`,
  `SaveSettings(boolean)`, `saveToCloud()`.
- `com.ansangha.drdriving.d`: `buyCar(int)`, `buyCoin(int,int)`,
  `iGetRepairCost()`, `iGetUpgradeCost(int,int)`, `onMissionFinished(int)`,
  `onSuccessMission()`, `onMultiFinished(int)`, `g_fGasLeft` ada di `l`.
- `com.ansangha.drdriving.l`: `g_fGasLeft`, `g_fGasInitial`, `g_fFuelConsume`,
  `g_fScore`, `bCheckAccident()`, `g_iMissionType`, `g_fTravelDistance`.
- `com.ansangha.drdriving.tool.e.carinfo[30]` (`tool.d`: `iPrice`, `iRepairCost`,
  `iAbility[6]`, `strName`).
- **Catatan R8:** nama method/field di atas adalah hasil jadx dari DEX 1.73
  (code 73) — verifikasi ulang bila versi game berubah.

## 8. Kesimpulan arsitektur

- Game **solo sepenuhnya lokal**: ekonomi, misi, mobil, upgrade, repair,
  level, achievement — semua dihitung dan disimpan di perangkat
  (SharedPreferences JSON + backup Firestore mentah). Tidak ada server game
  sendiri; tidak ada validasi server atas nilai apa pun.
- **Satu-satunya komponen online yang kompetitif:** multiplayer Firebase RTDB
  (matchmaking + ghost lawan + rating) dan leaderboard/achievement Play Games.
  Keduanya **client-authoritative** — kemenangan, rating, dan skor dikirim
  dari client tanpa verifikasi server.
- IAP gold adalah satu-satunya pembelian; grant-nya lokal pasca-consume
  Play Billing.
- Tidak ada proteksi anti-cheat yang berarti (hanya offset acak `rs` +
  clamp). Tidak ada native lib untuk di-hook — injector harus DEX-level.

## 9. Metode & batasan

- Ekstrak `.apks` → `aapt dump badging` + `apksigner verify --print-certs`
  → inventory `unzip -l` → `apktool` decode → `dexdump` (16.243 class) →
  `jadx --no-res` (7.318 class, 31 error minor; method yang gagal — mis.
  `SubmitHighScore`, `iGetRepairCost`, `frameMoveObject` — dibaca via smali).
- Tidak ada runtime/dynamic analysis (tidak dijalankan di perangkat);
  perilaku multiplayer disimpulkan dari kode statis protokol pesan.
- `libil2cpp.so` + `global-metadata.dat` **tidak ada** dalam paket ini
  (bukan Unity) — sesuai pola arsip sebelumnya, keduanya tidak disertakan.
- Kunci API Firebase (`google_api_key`) terlihat di resource — **sengaja
  tidak ditulis di laporan ini**.

## 10. File kerja

- Kerja REA: `~/workspace/rea-drdriving/work/` (apks terekstrak, dex, jadx,
  apktool-out, strings, class list) — tidak diarsip ke repo (hanya laporan).
- Laporan ini: `~/workspace/rea-drdriving/REPORT.md`
- Audit: `~/workspace/rea-drdriving/AUDIT-INJECTOR.md`
