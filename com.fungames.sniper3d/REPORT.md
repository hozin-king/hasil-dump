# REA — Sniper 3D (com.fungames.sniper3d) v7.15.0

**Tanggal:** 17 Nov 2026 · **Metode:** dump + decompile statis (skill `local-rea`) · **Riset saja — TIDAK ada injector yang dibangun, TIDAK ada push.**

## 0. Ringkasan eksekutif

| Pertanyaan | Jawaban |
|---|---|
| Engine | **Unity 6000.3.21f1 (Unity 6), IL2CPP** — metadata v39, 179.074 method, 225 DLL |
| Mode misi (campaign) | **Solo lawan AI, simulasi lokal** — posisi musuh, nyawa, hit/damage dihitung di client |
| Mode Arena/PvP | **Multiplayer real-time sungguhan** — matchmaking + game server khusus + sinkronisasi lawan + **validasi tembakan di server** |
| Klaim "misi lawan bot/AI" | **TERBUKTI** (§5) |
| Klaim "online cuma buat beli item" | **TIDAK TEPAT** — online juga dipakai sync progres, energi, leaderboard, chat/clan, dan Arena real-time (§6) |
| Klaim "Arena lawannya bot, bukan pemain asli" | **TIDAK TERBUKTI — bukti dump mengarah sebaliknya** (§7). Bot memang ada (bot roster), tapi arsitekturnya PvP real-time dan client tidak bisa memastikan satu match isinya bot semua |
| Anti-cheat | Play Integrity (Standard API) + **server bisa menandai pemain sebagai cheater → ban/suspend** + validasi tembakan server (Arena) + validasi receipt IAP |
| Ekonomi | Koin/diamond/energi **server-synced** — tidak ada fitur currency yang boleh disentuh |
| ESP referensi (`ESP_3_thnu.h`) | **Rendering saja** — bisa dipakai, tapi butuh sumber posisi dari game (§8) |

**Implikasi untuk injector:** 6 fitur yang diminta user (aimbot/aimlock/auto-aim saat zoom, ESP, no recoil, no reload, zoom jauh) **BOLEH disarankan HANYA untuk mode misi, dengan gate mode misi + fail-closed**. Di Arena semuanya **DITOLAK** sebagai kelas. Detail klasifikasi: `AUDIT-INJECTOR.md`.

---

## 1. Identitas & sumber

| Item | Nilai |
|---|---|
| Package | `com.fungames.sniper3d` |
| Nama | Sniper 3D |
| Versi | **7.15.0, versionCode 33186** |
| minSdk / targetSdk | 25 / 36 |
| Sumber | XAPK via API APKPure (`api.pureapk.com/m/v3/cms/app_version`, header `x-sv: 29`, `x-abis: arm64-v8a,armeabi-v7a,armeabi`, `x-gp: 1`) — download langsung `d.apkpure.com` 403, API yang tembus |
| URL unduhan | `[disensor — tautan unduhan bertanda tangan, minta ke Alyaa bila perlu]` (URL bertanda tangan, tersimpan di `work/xapk_url.txt`) |
| XAPK | **247.871.814 B**, SHA-256 `c7b446a8586d26e9a941c65b4459b5e2047cd3a25b0f5fff5e9c6df65a1562db` |

### Isi XAPK

| File | Ukuran | SHA-256 |
|---|---|---|
| `com.fungames.sniper3d.apk` (base) | 197.898.788 B | `eaf443b44a14df1fecfc1702d263fc4601647efc7c2e9071b0f19644c0760c80` |
| `config.arm64_v8a.apk` (split native) | 49.968.758 B | `72ead8dbfeb4c7ccc818dca4e349364127db9b01116c11677b47f6ec1db21d59` |
| `manifest.json` | 3.821 B | — |

### Base APK

- 7.499 entri, 298,5 MB (belum dikompres) / 196,6 MB (terkompres).
- **12 file .dex** (total ±85 MB) — wrapper Android + SDK (bukan logika game; logika game ada di IL2CPP).
- `assets/bin/Data/`: **5.867 file** (asset bundle/level, nama hash) + `Managed/Metadata/global-metadata.dat`.
- Permission (aapt): `POST_NOTIFICATIONS`, `ACCESS_WIFI_STATE`, `INTERNET`, `com.android.vending.BILLING`, `ACCESS_NETWORK_STATE`, storage (maxSdk 18), `C2D_MESSAGE`, plus permission iklan/badge launcher.

### Native .so (split arm64, 10 terbesar)

| Library | Ukuran | Peran |
|---|---|---|
| `libil2cpp.so` | 135.558.640 B | Seluruh logika game (IL2CPP) |
| `libunity.so` | 24.571.776 B | Engine Unity 6 |
| `libFirebaseCppApp-12_10_1.so` | 4.270.944 B | Firebase App |
| `libpitaya-android.so` | 4.167.472 B | **Client framework game server (Pitaya) — indikasi multiplayer server** |
| `libapplovin-native-crash-reporter.so` | 843.152 B | AppLovin |
| `liblofelt_sdk.so` | 772.120 B | Haptik |
| `libcrashlytics-common.so` | 755.864 B | Crashlytics |
| `lib_burst_generated.so` | 314.040 B | Burst |
| `libtapjoy.so` | 300.632 B | Tapjoy (offerwall) |
| `libcrashlytics.so` | 195.568 B | Crashlytics |

Lainnya: `libmain.so`, `libFirebaseCppAnalytics.so`, `libFirebaseCppCrashlytics.so`, `libcrashlytics-handler.so`, `libcrashlytics-trampoline.so`, `libdatastore_shared_counter.so`.

---

## 2. Metode dump

1. XAPK diunduh via API APKPure (download langsung 403), diverifikasi ukuran persis metadata (247.871.814 B) + SHA-256.
2. XAPK diekstrak ke `work/xapk/` (base + split arm64) dan `work/base/`, `work/arm64/`.
3. **Il2CppDumper GAGAL** — metadata v39, sedangkan Il2CppDumper (versi `~/workspace/flylm/il2cppdumper/` maupun master GitHub) maksimal v31.
4. **Cpp2IL 2022.1.0-pre-release.21 BERHASIL** (`~/workspace/rea-bussid-461/tools/Cpp2IL-Linux`, `--force-unity-version 6000.3.21f1`): metadata v39 didukung, **179.074 method** terpetakan → `work/cpp2il_out/` (225 DLL; `Assembly-CSharp.dll` 4.596.736 B).
5. Decompile: **ilspycmd 8.2.0.7535** (`~/.dotnet/tools/ilspycmd`, `DOTNET_ROLL_FORWARD=LatestMajor`) → `work/decompiled/` (signature + nama; sebagian besar badan method kosong) dan `work/decompiled_ilrec/` (dari output `dll_il_recovery`).
6. Badan method asli dibaca dari **output ISIL Cpp2IL** (`work/cpp2il_isil/IsilDump/`, 536 MB) — disassembly ARM64 + ISIL per method. ISIL punya celah (`NotImplemented` untuk sebagian instruksi), jadi penelusuran logika dilakukan pada method yang menentukan + bukti arsitektur (nama class/method/field, konstanta string, route jaringan).
7. `aapt dump badging` untuk identitas APK; `strings` pada `classes.dex`/`classes2.dex` untuk deteksi root.

**Catatan alat:** `dll_default` dan `diffable-cs` Cpp2IL hanya berisi signature (badan method kosong/`throw null`). Satu-satunya sumber badan method yang bisa dibaca adalah dump ISIL. Il2CppDumper **tidak** bisa dipakai untuk game ini (metadata v39).

---

## 3. Arsitektur game (dari dump)

Developer: **Wildlife Studios** (dulu Fun Games). Namespace utama: `Game.*` (584 namespace di Assembly-CSharp), `ModulesSniper.*`, `Wildlife.Platform.*` (platform services: Wallet, Purchases, Clans, Friends, Chat, Leaderboards, Mailbox, CloudSave, PlayerProfile, Metagame), `Pitaya` (realtime), `TFG.*`.

### 3.1 Mode game yang ada

| Mode | Bukti kode | Sifat |
|---|---|---|
| **Campaign / Misi** (solo) | `Mission.*`, `RandomMission.*Briefing`, `Game.LiveEvents.Events.SinglePlayer`, `Game.SinglePlayerProgressSyncer`, `LevelController` | Solo lawan AI, simulasi lokal (§5) |
| **Arena / PvP** | `Game.Pvp.*`, `Game.PvpRevamp.*`, `Game.Multiplayer.*`, `Services.PVP`, `Menu.Multiplayer` | **Real-time multiplayer** (§7) |
| **Shooting Range** (latihan) | `Game.ShootingRangeChallenge.*` | Solo, target |
| **World Ops / Live Events** | `Game.WorldOpsLiveEvent.*`, `Game.LiveEvents.*`, `Game.HeadHuntersLiveEvent.*`, `Game.ClanWars.*`, `Game.SquadWarsLiveEvent.*` | Event berbasis server |
| **Clan / Sosial** | `Game.Clans`, `Game.Chat`, `Wildlife.Platform.Services.Clans/Friends/Chat` | Online |
| **Store / IAP** | `Game.PackStore.*`, `Game.Purchases.*`, `Game.SniperStore.*`, `Wildlife.Platform.Services.Purchases` | Online, receipt validation |

### 3.2 Jaringan: Pitaya + metagame socket

- `PitayaClientWrapper : IManagedSocketHandler` — client socket persisten ke **game server Pitaya** (framework server game real-time; `libpitaya-android.so` native).
- `ModulesSniper.ServerConnection`, `ModulesSniper.SocketHandler`, `ModulesSniper.Metagame.*` — kanal metagame (profil, wallet, progres, matchmaking) lewat socket yang sama.
- `PitayaClock` / `PitayaDateChangedDetector` — waktu server dipakai sebagai jam aplikasi (anti time-cheat lokal).
- `Game.ConnectionRequired` + `Game.OfflineBlock` (plugin native `com.fungames.sniper3d.offlineblock.OfflineBlockPlugin`, `OfflineBlockManager`, `OfflineBlockConfig` remote-config) — game ini **online-first**: ada mekanisme blokir saat offline. (Badan `ShouldBlock` terkonfirmasi ada di ISIL; ambang pastinya remote-config — butuh probe runtime.)

### 3.3 Senjata & tembakan (sisi client)

Class inti: `Person.Weapon : MonoBehaviour` (gameplay) + `Game.Weapon.DataAccess.WeaponData` (statistik).

`WeaponData` — semua field lokal (client-side):

| Field | Arti |
|---|---|
| `Damage`, `DamageMultiplier`, `HeadshotDamageBonus` | Damage dasar & pengali |
| `Range`, `FireRate`, `ShotCount` | Jarak, laju tembak, jumlah proyektil |
| `Spread`, `spreadSensitivity`, `spreadRecoverSpeed` | Sebaran bidikan (setara "recoil" game ini) |
| `Stability`, `NormalizedStability` | Stabilitas |
| `ClipSize`, `ReloadTime` | Ukuran magazen & waktu reload |
| `MaxZoom`, `ZoomLevels`, `GetZoom(level)` | Pembesaran scope |
| `automaticFire`, `focusable`, `allowHipShot`, `Silenced` | Perilaku senjata |

`Weapon` (gameplay): `ShootTest` (raycast, `TestDistance = 6000f`), `FireInternal`, `FireKillCam`, `IncreaseSpread()` / `RecoverSpread()`, `WeaponReloadFeedback`, `WaitAndReload`, `WeaponDamageOverride` / `HeadshotWeaponDamageOverride` (field nullable — **game sendiri punya jalur override damage**), `HitInfo` (person, hitable, point, normal, direction, `IsHeadShot()`, `killed`).

**Tidak ada konsep "recoil" harfiah** — 0 hasil untuk string `recoil` di Assembly-CSharp. Yang ada: spread/bloom (`_spreadAmount`, `_shootInaccuracy`), `WeaponBob`, goyangan kamera/napas (mekanik *hold breath*: `Game.TutorialInGame.HoldBreath`). "No recoil" di game ini = **no-spread + no-sway**.

`Zoom` (static class): `ScaleMax`, `ScaleMin`, `ScaleStep`, `IsZoomingIn/IsZoomingOut`, `HasToggledZoom` — zoom = skala/FOV kamera client-side. `Camera.fieldOfView` dipakai di rendering & hit-marker (`CameraInformation`: position, rotation, fieldOfView).

**Aim assist bawaan:** `Game.Scripts.AimHelper` — HANYA indikator UI (dot merah/hijau + hint, properti `TargetInAim`, `LocalPosition`). **Bukan** aim snap/magnet — tidak ada logika penguncian bidikan di game.

---

## 4. Anti-cheat & keamanan (audit)

| Mekanisme | Bukti | Keterangan |
|---|---|---|
| **Play Integrity (Standard API)** | `IntegrityStandardValidatorService`, `IIntegrityValidatorService`, `RequestIntegrityToken(jsonPayload, onTokenRequestFinished, featureName)`, `PrepareIntegrityToken()`, `IntegrityAPIRemoteConfig` (`ConfigKey = "integrityApi"`), `Google.Play.Integrity.dll` | Token integrity diminta **per fitur** (parameter `featureName`), dikontrol remote config. Token dikirim ke server untuk divalidasi. Titik pemakaian pastinya butuh probe runtime. |
| **Penandaan cheater oleh server → ban/suspend** | `MetagameAnalytics.CheaterDetected(bool isBanPermanent)`, event `PlayerIsTaggedAsCheater` + struct `CheaterResponseData`, `MigrateCheaterViewController` (popup `CheaterBanPopupTitle/Content`, `CheaterSuspendPopupTitle/Content`, `CheaterSuspendPopupContentBanTime`) | Server bisa menandai akun sebagai cheater saat sync metagame; hukumannya ban permanen ATAU suspend berjangka (dengan timer). |
| **Validasi tembakan server (Arena)** | `ArenaCharacterMessenger.OnShotMsgValidated(shooter, shooterScore, target, targetScore, headShot, damage, hitPos, bulletId, bulletProc)` | Server memvalidasi klaim tembakan sebelum damage diterapkan. Lihat §7. |
| **Validasi receipt IAP** | `Wildlife.Platform.Services.Purchases`: enum `RECEIPT_FAILED_TO_VALIDATE`, `RECEIPT_INVALID` | Pembelian uang asli divalidasi receipt-nya di server. |
| **Wallet anti-cheat** | `WalletCheatsHandler` / `WalletCheatsProvider` (`IWalletCheatsHandler`) di `Wildlife.Platform.Services.Wallet` | Perubahan currency melewati handler server-side. |
| **Jam server** | `PitayaClock`, `PitayaTimeDeltaResponse` | Waktu dari server, bukan jam HP. |
| Deteksi root client-side | **TIDAK DITEMUKAN** — `strings` pada `classes.dex` + `classes2.dex`: 0 hit untuk `magisk|supersu|isRooted|rootbeer|/system/xbin/su|test-keys` | Tidak ada RootBeer/su-check di wrapper Java (yang terperiksa). Play Integrity adalah lapisan anti-tamper utamanya. |
| Anti-cheat pihak ketiga (mis. EasyAntiCheat dkk.) | Tidak ada | Tidak ditemukan library anti-cheat khusus di native .so. |

**Catatan jujur:** tidak ada bukti client-side mendeteksi injector/root secara langsung. Risiko utama adalah **server-side**: token Play Integrity, penandaan cheater, dan validasi tembakan Arena. Detail ambang deteksi (mis. akurasi mustahil, waktu misi terlalu cepat) tidak terlihat dari dump statis — butuh probe runtime.

---

## 5. Mode misi — VERIFIKASI: solo lawan AI, logika lokal ✅

### 5.1 Musuh (NPC) disimulasi lokal

Class `Person : MonoBehaviour` (NPC misi):

- `_health` / `_currentHealth` — **`double` lokal** di client.
- `_headShotDamageMultiplier`, `_bodyShotDamageMultiplier` — pengali damage lokal.
- `_alive` / `_dead`, `_isFrozen`, `_hitReactionTime`, `_increaseAwarenessOnDamage` — state AI lokal.
- `ShotTracker` (`ShotsTaken`, `HeadShotsTaken`, `RegisterShot(headshot)`) — statistik tembakan lokal.
- `Mission.Action _OnKilled` / `_OnDamageTaken` — callback misi lokal (objektif misi terpicu dari sini).
- Path/AI: `Mission.PathNode`, `Mission.FlyPath`, `_rotateToTargetSpeed`, `_continuePathWhenDead` — NPC bergerak mengikuti path & skrip misi di client.

Hit detection: `Weapon.ShootTest` — **raycast lokal** (`Physics.Raycast`, jarak tes 6.000) → `HitInfo` → damage diterapkan ke `Person._currentHealth` di client. Tidak ada pengiriman tembakan ke server selama misi berjalan.

### 5.2 Yang dikirim ke server: hanya laporan progres saat menang

`Game.SinglePlayerProgressSyncer`:
- `LevelControllerOnWin()` → `ReportProgress()` → `PlayerHandler.SyncPlayerCampaign(regionNumber, levelNumber, ...)` via `App.get_MetagameCommunication`.
- Yang disinkronkan: **nomor region & level yang selesai** (normal + special levels) — server mencatat progres campaign & memberi hadiah/unlock berdasarkan laporan ini.
- Artinya: **gameplay misi 100% lokal; yang server-side adalah pencatatan hasil & hadiah.** Server tidak memvalidasi tiap tembakan di misi (tidak ada `OnShotMsgValidated` untuk misi), tapi server menerima laporan "level X selesai" — pola hasil yang mustahil (mis. semua misi selesai dalam hitungan detik, headshot 100% terus-menerus) secara prinsip bisa ditandai oleh analitik server. Ambangnya tidak terlihat dari dump.

### 5.3 Energi & mata uang misi

- `Game.Energy.*` (`Energy : IEnergy`, `EnergyConfig`, `EnergyFreeRefills`) — misi menghabiskan energi; energi direfill berbasis waktu server (`PitayaClock`) dan sinkron ke profil server. **Energi bukan lokal** — tidak boleh dimodifikasi.
- Hadiah misi (`CollectRewards`: softCurrency/gold, hardCurrency/gems, pvpCurrency, tokens, senjata, gear, special bullets) diberikan lewat jalur server/metagame — **bukan lokal**.

### 5.4 Kesimpulan misi

> Misi Sniper 3D adalah **solo vs AI dengan simulasi penuh di client**. Aimbot/auto-aim/ESP/no-spread/no-reload/zoom bekerja pada lapisan lokal (Transform musuh, raycast, field WeaponData) dan **secara teknis bisa jalan**. Risiko yang tersisa adalah server-side: laporan progres + analitik + penandaan cheater (§4). Karena itu fitur misi harus memakai gate mode misi dan tidak boleh menyentuh progres/hadiah/energi.

---

## 6. Verifikasi klaim "online cuma buat beli item" — TIDAK TEPAT ❌

Online dipakai untuk **lebih dari IAP**:

| Komponen online | Bukti |
|---|---|
| IAP / toko (uang asli) | `com.android.vending.BILLING`, `Game.Purchases.*`, `ModulesSniper.InAppPurchase`, receipt validation (§4) — **benar ada, tapi bukan satu-satunya** |
| Sync profil/progres/wallet | `ModulesSniper.Metagame.*`, `Wildlife.Platform.Services.Wallet/PlayerProfile/CloudSave`, `SyncPlayerCampaign` (§5.2) |
| Energi & waktu | `Game.Energy.*`, `PitayaClock` (jam server) |
| Leaderboard & nama bot | `Game.Ranking.*`, `Game.ShortLeaderboard.*`, `LeaderboardBotNameProvider`, `ShortLeaderboardBotManager` |
| Chat / Clan / Mailbox | `Game.Chat.*`, `Game.Clans`, `Wildlife.Platform.Services.Chat/Clans/Mailbox` |
| **Arena real-time** | §7 — matchmaking + game server + relay tembakan lawan |
| Remote config & live events | `Game.BackendRemoteConfig.*`, `Game.LiveEvents.*`, `Game.ChristmasLiveEvent.*` dkk. |
| Blokir offline | `Game.OfflineBlock` + plugin native `OfflineBlockPlugin` |

**Koreksi yang tepat:** "Gameplay *menembaknya* di misi berjalan lokal; tapi game ini online-first — login, sync progres, energi, dan Arena semuanya butuh server. IAP hanyalah satu dari banyak komponen online."

---

## 7. Verifikasi klaim "Arena lawannya bot, bukan pemain asli" — TIDAK TERBUKTI ❌ (bukti mengarah sebaliknya)

Ini klaim yang paling penting untuk dikoreksi, karena menentukan apakah aimbot/ESP boleh dipakai di Arena. Hasil dump: **Arena adalah PvP real-time dengan lawan yang disinkronkan lewat server — dan bot hanya terbukti sebagai pengisi roster, bukan sebagai keseluruhan lawan.**

### 7.1 Bukti Arena = multiplayer real-time

**Alur matchmaking** (`Game.Multiplayer.MatchmakingImpl.*`):
- `ArenaMatchmaker.JoinQueue(args)` → `OnWaitingForMatch` → `OnMatchFound(MatchFoundPush)` / `OnMatchmakingTimeout` (timeout → event + `Reset()`, **tidak ada fallback bot di client**).
- `MatchFoundPush` membawa `GameServerUrl` — match berjalan di **game server khusus** (Pitaya), bukan simulasi lokal.
- `MatchFoundEventArgs`: `playerId`, `enemyPlayerId`, `matchId`, `enemyName`, `host` — struktur match 1v1 dengan peran host.

**State machine match** (`ArenaMatchFluxController.MatchLogicalStatus`):
`WaitingConnection → WaitingReady → WaitingLevelLoaded → Running → ReceivedMatchEnd` — kedua belah pihak harus connect, menyatakan siap (`playerReady`), dan menyatakan level termuat (`playerLevelLoaded`) sebelum match jalan. Ini sinkronisasi antar-pemain, bukan bot lokal.

**Protokol pesan real-time** (`ArenaMatchHandler`, handler `matchHandler`):

| Arah | Route | Arti |
|---|---|---|
| Client → server | `playerReady`, `playerLevelLoaded`, `playerGameMessage`, `matchEnded` | Siap, level termuat, pesan game, match selesai |
| Server → client | `match.gameMessage`, `match.roomConnected`, `match.readyTimeout` | Pesan game, room siap, timeout |
| Server → client | `match.levelLoaded`, `match.levelLoadedTimeout` | Sinkron loading |
| Server → client | **`match.characterUpdate`** | **Update posisi/rotasi/aim lawan, real-time** |
| Server → client | **`match.shotMsg`** | **Pesan tembakan lawan, real-time** |
| Server → client | `match.respawnMsg`, `match.resyncState`, `match.reconnected` | Respawn, resync state, reconnect |
| Server → client | `match.arenaMatchResult` | Hasil match dari server |
| Server → client | `match.botRoster` | Daftar bot dalam match (§7.2) |

**Messenger karakter** (`ArenaCharacterMessenger`) — ini bukti paling kuat:
- Mengirim: `SendCharacterUpdate(rotation, aim)`, `SendShot(target, headShot, hasHit, layerDamage, hitPosition, shotOrigin, shotDirection, specialBulletID)`, `SendReload(duration)`, `BuyRespawn(player, publicId)`, `SendReconnected()`.
- Menerima: `OnStatusReceived(rotation, aim)`, **`OnShotMsgValidated(shooter, shooterScore, target, targetScore, headShot, damage, hitPos, bulletId, bulletProc)`**, `OnReloadMessageReceived(duration)`.
- `ArenaMatchFluxController` menangani tiap tipe: `HandleCharacterUpdate`, `HandleShotMsg`, `HandleRespawnMsg`, `HandleReloadMsg`, `HandleResyncMsg`, `CheckValidMessage`.
- **Server memvalidasi tembakan** (`OnShotMsgValidated`) sebelum damage diterapkan — lawan menembak → server relay + validasi → client terapkan damage. Pola ini hanya masuk akal bila ada lawan yang aksinya tidak dikendalikan client sendiri.

**Tidak ada AI bot lokal untuk lawan Arena.** Pencarian di namespace `Game.Multiplayer.*`: tidak ada class `BotController`/`BotAI`/`BotBrain`/`BotMovement`/`BotShoot`. Lawan Arena digerakkan lewat `ArenaCharacterMessenger` (pesan jaringan) — `ArenaOpponent` hanya me-render karakter + `SetupMessengerCallbacks`. `BotBehavior` yang ada di dump adalah untuk **leaderboard** (`Game.ShortLeaderboard.*`, `BotsConfig`/`BotConfig`: `amount`, `minWinsPercentage`, `maxWinsPercentage`, `scoreOnStartPercentage` — entri leaderboard palsu), bukan AI lawan Arena.

### 7.2 Bukti bot memang ada — tapi sebagai pengisi roster

- `ArenaMatchHandler.MATCH_BOT_ROSTER = "match.botRoster"` — server mengirim daftar bot dalam match; `OnBotRoster(obj)` → `PvpOpponentWeaponPrefetcher.PrefetchBotRoster(args)` — roster dipakai untuk **prefetch bundle senjata/gear lawan** (rendering), bukan untuk menjalankan AI.
- `PvpOpponentWeaponPrefetcher.IsBot(JsonObject opponent)` — tiap lawan membawa flag boolean di metadata JSON-nya (dibaca + `Boolean.TryParse`); hasil `PvpOpponentWeaponOutcome`: `Real`, `ExemptReal`, `Forced`, `ForcedBuiltNow`, `Placeholder` — lawan bisa **Real** atau dipaksakan/dibuat (bot/placeholder).
- `ArenaSpawnManager`: `OnBotInstantiated` (event), `GetInitialSpawnIndexes(List<ArenaPlayerInfo> botsInfos)`, `RealSpawnIndexToFakeSpawnIndexMap` / `FakeSpawnIndexToRealSpawnIndexMap`, `SpawnInitial(opponentInfos, ...)`, `InstantiateOpponent(ArenaPlayerInfo)` — lawan di-spawn lokal dari data `ArenaPlayerInfo` (yang datang dari server), dengan pemetaan spawn "asli" vs "palsu".
- `BotMetagame : IMetagameCommunication` — implementasi metagame palsu (dipakai di editor/testing, bukan AI Arena).

**Artinya:** match Arena **bisa** berisi bot (server yang menentukan roster; bot mengisi slot bila lawan asli tidak ditemukan / sebagai bagian desain match). Tapi:
1. Protokolnya dibangun untuk lawan asli (relay tembakan/posisi real-time + validasi server).
2. Client **tidak bisa memastikan** sebelum/selama match apakah semua lawan bot — flag `IsBot` datang dari server per lawan.
3. Sekalipun lawannya bot, tembakan tetap melewati validasi server (`OnShotMsgValidated`) — aimbot yang menghasilkan pola mustahil tetap berisiko ditandai cheater.

### 7.3 Vonis klaim Arena

> **"Arena lawannya bot" TIDAK TERBUKTI dan tidak boleh dijadikan dasar membangun fitur.** Yang terbukti: Arena = PvP real-time (bisa lawan asli), dengan kemungkinan bot sebagai pengisi roster. Karena injector tidak bisa membedakan bot vs pemain asli secara andal — dan karena tembakan divalidasi server — seluruh fitur aim/ESP/damage di Arena **DITOLAK** (lihat `AUDIT-INJECTOR.md`). Bila user tetap yakin semua lawan Arena di pengalamannya adalah bot, itu adalah observasi gameplay, bukan fakta arsitektur — dan tetap tidak mengubah klasifikasi, karena satu match dengan satu pemain asli saja sudah cukup untuk menjadikan fitur itu cheat PvP.

---

## 8. Penilaian file referensi ESP — `~/workspace/user/files/ESP_3_thnu.h` (116 baris)

Dibaca langsung. Isinya: class `ESP` C++ yang menggambar via JNI ke Android Canvas lewat objek `CanvasView` kustom.

| Metode | Fungsi |
|---|---|
| `DrawLine(color, thickness, start, end)` | Garis (via `CanvasView.DrawLine`, signature JNI `(Landroid/graphics/Canvas;IIIIFFFFF)V`) |
| `DrawText(color, txt, pos, size)` | Teks |
| `DrawFilledCircle(color, pos, radius)` | Lingkaran isi |
| `DrawBox(color, stroke, rect)` | Kotak (4× DrawLine) |
| `DrawHorizontalHealthBar(screenPos, width, maxHealth, currentHealth)` | Bar HP — hijau >60%, kuning 30–60%, merah <30% |
| `DrawCrosshair(clr, center, size=20)` | Crosshair |
| `getWidth()` / `getHeight()` | Ukuran Canvas |

### 8.1 Yang bisa dipakai di Sniper 3D

- **Sisi rendering: BISA.** Menggambar ke Canvas Android tidak bergantung engine game — overlay di atas Unity tetap jalan selama injector bisa menempelkan `CanvasView` transparan di atas activity game (pola standar: `WindowManager` + `TYPE_APPLICATION_OVERLAY` atau view di decor view). Metode ini sama persis dengan yang dipakai injector Unity lain (termasuk contoh yang jadi referensi file ini).
- **Yang disediakan file ini: hanya gambar.** Ia menerima `Vector2` posisi layar yang sudah jadi — tidak ada pengambilan data game.

### 8.2 Yang MASIH KURANG untuk ESP lengkap di Sniper 3D

| Kebutuhan | Status di file | Sumber di Sniper 3D (dari dump) |
|---|---|---|
| Daftar musuh | ❌ tidak ada | `Person` (NPC misi) — semua instance di scene; `LevelController`/scene root. Perlu enumerasi `GameObject`/`Person` via IL2CPP API |
| Posisi 3D musuh | ❌ tidak ada | `Person.transform.position` (+ posisi kepala: head bone/attachment `AttachToHead`) |
| Proyeksi 3D → layar | ❌ tidak ada | `Camera.main.WorldToScreenPoint` (Unity) — atau proyeksi manual dari matriks kamera (`CameraInformation`: position, rotation, fieldOfView). **Ini bagian yang bergantung game** |
| Nyawa musuh (untuk bar HP) | ❌ tidak ada | `Person._currentHealth` / `_health` (double, lokal) — persis yang dipakai `DrawHorizontalHealthBar(maxHealth, currentHealth)` |
| Status hidup/mati | ❌ tidak ada | `Person._alive` / `_dead` |
| Class `CanvasView` Java | ❌ tidak ada (hanya dipanggil via JNI) | Harus dibuat di injector (metode `DrawLine/DrawText/DrawFilledCircle` dengan signature persis di atas) |
| `StructsCommon.h` | ❌ tidak disertakan | Harus dibuat (`Color`, `Vector2`, `Rect`) |
| Jarak musuh | ❌ tidak ada | Hitung dari posisi kamera → posisi musuh (untuk teks jarak) |
| Filter mode (misi vs Arena) | ❌ tidak ada | Gate mode misi — ESP **wajib mati** di Arena (§7) |

### 8.3 Batasan

- ESP **hanya dinilai untuk mode misi (solo lawan AI)**. ESP untuk PvP/Arena lawan pemain asli **TIDAK BOLEH** masuk daftar fitur (penolakan + alasan di `AUDIT-INJECTOR.md`).
- ESP di misi tetap berisiko server-side (§4 — penandaan cheater), meski datanya lokal.
- File ini tidak membuktikan apa pun soal Sniper 3D — ia hanya pola rendering generik. Semua klaim "bisa dipakai" di atas bertumpu pada struktur `Person`/`Camera` yang ditemukan di dump (§5, §3.3), bukan pada file ini.

---

## 9. Ekonomi — lokal vs server

| Item | Status | Bukti |
|---|---|---|
| Koin (soft currency) | **Server** | `Game.Currency.*`, `WalletCheatsHandler`, `CollectRewards(..., long softCurrency, ...)` |
| Diamond/gems (hard currency) | **Server** | Sama; `WeaponHardCurrencyOverrideConfig`, `ChargeGems` |
| PvP currency / token | **Server** | `CollectRewards(..., int pvpCurrency, ...)` |
| Energi | **Server** | `Game.Energy.*` + jam server |
| Senjata/gear/mods | **Server (kepemilikan)** | `WeaponData` statistiknya lokal (dibaca client), tapi kepemilikan & upgrade disync metagame; pembelian = IAP/server |
| IAP (uang asli) | **Server + receipt validation** | `RECEIPT_FAILED_TO_VALIDATE`, `RECEIPT_INVALID`, Google Play Billing |
| Hadiah misi | **Server** | `SyncPlayerCampaign` + `CollectRewards` |
| Skor misi / statistik tembak | Lokal dihitung, **dilaporkan** | `ShotTracker`, `SyncPlayerCampaign` |

**Tidak ada satu pun fitur currency/IAP/unlock yang disarankan.** Semuanya server-gated.

---

## 10. Yang masih butuh probe runtime (tidak bisa dibuktikan statis)

1. **Komposisi match Arena di lapangan** — berapa % lawan bot vs asli; apakah bot selalu ada; apakah ada mode Arena yang bot-only. Butuh: main beberapa match + catat `IsBot` per lawan / amati pola nama & perilaku.
2. **Titik pemakaian Play Integrity** — fitur apa saja yang memicu `RequestIntegrityToken` (login? matchmaking? pembelian?), dan apa konsekuensi token gagal (blokir diam / ban?).
3. **Ambang deteksi cheater server** — apakah ada validasi statistik misi (waktu selesai, akurasi, headshot rate) saat `SyncPlayerCampaign`.
4. **Perilaku OfflineBlock** — apakah misi bisa dimainkan tanpa internet sama sekali, atau login/sync wajib online.
5. **Struktur Transform musuh di runtime** — nama bone kepala (`AttachToHead`), alamat `Person` di memori, alamat `Camera.main` — untuk implementasi aimbot/ESP (butuh dump runtime via injector, bukan dump statis).
6. **Zoom maksimal efektif** — `MaxZoom`/`ZoomLevels` per senjata (nilai dari `WeaponData` runtime, bukan dari dump).

---

## 11. File kerja

```
~/workspace/rea-sniper3d/
├── REPORT.md                  (file ini)
├── AUDIT-INJECTOR.md          (klasifikasi fitur + saran injector)
└── work/
    ├── sniper3d-7.15.0.xapk   (247.871.814 B, SHA-256 c7b446a8…)
    ├── xapk/                   (base APK + config.arm64_v8a.apk + manifest.json)
    ├── xapk_url.txt           (URL APKPure bertanda tangan)
    ├── apkpure_sniper.bin     (respons API APKPure)
    ├── base/                  (base APK terekstrak: dex, assets, manifest)
    ├── arm64/                 (lib/arm64-v8a: libil2cpp.so 135 MB, libunity.so, libpitaya-android.so…)
    ├── dump/                  (kosong — Il2CppDumper gagal, metadata v39)
    ├── cpp2il_out/            (225 DLL hasil Cpp2IL: Assembly-CSharp.dll 4,6 MB)
    ├── cpp2il_ilrec/          (DLL hasil Cpp2IL dll_il_recovery)
    ├── cpp2il_cs/             (DiffableCs — signature saja)
    ├── cpp2il_isil/           (IsilDump 536 MB — badan method ARM64+ISIL)
    ├── decompiled/            (ilspycmd atas dll_default — signature)
    ├── decompiled_ilrec/      (ilspycmd atas dll_il_recovery — 6,7 MB)
    └── decompiled_ilrec/…     (lihat decompiled/ untuk DLL pendukung: Client, Pitaya,
                                TFG.SecNet, Wallet, Purchases, Play Integrity)
```

File referensi ESP: `~/workspace/user/files/ESP_3_thnu.h` (116 baris, dibaca langsung — lihat §8).

**Catatan untuk parent:** MEMORY.md mencatat perintah user agar laporan REA/dump + injector APK Sniper 3D (dan Wild Hunter 3D) di-push ke GitHub + dipublikasikan permanen dengan rilis otomatis. Tugas subagent ini dibatasi "riset saja, JANGAN push" — keputusan push/publikasi diserahkan ke parent.
