# REA — Vodobanka (yio.tro.vodobanka) v260801

Analisis statis penuh terhadap `Vodobanka_260801_2_tlfy.apk` (APK universal tunggal,
12,4 MB, 1230 entri). Metode: aapt2 (manifest/badging), apksigner (sertifikat),
dexdump (sensus paket) + jadx 1.5.1 (1461 file sumber `yio.tro.*`, hanya 6 error
dekompilasi). Semua klaim di bawah punya bukti di kode hasil dekompilasi
(`~/workspace/rea-vodobanka/jadx/sources/`).

---

## 0. Vonis ringkas

- **100% OFFLINE.** Tidak ada satu pun izin jaringan, tidak ada kode socket/HTTP
  di logika game, tidak ada SDK iklan/analytics/Firebase. Satu-satunya "keluar"
  adalah membuka tautan komunitas di browser eksternal.
- **Tidak ada sistem uang/toko sama sekali.** Yang ada adalah *permissions* =
  kuota pemakaian perlengkapan per misi (granat, scout, blocker, dll).
- **Model tempur one-hit-kill** — tidak ada HP. Peluru membunuh seketika;
  pacifier membuat target menyerah (surrender).
- **Game ini MEMBAWA cheat debug-nya sendiri**: `DebugFlags.cheatGodMode` dan
  `DebugFlags.cheatInfiniteResources` adalah flag sungguhan yang dibaca logika
  game, lengkap dengan panel debug (`SceneDebugPanel`) dan mode super user
  (`SceneSecretScreen`).
- **Nol obfuskasi pada kode game, nol anti-tamper, nol cek tanda tangan, nol
  deteksi root.** Semua nama kelas/metode/field asli dan terbaca.
- **Gate versi PRO bersifat lokal murni**: `CampaignManager.isLevelAvailable()`
  membatasi level campaign bernomor ≤ 34 untuk versi gratis; sisanya diarahkan
  ke layar "about pro version". Versi pro adalah APK terpisah
  (`yio.tro.vodobanka_pro`, lihat `assets/links.txt`).

Semua fitur cheat yang masuk akal di sini **LOKAL** — tidak ada server yang
bisa memvalidasi apa pun. Detail target per fitur ada di §10.

---

## 1. Verifikasi paket & manifest

| Item | Nilai |
|---|---|
| Package | `yio.tro.vodobanka` |
| Nama aplikasi | Vodobanka |
| versionName / versionCode | `260801` / `72` |
| minSdk / targetSdk / compileSdk | 19 / 35 / 35 |
| sharedUserId | `yio.tro.vodobanka` |
| Application | `androidx.multidex.MultiDexApplication` |
| Activity satu-satunya | `yio.tro.vodobanka.android.AndroidLauncher` (exported, MAIN/LAUNCHER) |
| Komponen lain | Hanya AndroidX: `androidx.startup.InitializationProvider`, `androidx.profileinstaller.ProfileInstallReceiver` |
| allowBackup | `true` |
| isGame | `true` |

### Izin (uses-permission) — daftar LENGKAP

Hanya **satu**:

```
uses-permission: yio.tro.vodobanka.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

Itu izin signature-level milik sendiri (standar AndroidX). **Tidak ada**
INTERNET, tidak ada ACCESS_NETWORK_STATE, tidak ada izin penyimpanan, tidak ada
apa pun.

Klarifikasi soal `android.permission.DUMP` yang muncul di pemindaian string
manifest: itu **bukan** uses-permission. Itu atribut `android:permission` pada
`ProfileInstallReceiver` milik AndroidX ProfileInstaller — izin yang harus
dimiliki *pengirim broadcast* ke receiver itu, bukan izin yang diminta aplikasi.

`uses-feature`: OpenGL ES 2.0 (required).

### Konsekuensi struktural

- Tidak ada `service`, tidak ada activity iklan, tidak ada Firebase/Google
  Play Services sama sekali di manifest.
- Native library hanya bawaan libGDX untuk 4 ABI
  (arm64-v8a, armeabi-v7a, x86, x86_64): `libgdx.so` + `libgdx-freetype.so`.
  Tidak ada `.so` logika game, tidak ada `.so` proteksi.

---

## 2. Sertifikat

- Signer tunggal: **CN=Ivan Yakovliev, L=Kyiv, C=UA** (nama asli Yiotro).
- SHA-256: `e4e578b20731130d6ac848eb43432899ae3c08ea29fe6001fc7883b4d4ff3e00`
- SHA-1: `c2ba234615cfd40e92da3d37a33cb02887d35537`
- Tidak ada kode di dalam game yang memeriksa sertifikat ini (lihat §9).

---

## 3. Peta dex & paket

- `classes.dex` 12,7 MB — seluruh game + libGDX + Kotlin/AndroidX.
- `classes2.dex` 0,6 MB — hanya library desugar `j$/` (backport java.time/stream).
- Paket game `yio.tro.vodobanka` (1461 kelas hasil jadx):

| Paket | Isi |
|---|---|
| `yio.tro.vodobanka` | `YioGdxGame` (kelas utama), `Yio`, `SettingsManager`, `SoundManager`, `GameController` ada di `game/` |
| `.android` | `AndroidLauncher` |
| `.game` | `GameController`, `GameRules`, `GameMode`, `Difficulty`, `GameResults` |
| `.game.campaign` | 105 kelas level `Clev*` + 550 kelas `Ulev*` + `CampaignManager`, `LevelStorage` |
| `.game.gameplay` | Inti: `ObjectsLayer`, unit, senjata, tembakan, granat, ruangan, fog of war, AI |
| `.game.gameplay.units` | `Unit`, `SwatMember`, `Suspect`, `Civilian`, `Spy`, `MafiaBoss`, `Mimic`, komponen & tasks |
| `.game.loading` | `LoadingManager`, `LoadingType`, generator level |
| `.game.export_import` | `ExportManager`, `ImportManager`, `SavableYio` (serialisasi level/save ke teks) |
| `.game.debug` | `DebugFlags` |
| `.game.scripts`, `.game.tests` | Script briefing level; test otomatis internal (sisa pengembangan) |
| `.menu.*` | Kerangka UI Yiotro: `Scenes`, elemen, render, reaksi |
| `.stuff.*` | Utilitas: `factor_yio` (animasi), `object_pool`, `scroll_engine`, `name_generator`, `calendar`, `UrlOpener`, `StoreLinksYio` |

Level **bukan file aset** — setiap level adalah kelas Java yang mengembalikan
string kode level plaintext berformat:

```
vodobanka_level_code#map_name:...#general:...#camera:...#cells:...#walls:...#doors:
#furniture:...#humanoids: x y sudut tipe senjata waypoint...#light_sources:#marks:
#windows:...#permissions: flash_grenade 3,scout 5,...#scripts: message=...,reveal_room=...
#game_rules: hard def#
```

(terbaca utuh, contoh: `game/campaign/UlevAaronFinale.java`).

---

## 4. Arsitektur

- **Kelas utama**: `yio.tro.vodobanka.YioGdxGame extends
  com.badlogic.gdx.ApplicationAdapter implements InputProcessor`. Satu
  ApplicationAdapter menjalankan seluruh game; pergantian layar dikelola
  kerangka menu Yiotro (`menu.scenes.Scenes` — factory statis semua scene).
- **Kontrol permainan**: `game.GameController` memegang `ObjectsLayer`
  (lapisan objek: grid sel, unit, granat, partikel, goal, dll) dan
  `SpeedManager` (tactical pause & kecepatan).
- **Mode permainan** (`game.GameMode` / `game.loading.LoadingType`):
  `campaign`, `skirmish` (peta acak dari `RandomLayoutGenerator`),
  `editor` (buat level sendiri), `custom` (user levels bawaan), `calendar`
  (level kalender harian — dihasilkan/dipilih lokal oleh
  `stuff.calendar.CalendarManager`), plus 8 mini-game yang dirujuk
  `LevelStorage` (`8c` Flappy, `16c` Jumper, `24c` Walker, `52c` Pong,
  `59d` Knifes, `60c` Eater, `71c` Chekanka, `72c` RubberBand).
- **Alur main**: **real-time dengan tactical pause** — unit bergerak dan
  menembak dalam tick `moveActually()`; pemain memberi perintah saat jeda
  (`SpeedManager.applyTacticalPause()`, `GameRules.fastForwardSpeed = 4`).
  Tersedia juga *micro control* (`GameRules.microControlMode`, paket
  `units/micro_control`: ControlLine/ControlPoint di `SwatMember`).
- **Aturan global** adalah field statis di `game.GameRules`:
  `difficulty`, `fogEnabled`, `lightingEnabled`, `doorLeafType`,
  `forceMaxScore`, `microControlMode`, `temporalVisibilityMode`, dll.
- **Kesulitan** (`game.Difficulty`): `def, easy, normal, hard, expert`.
  Pilihan campaign disimpan `game.gameplay.CampaignDifficultyManager`
  (Preferences, key `value`).

---

## 5. Sistem permainan

### 5.1 Unit

`game.gameplay.units.Unit` (abstrak, berbasis komponen: sight, arms, walking,
shot action, aggression, state, destinations, tracking, highlight) dengan tipe
(`UnitType`): `swat, civilian, suspect, vip, spy, mafia_boss, mimic`.

Kelas konkret: `SwatMember` (dikendalikan pemain, `isControlledByPlayer()=true`,
tidak bisa di-stun), `Suspect` (tersangka bersenjata — target investigasi),
`Civilian`, `Spy`, `MafiaBoss`, `Mimic`, `VeryImportantPerson`.

**Tidak ada field health/HP/armor di `Unit`** — lihat model tempur §5.3.

### 5.2 Senjata

`WeaponType` (21): `fist, pacifier, handgun, shotgun, machine_gun, scout,
civ_hands, vip_hands, handcuffed,` dan granat `smoke, flash, stun, sho,
feather, slime, lightning, draft, mask, scarecrow, rocket` + `yumpik`.
`units.Weapon` hanya memodelkan visual tongkat/arah + cooldown; efek ditentukan
tipe tembakan (§5.3). Senjata per level ditentukan kode level (spawn
`#humanoids: ... swat pacifier`, `suspect machine_gun waypoint...`, dst).

### 5.3 Model tempur — one-hit-kill, tanpa damage/HP

`game.gameplay.shots.ShotType`: `pacify, bullet, yum`.
`game.gameplay.shots.Shot.applyEffectToUnit(Unit)` adalah satu-satunya corong efek:

- **bullet** → `killUnit(unit)` → `unit.kill(true, ...)` — **mati seketika**,
  tanpa perhitungan damage. Pengecualian bawaan di kode yang sama:
  - target **suspect tidak bisa dibunuh peluru** (`unit.isSuspect()` → efek
    dibatalkan; tersangka wajib ditangkap/dilumpuhkan),
  - target non-mortal (`!unit.isMortal()`) kebal,
  - **jika `DebugFlags.cheatGodMode` aktif dan target dikendalikan pemain →
    efek dibatalkan** (god mode bawaan, lihat §8).
- **pacify** → target `setState(UnitStateType.surrendered)` + `onPacified()`
  (non-lethal; tidak berlaku ke unit pemain; VIP bisa berubah jadi kill
  tergantung `GoalManager.canVipBeKilledBySwat()`).
- **yum** → membunuh non-SWAT yang mortal; SWAT dan non-mortal kebal.

Tembakan bersifat **hitscan grid**: `Shot.updateAffectedCells()` melempar
`RayCaster` 3 sinar sejajar (tengah + ±radius penembak), sinar **menembus
jendela** (`rayCaster.setPenetrateWindows(true)`), titik tabrakan dihitung
`updateCollisionPoint()`, dan satu tembakan mempengaruhi **maksimal 2 unit**
(`Shot.getLimitByShotType()` selalu mengembalikan 2).

### 5.4 Akurasi

Akurasi = simpangan sudut acak `Unit.aimCorruptionDelta` (radian), dihitung di
`Unit.updateAimCorruptionDelta()` dan dipakai `ShotActionComponent`
(`targetAngle = angleTo(target) + aimCorruptionDelta`; tembakan dilepas saat
selisih sudut bidik < 0,05 rad):

- **Unit pemain (SWAT): selalu 0** — bidikan pemain sudah sempurna secara bawaan.
- Musuh, menurut `GameRules.difficulty`:
  - easy: acak ±0,5655 rad (±32,4°)
  - normal: acak ±0,3770 rad (±21,6°)
  - hard / expert / def: **0** (musuh justru paling akurat di kesulitan tinggi)
- Keanehan terbukti: bila `LanguagesManager.xmlFileValid == false`, simpangan
  musuh dipaksa acak ±0,9425 rad (±54°) menimpa semua kesulitan.

Unit menembak otomatis: `Unit.checkToFire()` dipanggil berkala
(`RepeatYio` setiap 12 tick) bila senjata siap, state normal,
`AggressionComponent.isReadyToShoot()`, dan ada target terlihat
(`getTargetToFire()` berbasis `SightComponent`).

### 5.5 Line-of-sight & fog of war

- `units.SightComponent` per unit (frekuensi update: SWAT 25, default 30 tick)
  + `gameplay.RayCaster` di atas grid `base_layout.CellField` untuk halangan
  dinding/pintu/jendela.
- Paket khusus: `gameplay/fog_of_war`, `gameplay/lighting`, `shadow_info` —
  visibilitas temporal (`GameRules.temporalVisibilityMode`) dan ruangan yang
  belum terungkap (`reveal_room` di script level).

### 5.6 AI musuh

AI berbasis **task** (`units.tasks`): `TaskSuspectWalkAround` (patroli
mengikuti waypoint dari kode level), `TaskCaptureRoom`, `TaskScoutRoom`,
`TaskMafiaBossWalkAround`, `TaskIdling`, `TaskToggleDoor`, dll., dibuat
`TasksFactory` sesuai tipe unit. Reaksi tempur dari `AggressionComponent` +
`checkToFire()` di atas; `PanicComponent` untuk sipil/tersangka panik;
`ArrestQueueManager` untuk antrean penangkapan; `Spy`/`Mimic` adalah peran
khusus (mata-mata & peniru di antara suspect). Tidak ada pembelajaran/server —
semua deterministik lokal di tick game.

### 5.7 "Resources" = kuota perlengkapan per misi (BUKAN uang)

Pencarian menyeluruh `price|cost|buy|purchase|money` di seluruh kode game:
**nol hasil yang relevan** (hanya nama level seperti `UlevBankRobber`).
Tidak ada mata uang, tidak ada toko, tidak ada pembelian antar-misi.

Yang ada: `game.gameplay.permissions.PermissionsManager` — peta
`PermissionType → Integer` per misi:

- `PermissionType` (14): `blocker, scout, flash_grenade, smoke_grenade,
  stun_grenade, sho_grenade, feather_grenade, slime_grenade,
  lightning_grenade, draft_grenade, mask_grenade, scarecrow_grenade,
  rocket_grenade, wait`.
- Semantik nilai: **-1 = tak terbatas, 0 = dilarang, N>0 = sisa kuota**.
  Bawaan: blocker/scout/flash/smoke/stun/wait = -1; sisanya diisi
  `PermissionsGenerator` dari definisi level (`#permissions:` di kode level)
  atau preset `EquipmentType` (`random, mix, def, smoke_and_sho, ...`).
- Pemakaian mengurangi kuota di `decreasePermission()` — **kecuali**
  `DebugFlags.cheatInfiniteResources == true` atau flag
  `DebugFlags.superUserEnabled` (yang membuat `isPermitted()` selalu true).
- Ada `PermissionsManager.makeEverythingPermitted()` bawaan (semua jadi -1).

### 5.8 Investigasi (mekanik inti Vodobanka)

`game.gameplay.goal`: `GoalManager`, `InvestigationManager`,
`InterrogationManager`, `Characterization` (data karakter per humanoid:
`CharDataType`, `CharConditionType`), `EvidenceData`. Di antara para suspect
ada pelaku sebenarnya; pemain mengumpulkan bukti (`pickable_objects`,
evidence1–3 di atlas) dan menginterogasi, lalu menangkap orang yang benar.
Inilah alasan peluru tidak membunuh suspect (§5.3): membunuh tersangka =
gagal misi secara desain.

### 5.9 Skor

`game.gameplay.match_end.ScoreCalculator` menghitung skor akhir match;
`GameRules.forceMaxScore` (statis) memaksa skor maksimum bila true
(dibaca di `ScoreCalculator` baris 78; satu level bawaan,
`UlevEscapeDeathRow`, menyetelnya true). `MatchStatistics` mencatat statistik
match. Skor murni lokal — tidak ada leaderboard.

---

## 6. Progresi & gate versi PRO

- Kemajuan campaign disimpan `game.campaign.CampaignManager` di Preferences
  **`yio.tro.vodobanka.campaign`**, key `progress`
  (konstanta `NotificationCompat.CATEGORY_PROGRESS`), isi = daftar key level
  yang selesai, dipisah spasi. `onLevelCompleted(key)` menambah + `saveValues()`.
- Peta campaign adalah graf planet (`menu.elements.campaign.CvePlanet`/
  `CveLink`): status level dari `CampaignManager.getLevelStatus()` —
  `completed` bila key ada; `unlocked` bila ada tetangga pendahulu yang
  selesai (atau tidak punya pendahulu); selain itu `locked`.
- Jumlah konten: **105 kelas level campaign** (`Clev1..Clev54` + varian `b`
  dan lanjutan) dan **550 kelas user level** (`Ulev*`) — semua tertanam di dex.
- **Gate PRO** di `CampaignManager.isLevelAvailable(String)`:

  ```java
  public boolean isLevelAvailable(String str) {
      return !Yio.isNumeric(str)
          ? getFirstNumeral(str) < 3
          : Integer.valueOf(str).intValue() <= 34;
  }
  ```

  Level bernomor > 34 (dan pack non-numerik seri ≥ 3) **tidak tersedia di
  versi gratis**; `launchLevel()` yang gagal cek ini membuka
  `Scenes.aboutProVersion`. Pelengkapnya konstanta kompilasi
  `yio.tro.vodobanka.PaidStatus.PRO_VERSION = false`. Versi pro dijual sebagai
  aplikasi terpisah (`yio.tro.vodobanka_pro` di `assets/links.txt`) — di APK
  ini tidak ada IAP/billing sama sekali.
- `CampaignManager.markManyLevelsAsCompleted(int)` bawaan menandai level
  1..N selesai sekaligus.

---

## 7. Data & simpanan

Semua penyimpanan adalah **libGDX Preferences** (SharedPreferences Android).
Tidak ditemukan penulisan file via `Gdx.files.local/external` di kode game.

| Preferences | Pemilik | Isi |
|---|---|---|
| `yio.tro.vodobanka.campaign` | `CampaignManager` | key `progress`: daftar level campaign selesai |
| `vodobanka.settings` | `SettingsManager` | pengaturan (suara, bahasa, dll) |
| `yio.tro.vodobanka.editor_saves` | `gameplay.editor.EditorSavesManager` (`PREFS`) | slot level editor |
| `vodobanka.skirmish` | `SceneSkirmishMenu` | pengaturan skirmish |
| `vodobanka.oneTimeInfo` | `OneTimeInfo` | penanda info sekali tampil |
| `yio.tro.vodobanka.mini_game.<key>` | `AbstractMiniGameElement` | skor/progres mini-game |
| `yio.tro.vodo.ul_manually_hidden` | `UlHideWorker` | user level yang disembunyikan manual |
| `yio.tro.vodobanka.time` | `stuff.AppTimeTracker` | waktu pemakaian aplikasi |
| `yio.tro.vodobanka.diagnostics` | `stuff.XmlDiagnostics` | diagnostik XML bahasa |
| `yio.tro.vodobanka.refresh_rate` | `RefreshRateDetector` | refresh rate layar |
| `yio.tro.vodobanka.campaign` (key `value` di prefs kesulitan) | `CampaignDifficultyManager` | kesulitan campaign terpilih |

Catatan:
- `AndroidLauncher` membaca `getPreferences("settings")` Android mentah untuk
  `full_screen` (bawaan launcher Yiotro).
- **Editor level dibagikan sebagai teks**: `game.export_import.ExportManager
  .performToClipboard()` menserialisasi seluruh state level (sel, dinding,
  pintu, furnitur, unit, goal, permissions, scripts — implementasi
  `SavableYio.saveToString(...)` per manajer) ke clipboard;
  `ImportManager` + `SceneEditorLobby.performImportFromClipboard()`
  membacanya kembali. Tidak ada unduhan level dari server.
- `allowBackup=true` → semua Preferences di atas ikut Android Auto Backup.

---

## 8. Cheat/debug BAWAAN pengembang (temuan penting)

`game.debug.DebugFlags` — semua `public static boolean`, bawaan rilis `false`:

```
cheatGodMode, cheatInfiniteResources, superUserEnabled, debugEnabled,
testingModeEnabled, logEnabled, problemCheckerEnabled, editCampaignLayout,
forceMoreMimics, abrikosStuff, showFps, showGrid, showWayGraph, showSightList,
showActiveCells, showColoredCells, showAggression, showCellUnitReferences,
showDebugMarkInfo, showFloorBatchesPositions, showPosMap
```

Yang benar-benar dibaca logika permainan:

- `cheatGodMode` → `shots.Shot.applyEffectToUnit()` (peluru ke unit pemain
  dibatalkan).
- `cheatInfiniteResources` → `permissions.PermissionsManager
  .decreasePermission()` (kuota tidak berkurang) + panel.
- `superUserEnabled` → `PermissionsManager.isPermitted()` selalu true;
  `CampaignViewElement` memperlakukan level `locked` sebagai bisa dibuka;
  menu konteks pintu; tombol super user di overlay gameplay/editor.

Antarmukanya ikut terkompilasi di build rilis:

- `menu.scenes.gameplay.SceneDebugPanel` — panel berisi checkbox **God Mode**
  dan **Infinite Resources** yang langsung men-toggle kedua flag di atas
  (metode `switchGodMode()`/`switchInfiniteResources()` di kelas yang sama).
- `menu.scenes.SceneSecretScreen` — "secret screen" bawaan dengan
  `switchSuperUser()` (men-toggle `DebugFlags.superUserEnabled` + notifikasi
  "Super user enabled/disabled") dan `switchShowFps()`.
- `game.DebugActionsController` (baris 103) menyetel
  `DebugFlags.cheatGodMode = true` pada salah satu aksi debug-nya.
- Panel debug digerbang mode super user: `SceneMechanicsOverlay` membuat
  `superUserButton` yang hanya berfungsi bila `DebugFlags.superUserEnabled`.

Artinya: untuk god mode & kuota tak terbatas, **game-nya sendiri sudah
menyediakan saklarnya** — mod paling bersih cukup memastikan flag ini menyala
(mis. menyetelnya saat start), tanpa mengubah logika apa pun.

---

## 9. Permukaan online — BUKTI offline

1. Manifest: **nol** izin jaringan (§1) — aplikasi bahkan tidak *bisa*
   membuka socket secara sah.
2. Pencarian di seluruh kode `yio.tro.*`: tidak ada `java.net.Socket`,
   `HttpURLConnection`, `openConnection`, atau pemakaian `Gdx.net` untuk
   permintaan HTTP. Satu-satunya pemakai `Gdx.net` adalah
   `stuff.UrlOpener` → `Gdx.net.openURI(String)` = membuka **browser
   eksternal**.
3. Konstanta URL yang ada hanya tautan keluar untuk dibuka di browser:
   `menu.scenes.SceneCommunity` (Reddit `r/yiotro_games`, Discord Yiotro) dan
   `stuff.StoreLinksYio` (Play Store/App Store/Steam game Yiotro lain +
   satu folder Google Drive komunitas). Tidak ada endpoint API, tidak ada
   telemetri, tidak ada cek lisensi online.
4. Tidak ada Firebase/Play Games/analytics/ads di dex maupun manifest;
   `classes2.dex` murni library desugar `j$/`.
5. `assets/links.txt` hanya memetakan ID toko game-game Yiotro lain
   (promosi silang saat pengguna mengetuk tautan — tetap lewat browser).

**Kesimpulan: Vodobanka versi ini 100% offline, tanpa iklan, tanpa akun,
tanpa sinkronisasi cloud.** Klaim reputasi Yiotro terverifikasi di kode.

---

## 10. Proteksi

- **Obfuskasi kode game: TIDAK ADA.** Seluruh 1461 kelas `yio.tro.*`
  mempertahankan nama asli yang deskriptif (kelas, metode, field:
  `cheatGodMode`, `isLevelAvailable`, `updateAimCorruptionDelta`, ...).
  Jadx merekonstruksi hampir sempurna (6 error dari 2813 kelas total).
  Kode level pun plaintext (§3).
- **Cek tanda tangan / anti-tamper: TIDAK ADA** di kode game (tidak ada
  pembacaan `PackageInfo.signatures`/hash sertifikat).
- **Deteksi root/emulator: TIDAK ADA** yang ditemukan di kode game.
- Native hanya libGDX standar; tidak ada proteksi komersial (bukan PairIP,
  bukan Promon, dsb.).

---

## 11. Vonis cheat per fitur (format: lokal/server dulu)

Game ini **tidak punya komponen server sama sekali** (§9), jadi semua vonis
berbasis target lokal berikut. Urutan dari yang paling mudah.

### 11.1 God mode untuk unit SWAT — LOKAL, SANGAT MUDAH (sudah bawaan)
- Target: `yio.tro.vodobanka.game.debug.DebugFlags.cheatGodMode`
  (`public static boolean`).
- Titik baca: `yio.tro.vodobanka.game.gameplay.shots.Shot
  .applyEffectToUnit(Unit)` — cabang `ShotType.bullet`:
  `(DebugFlags.cheatGodMode && unit.isControlledByPlayer())` → efek dibatalkan.
- Cara: set flag `true` (hook setter/startup, patch smali, atau aktifkan
  panel debug bawaan §8). Cakupan persis: kebal **peluru**. Pacify memang
  sudah tidak berlaku ke unit pemain; efek lain (granat dsb.) tidak melewati
  pemeriksaan ini — jangan klaim kebal total di luar jalur `Shot`.
- Alternatif tanpa flag: cegat `Unit.kill(...)` untuk unit
  `isControlledByPlayer()`.

### 11.2 Kuota perlengkapan tak terbatas — LOKAL, SANGAT MUDAH (sudah bawaan)
- Target: `DebugFlags.cheatInfiniteResources` (dibaca
  `PermissionsManager.decreasePermission(PermissionType)`).
- Alternatif: panggil `PermissionsManager.makeEverythingPermitted()` atau
  `setPermission(PermissionType, -1)` untuk semua tipe di
  `game.gameplay.permissions.PermissionsManager` (field `map`,
  `objectsLayer.permissionsManager` dari `ObjectsLayer`).
- Ini pengganti "unlimited money" — uang memang tidak ada (§5.7).

### 11.3 Buka semua level campaign (termasuk gate PRO) — LOKAL, MUDAH
- Gerbang utama: `CampaignManager.isLevelAvailable(String)` — paksa `true`.
- Kunci peta: `CampaignManager.getLevelStatus(String)` /
  `menu.elements.campaign.CampaignViewElement` (status `locked` juga
  diabaikan bila `DebugFlags.superUserEnabled`).
- Jalur data: tulis Preferences `yio.tro.vodobanka.campaign` key `progress`
  berisi semua key level, atau panggil
  `CampaignManager.markManyLevelsAsCompleted(int)`.
- Catatan: `PaidStatus.PRO_VERSION` adalah `static final boolean` — nilai
  sudah ter-inline saat kompilasi; mengubahnya butuh patch smali/dex, bukan
  refleksi. Umumnya tidak perlu disentuh bila `isLevelAvailable` ditangani.

### 11.4 Akurasi — pemain sudah sempurna; musuh bisa dibuat buta tembak — LOKAL, MUDAH
- Pemain: tidak perlu apa-apa, `Unit.updateAimCorruptionDelta()` menyetel
  `aimCorruptionDelta = 0` untuk `isSwatMember()`.
- Musuh: patch/hook `Unit.updateAimCorruptionDelta()` agar cabang non-SWAT
  selalu menghasilkan simpangan maksimum (pola fallback ±0,9425 rad sudah ada
  di kode), atau nolkan peluang tembak di `AggressionComponent
  .isReadyToShoot()` / `Unit.checkToFire()`.
- Field terkait: `Unit.aimCorruptionDelta` (double, package-private).

### 11.5 Manipulasi musuh (buta / menyerah massal) — LOKAL, SEDANG
- Buta: `units.SightComponent` per unit (musuh tidak memperoleh target →
  `Unit.getTargetToFire()` kosong → tidak menembak).
- Menyerah massal: `Unit.setState(UnitStateType.surrendered)` pada suspect —
  state yang sama dipakai jalur pacify resmi (§5.3); penangkapan lalu lewat
  `ArrestQueueManager`/`TaskArrest`.

### 11.6 Tembakan menembus lebih banyak target — LOKAL, MUDAH (terbatas)
- `Shot.getLimitByShotType()` selalu `2` — menaikkannya menaikkan jumlah unit
  yang terkena satu tembakan hitscan. Penetrasi dinding **tidak** didukung
  struktur raycast (sinar berhenti di sel terdampak; hanya jendela yang
  ditembus, `setPenetrateWindows(true)`) — jangan dijanjikan.

### 11.7 Skor maksimum — LOKAL, SANGAT MUDAH
- `GameRules.forceMaxScore = true` → dibaca
  `game.gameplay.match_end.ScoreCalculator` (baris 78).

### 11.8 Unlimited money — TIDAK RELEVAN
- Tidak ada mata uang/ekonomi di game ini (§5.7). Fitur yang setara adalah
  kuota perlengkapan §11.2.

### 11.9 Damage boost — TIDAK RELEVAN dalam bentuk klasik
- Tidak ada HP/damage (§5.3): satu peluru = mati. Yang bisa diubah hanyalah
  siapa yang boleh terkena (pengecualian suspect/non-mortal di
  `Shot.applyEffectToUnit`) — mis. mengizinkan peluru membunuh suspect akan
  merusak desain investigasi (§5.8) dan umumnya membuat misi gagal; dicatat
  sebagai kemungkinan teknis, bukan rekomendasi.

---

## 12. Ringkasan target (untuk build berikutnya, tanpa bedah ulang)

| Tujuan | Target persis |
|---|---|
| God mode SWAT | `DebugFlags.cheatGodMode = true` → dibaca `shots.Shot.applyEffectToUnit` |
| Kuota ∞ | `DebugFlags.cheatInfiniteResources = true` → dibaca `PermissionsManager.decreasePermission` |
| Semua izin terbuka | `DebugFlags.superUserEnabled = true` / `PermissionsManager.makeEverythingPermitted()` |
| Unlock campaign + PRO | `CampaignManager.isLevelAvailable(String)`; prefs `yio.tro.vodobanka.campaign`/`progress`; `CampaignManager.markManyLevelsAsCompleted(int)` |
| Musuh meleset | `Unit.updateAimCorruptionDelta()`, field `Unit.aimCorruptionDelta` |
| Musuh tidak menembak | `Unit.checkToFire()`, `AggressionComponent.isReadyToShoot()`, `SightComponent` |
| Skor maks | `GameRules.forceMaxScore = true` → `match_end.ScoreCalculator` |
| Multi-target per tembakan | `Shot.getLimitByShotType()` (bawaan 2) |
| Panel cheat bawaan | `menu.scenes.gameplay.SceneDebugPanel`, `menu.scenes.SceneSecretScreen.switchSuperUser()` |

Artefak kerja: ekstrak di `~/workspace/rea-vodobanka/extract/`, sumber jadx di
`~/workspace/rea-vodobanka/jadx/sources/`, catatan mentah (badging, manifest
tree, sensus paket) di `~/workspace/rea-vodobanka/notes/`.
